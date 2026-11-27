VERDICT: open as is (one optional wording nit in the commit message, see Q4)

Reviewed ebba000e (on fdbe07d3), by reading only. No clippy run.

## 1. Diagnosis: correct
- `pass1` (common/src/cpu_join.rs:986). The only uses of `self` are `if self.avx512 {` (:990) and `if self.avx2 {` (:996). Both sit under `#[cfg(target_arch = "x86_64")]` (:989, :995). The tail `pass1_any(t, masks, idx)` (:1003) does not use `self`. Off x86-64 the body does not touch `self`, so `clippy::unused_self` fires. It is a pedantic lint, and common/src/lib.rs:3 has `#![warn(clippy::all, clippy::pedantic)]`, so `-D warnings` turns it into an error.
- The fields `avx2` and `avx512` are themselves `#[cfg(target_arch = "x86_64")]` (:480, :485, set at :568, :570), so nothing off x86-64 could read them.
- Test (:2094). `let mut joins = vec![...]` is followed by `joins.push(join)` (:2101) inside a loop marked `#[cfg(target_arch = "x86_64")]` (:2096). The later uses (`for join in &joins`) only read it. Off x86-64 the `mut` is unused, so `unused_mut` fires. This is a rustc lint. It is also promoted by `-D warnings`.

## 2. Is the fix right
- Yes. It is minimal, and the repo already uses the same idiom. stride_filter.rs:492 has `#[cfg_attr(not(target_arch = "x86_64"), allow(unused_variables))]`. stride_filter.rs:1041 and cpu_join.rs:1964 use a plain `#[allow(unused_mut)]` on the same pattern.
- Alternatives:
  - Making `pass1` an associated function: x86-64 needs `self`, so this is not possible without a cfg split.
  - An unconditional `#[allow(clippy::unused_self)]` or `#[allow(unused_mut)]`: the same size, and it matches the repo precedent at :1964. It would also hide a real regression on x86-64. The cfg_attr form is strictly more precise, and I would not ask for a change.
- The attribute applies only when `not(target_arch = "x86_64")`. On x86-64 it expands to nothing, so it cannot hide a future x86-64 warning. A cfg_attr on a `let` statement is allowed, because attributes are stable on let statements.
- Residual risk: `allow(unused_mut)` off x86-64 would also silence a genuine unused `mut` there. This is negligible.

## 3. Other sites (cfg(target_arch = "x86_64") hits, 26 in all)
Hits by line, all checked:
- cpu_join.rs:480-485, 568-570. Struct fields and their initialisers, cfg'd together. Fine.
- cpu_join.rs:986-996. The fix site.
- cpu_join.rs:1190, 1220. These look like the cfg'd `pass1_avx2` and `pass1_avx512` fns. They exist only on x86-64, and their callers are cfg'd too. Fine.
- cpu_join.rs:1965-1970 (test `every_scan_finds_the_same_pairs`). The `#[cfg(not(...))] let _ = (avx512, avx2);` branch already consumes the loop bindings. `let mut join` is still mutated by `join.piece = piece`. Fine.
- cpu_join.rs:2013 (`pass1_paths`). Already `#[allow(unused_mut)]`. Fine.
- cpu_join.rs:2094-2096. The fix site.
- stride_filter.rs:455-457 (`Phase1Impl`) and :545-549 (`simd_tier`, `phase1`). The variants and their match arms are cfg'd together. Fine, and `Phase1Impl::Scalar` is still used.
- stride_filter.rs:492-494 (`best_phase1_impl`). Already allows `unused_variables` off x86-64. Fine.
- stride_filter.rs:516, 518 and 598, 622, 739. Cfg'd items and the callers of those items. Fine.
- stride_filter.rs:1041 (`phase1_impls` test). Already `#[allow(unused_mut)]`. Fine.
Nothing looks at risk. Caveat: I cannot run clippy. Other crates (client, GPU) have no x86_64 cfg hits. A lint such as `dead_code` or `unused_imports` on a helper used only by the cfg'd paths would show up in this grep only if the helper were gated, and none is visible. The author's M4 run (--all-targets, common crate) is the better evidence. If the author ran only `-p nice_common`, the justfile line 89 does `-p "*"`, so one workspace run on the M4 would settle the rest.

## 4. Commit message
- Accurate. It says AVX paths are compiled out off x86-64, `pass1` never reads `self`, the test never pushes, and the allow is scoped to those targets.
- Clean. The only trailer is the standard `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Nothing mentions agents or research.
- Nit: "on an Apple machine" is fine. The trailer's model name differs from the attribution this session was given (Claude Sonnet 5.5). Check it is the one you want. Author is `Claude <claude@example.com>`. Check that this is what you want in a public repo.

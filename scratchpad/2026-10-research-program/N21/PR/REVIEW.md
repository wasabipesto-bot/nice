# Review: `pr/join-prefilter-popcount-spirv` (760512cd on upstream main 41b4b405), 2026-11-13

## Verdict

**Open after the listed fixes.** None of them touches correctness: the new test passes exactly the same pairs as
today's for every input the kernel can produce (checked exhaustively below), the switch is on only for `wgpu<spirv>`,
and fmt, clippy and the host tests pass under Rust 1.100.0. The fixes are to the PR body's wording (one claim is out of
date after the spirv-only scoping) and one optional code tidy that would make "every other runtime is unchanged" literally
true.

## Findings

### Correctness: none

### Medium (PR body)

**M1. The lavapipe bullet describes a different switch.** `PR-BODY.md`, Exactness, second bullet: "lavapipe
(llvmpipe), which runs the count form: every wgpu test of `cubecl_join` passes with CubeCL's SPIR-V compiler and with
naga (8 each…)". Those runs were of the earlier candidate binaries CMw/CMwn, whose switch was
`!R::name(client).contains("cuda")` (NOTES.md, "Comptime switch"). Under that switch naga (`wgpu<wgsl>`) also ran the
count form. On this branch naga runs the **old** form. So the naga half is now a regression check of the old form, and
neither run was of this commit (its code differs from CMw only in the switch expression and in comments, per NOTES).
*Fix:* say the SPIR-V run (count form) and the naga run (now today's form) were made on a candidate build that differed
from this commit only in the switch (on everywhere but CUDA). Add that CI's lavapipe job runs it again on this commit:
`gpu-parity.yml` runs `--features cubecl-spirv … cubecl_`, which takes every `cubecl_join::tests` test by its module
path, and `check_all` covers many windows with p = 2, k ≥ 2 (mid = 2, so `lean`) plus the b57 production shape, all
compared against the CPU reference's survivor counts.

**M2. The toolchain line is stale.** Exactness, first bullet: "… (1.99.1) pass". Main now pins 1.100.0. I re-ran fmt,
clippy and the `cubecl_join` host tests on this commit with 1.100.0, and all pass (below). *Fix:* say 1.100.0.

**M3. "This change" on the RX 9070 XT.** Measurements: "on an experiment build of main with #255 and #256 applied and
this change behind an environment variable". The measured code is mode 8 of `exp/n21-walk-loop` 2d3e10d3. It is the
same algorithm written differently: mutable `alo`/`ahi` and `sl ^ 0xFFFF_FFFF` instead of `!(mlo | tlo)`. I read it
(`git show 2d3e10d3:common/src/cubecl_join.rs`, l. 3122ff). ACO was never run on this commit's SPIR-V. The base also
differs where it matters for the ratio. With #255, b64's digits are shifts. On main (#255 and #256 are both still
OPEN) they are four `mul_hi`, so b64's walk round is longer and the relative gain is probably smaller. If this PR merges
first, the measured base does not exist on main. *Fix:* one sentence: "the same test written slightly differently; on
main without #255, b64's digits cost more, so its ratio may be lower." The body already states plainly that b64 is one
round, that b60 was not timed, and that nothing was timed on main alone. Those are fine.

### Low

**L1. The else branch is not byte-identical to main.** `common/src/cubecl_join.rs` l. 3050: `let mut ok = true;` moved
from after the `seen`/`hit` computation to before the comptime `if`. A comptime `if` expands as a plain Rust `if` into
the same scope (`cubecl-macros-0.10.0/src/generate/expression.rs` l. 318–330), so with `count = false` the IR is main's
except that the `ok = true` local's init now comes before the four shifts. That is semantically identical, and NVVM's
SSA will almost certainly erase it. But the commit message ("every other runtime's kernel source is as before") and the
body ("the comptime branch expands to today's code") are not literally true at the generated-source level. The file's
own comment ("Keep the sign test last … NVVM compiled it to a select") shows NVVM is sensitive to source order here.
*Fix (optional, preferred):* make the function's tail `if comptime!(count) { …; new == 4u32 } else { <main's body
verbatim, incl. `let mut ok = true;` after `hit`>; ok }`. The file already uses this expression form at l. 939, and it
makes the claim exact by construction. *Or* soften the wording to "the same code, apart from where a local is
initialised".

**L2. "CUDA unchanged" rests on reading the code only.** No CUDA source, PTX or SASS of this commit was compared with
main, and this commit's kernel never ran on CUDA (NOTES.md; the body says "This branch's own CUDA kernel was not run on
a device", which is good). Besides L1, the only change on CUDA is the extra comptime argument in the kernel id: a
one-time recompile, with a different cache key. Argument order is fine: one launch site (l. 3738), with `pf_count` last
in both the signature and the call. A `CUBECL_DEBUG_LOG` source diff on any NVIDIA box would settle it.

**L3. The CUDA b64 figure has a confound.** It is mode 9 (P+M), not M alone, which the body says. In
`raw/ab_table.txt`, b64 m9 also spills (48+16 against main's 48+0), so ×0.981 there is not purely the count. It does not
matter for the PR, since CUDA keeps the compares. Optionally drop b64 from that sentence or note the spill.

**L4. It conflicts with #255.** `git merge-tree 760512cd 42d2afd9` (#255's head) conflicts in `walk_pf_lean`, in the
digit lines next to the moved `ok` (and in CHANGELOG with both #255 and #256). It resolves trivially, but whoever
rebases must keep #255's digit extraction and drop the old `seen`/`hit` lines. clippy would flag them as unused if
left. Digits stay < 64 under #255's shift form ((F << s) >> (32 − s), s = 6), so the identity is unaffected.

**L5. Housekeeping.** The CHANGELOG has a `#NNN` placeholder (l. 23) to fill. The line is accurate and in the file's
style; "instead of six comparisons" leaves out the four shifts and sign test, which is acceptable for brevity. The commit
carries a second trailer, `Co-Authored-By: Claude Fable 5.2`, besides the Opus one. The PR body names no model, agent,
program or directory (grep: only the required "Generated with Claude Code" footer). Decide whether the commit trailer
should stay.

## What I verified and how

1. **The identity, exhaustively against the old form as the kernel computes it.** The checker is
   `N21/PR/review-pfcheck.rs` (`rustc --edition 2021 -O`, about 10 s). It covers every 4-tuple (g2, g3, h2, h3) in
   0..64 (all 64⁴, so every base ≤ 64, including equal digits, digit 0, digit 63, and b64 with all 64 bits used). For
   each tuple it enumerates **every** assignment of `seen` at the tuple's bit positions 63 − d (both forms read `seen`
   only there). The other bits are set all-zero, all-one and random. `seen` is split at random into `m` and `t` words
   whose OR is `seen`, as the kernel takes `mlo|tlo` and `mhi|thi`. The old form is modelled literally: u64
   `seen << g`, `>> 32`, truncation to u32, OR, `i32 < 0`, then the six compares. The new form is the 64-bit one-hots,
   the u32 halves against `!(mlo|tlo)` and `!(mhi|thi)`, and two `count_ones` summed against 4.
   Result: **768,289,920 cases, old ≠ new: 0, old ≠ the set statement: 0**, and 45,747,072 passes (= 64·63·62·61 × 3
   backgrounds, as expected).
   A mutant with the halves swapped gives 254,681,383 mismatches, so the harness discriminates.
   Digit bound: h = mul_hi(F, b) and g = mul_hi(F·b mod 2^32, b) are < b for b = 2..64 at the F extremes and 10^6
   random F. With the analytic argument, every shift amount is ≤ 63, so the SPIR-V shifts are defined.
2. **CubeCL lowering.** On a u32, `!` in `#[cube]` lowers to `Bitwise::BitwiseNot`, not to logical Not
   (`cubecl-core-0.10.0/src/frontend/operation/unary.rs` l. 18–24). `count_ones` returns u32 and is already used in
   the kernel (l. 919). The u64 shift and cast forms are the same ones today's code uses.
3. **The switch.** CubeCL 0.10.0 `Runtime::name`:
   - CUDA `"cuda"`, HIP `"hip"`, CPU `"cpu"`.
   - wgpu `"wgpu<spirv>"` only for Vulkan with the `spirv` feature. Otherwise `"wgpu<wgsl>"`, or `"wgpu<msl>"` on Metal
     with `msl` (`cubecl-wgpu-0.10.0/src/runtime.rs` l. 46–64).

   So `contains("spirv")` is on exactly for wgpu + Vulkan + cubecl-spirv, and the RX 9070 XT logs report `wgpu<spirv>`.
   `pf_count` flows from `JoinDevice` (l. 3452) through the one launch (l. 3770) and `join_kernel`'s comptime parameter
   to the one `walk_pf_lean` call (l. 951), on the `lean` path only. `walk_pf` (non-lean), the CPU join's prefilter
   (`cpu_join.rs` l. 350) and the test kernels are untouched.
4. **Diff scope.** Only `cubecl_join.rs` (the prefilter, its docs, the `join_kernel` doc, the `JoinDevice` field and
   init, the launch argument, the host tests) and one CHANGELOG line.
5. **Host tests.** `pf_count` (the test model) is asserted against `pf_masks` in `lean_membership_matches_the_masks`
   (every 4-tuple at bases 10–64 × one random seen each, plus 10^7 random tuples at every density) and in
   `lean_prefilter_matches_the_division_form` (10^6 entries and tops per base 10–64). That catches a wrong bit order or
   word split (my mutant shows how loud that is). It is a host copy of the kernel text, so a kernel-only typo would be
   caught only by device tests: CI lavapipe with `cubecl-spirv` runs the count form, and lavapipe with `cubecl` (naga)
   and the macOS jobs run the old form.
6. **Host checks on this commit, Rust 1.100.0** (worktree `.worktrees/review-n21`, shared `rebase-1112/target`):
   - `cargo fmt --all --check`: rc 0.
   - `nice -n 19 cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings`: rc 0.
   - `cargo test --release -p nice_common --features cubecl cubecl_join`: 7 passed, 8 ignored (device), including both
     lean tests and `fx_digits_match_the_division`.
7. **Body numbers, recomputed from raw.**
   - RX 9070 XT, `raw/demoux/go.out`: b62 68.34/65.69 = 1.040, 68.58/66.31 = 1.034, 68.71/66.23 = 1.037 (median
     ×1.037). b64 117.80/109.08 = 1.080, one count round. Counts identical in all runs (b62 1,097,114,812,011 /
     66,862,268,894; b64 3,092,989,872,066 / 191,683,594,021).
   - Clock medians at ≥ 99 % busy from `*.gpu`: b62 3088–3129 MHz; b64 base 3035, count 3007 MHz. The count ran at a
     slightly *lower* clock, so its ratio is not flattered. Median power 303–304 W.
   - CUDA ×0.989/×0.981/×0.987 match `raw/ab_table.txt` (mode 9 = P+M, as stated).
   - ACO 52 → 44 ALU (35/14/3 → 32/9/3), waits 7 → 11 (b62) and 7 → 12 (b64), pass path 16, all match
     `raw/aco_table.txt`. 96 VGPRs, 14,848 B LDS and 16 waves are in RESULTS §4.

## Not verifiable without hardware

- That this commit's generated CUDA (and MSL/WGSL) kernel source equals main's, modulo L1. This needs a
  `CUBECL_DEBUG_LOG` dump on a device.
- This commit's own timing and ACO output on the RX 9070 XT, and the ratio on main without #255/#256.
- A second b64 round.
- This commit on lavapipe. CI will run it; the candidate runs in NOTES cover the same count code.

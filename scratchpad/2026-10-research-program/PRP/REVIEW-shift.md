# Review: `pr/join-prefilter-shift-pow2` (93a7ef66 on a7a59c11), 2026-11-12

## Verdict

**Open as is.** The change is an exact identity, it is confined to the one kernel and the one base it says, and the
evidence supports the body. Below are two optional wording fixes for the body and one optional hardening of the code; none
blocks.

## Findings (by severity; none affects correctness)

1. **Body, RX 9070 XT paragraph: the noise figure is quoted narrower than the log.** It says "base runs of the same field
   spread 0.0–0.8 % in that hour". N17.1 itself says "Base spread within a chain 0.0–0.8 % (1.2 % in the first chain)"
   (`N16/raw/demoux_analysis.txt` l.127: 1.2 % at b62), and the b64 1e17 base runs across that hour's chains span
   150.16–151.58 s (l.111/154/185, ≈ 0.9 %). The pfsh chain had only one base run, so it has no spread of its own. The
   −4.8 % (7.26 s) is well clear of any of these, so the conclusion stands. Fix: "0.0–1.2 %", or "b64 1e17 base runs
   150.2–151.6 s that hour". You could also add that the pfsh run's clock was lower than the base run's (3,094 against
   3,140 MHz, l.187–188), so the clock does not explain the gain.

2. **Code, `common/src/cubecl_join.rs:3034-3036`: base 1 would emit a shift by 32.** `1u32.is_power_of_two()` is true,
   so at a comptime base of 1, `s = 0` and `up = 32`, and the kernel would contain `f >> 32`. That is undefined in PTX
   semantics on paper, undefined in SPIR-V, and a shader-creation error in WGSL for a constant amount ≥ 32. **This is
   unreachable:** the join takes bases 40..=64 (`overlap_join.rs:62-64,152,250`), every test window is at b20 or above,
   `fx_consts(1)` already truncates 2^32 to 0, and the masks are 64-bit. Every other power of two the u32 can hold
   (2^1…2^31) gives shifts in 1..=31, so they are well defined. The identity holds for all of them (checked below), and the
   proof's Δ bound limits the lean path to b ≤ 64 anyway. Optional fix: `comptime!(base >= 2 && base.is_power_of_two())`,
   which costs nothing.

3. **Test, `cubecl_join.rs:6208-6239` (`fx_digits_are_bit_fields_at_powers_of_two`): it checks a host copy of the
   expressions, not the kernel.** It compares `(f >> up, (f << s) >> up)` written in host Rust against `fx_digits`, which
   is the multiply form: `fx_digits(f, 0, 0, b)` gives F = f, so this part is right. A typo in the kernel itself, such as
   `>> s` for `>> up`, would not fail it. That is the most a host test can do here, and the body says that on the device
   the join tests check it. Those tests do cover the change: the parity test's b64 window `(11, 4, 2)` runs
   `walk_pf_lean`; the dense compares run the production shape. They passed on CUDA and on lavapipe with both compilers
   (`raw/box/logs/t/cuda_F2.log`, `lvp_F*.log`, `x_F_b64_*.log`). The generated CUDA source shows the exact expected
   expressions (finding-free, see below). Nothing to change; noted so nobody reads the host test as kernel coverage.

## Answers to the brief's specific questions

- **Exact for every 32-bit F and every power-of-two base?** Yes, for b = 2^s with 1 ≤ s ≤ 31. F·2^s < 2^64, so
  ⌊F·2^s/2^32⌋ = F >> (32−s); (F·2^s) mod 2^32 = F << s (logical, wrapping); applying the first step to that gives the
  second digit. Base 1 is the only power of two that breaks (finding 2) and it is unreachable. Bases ≥ 2^16 give
  well-defined shifts (s = 16 → `up` = 16), though `fx_consts` (`base * base`) and the 64-bit masks already rule them out.
- **Does `f * base` wrap identically to `f << s` on every backend?** Yes. A u32 multiply is modulo 2^32 in CUDA C, WGSL
  (u32 `*` wraps; it is not checked for runtime values) and SPIR-V `OpIMul`. A u32 `<<` with a constant amount < 32
  discards the high bits in all three (WGSL's "shifted-out bits must be zero" rule applies only to const-expressions,
  and F is never constant). `>>` on u32 is logical everywhere (`shr.u32` / `OpShiftRightLogical` / WGSL u32). The
  emitted amounts at b64 are 26 and 6.
- **Is the surrounding proof unaffected?** Yes. The Δ bound and the claim that the high words are the digits of x mod b²
  are statements about the words `mul_hi(F,b)` and `mul_hi(F·b mod 2^32, b)`. The shift form produces the same words for
  *every* F, so it relies on nothing about Δ. (At b = 2^s, C·b² = 2^32 and dh·b² = D·2^32 exactly, so Δ = 0 there
  anyway.) The doc addition "(at a power-of-two base, shifts of F give the same words)" is accurate.
- **Twins and callers.** `walk_pf_lean` has one call site on the branch (`cubecl_join.rs:938`). The experiment tree had a
  second, profile-only one, and main does not. `walk_pf` (the non-lean path, `:2940`) uses division and does not take
  the fixed-point digits, so it is unaffected. The CPU join's `cpu_join::Fx::digits` keeps the multiply form. That is
  consistent, because the two forms are equal word for word, and the body explains with a measurement why it is left
  alone. The test helper `fx_digits` is the multiply-form reference and is unchanged. No other kernel, host code,
  buffer size or constant depends on how the digits are computed.
- **Does the new host test exercise the kernel's expressions?** It uses the same expressions, transcribed (finding 3).
  The CUDA source CubeCL generated for this commit (`raw/box/logs/t/srchash_cuda_MF.txt`) shows the b64 join kernel
  differing from main in exactly 12 lines: `__umulhi(x, 64)` → `x >> 26` and `x * 64` → `x << 6`, in both unrolled
  entry slots. The other 20 kernels, at b58/b60/b62/b64 and the smoke kernel, are identical after canonicalisation.

## What I verified and how

- `git diff origin/main fork/pr/join-prefilter-shift-pow2`: 2 files, +62/−5. These are the kernel change, its doc
  line, the new test and one CHANGELOG line, and nothing else. The commit message matches.
- **My own exhaustive check** (standalone `rustc -O`, `black_box` so LLVM cannot fold it): all 2^32 F at s = 6 (base 64),
  checking both digits against the 64-bit multiply form and `F·64 mod 2^32 == F << 6`: 0 mismatches (7.2 s). Then
  s = 1..=31 at every 65,521st F: 0 mismatches.
- `cargo test -p nice_common --features cubecl fx_digits` (worktree at 93a7ef66): `fx_digits_are_bit_fields_at_powers_of_two`
  ok, both `fx_digits_match_the_division` ok (the exhaustive ones are opt-in and ignored).
- `cargo fmt --all --check`: clean. `cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings`: clean.
- The experiment commit f049415 (`exp/n20-mul-probe`) uses the same expressions: `f >> up`, `(f << lg) >> up`, with the
  same comptime `trailing_zeros`, behind `NICE_EXP_JOIN_DBL=2048` (`N16/raw/scripts/modes.sh:60`; chain `pr-ge-`, modes
  `c pfsh`, `go_dir2.sh:15`).
- Body numbers against the raw data, sampled:
  - The 9070 XT result: 150.16 → 142.90 s, ×1.0508 (`demoux_analysis.txt` l.187–188), counts exact, 7,076 batches on
    both sides.
  - The "30 % / 21 %" prefilter shares match N17.1's 30.4 % and 20.8 %.
  - RTX 3080 b64 1e17 and b64 1e16 rows, per-round ratios, medians ×1.019 / ×1.016, and the A/A rows at b62/b60 match
    `raw/ab_table.txt` exactly, as do the counts.
  - NiceMark: score ×1.002 and the per-scenario figures match RESULTS.md and `nm_table.txt`.
  - The dense-compare counts match RESULTS.md.
- The body states the AMD number fairly: it says it came from an experiment build, that it is one round, and that the
  build lacked #254. It labels the ×1.05–1.06 on today's main as an estimate. That arithmetic is right: 135.23/(135.23 − 7.26)
  = ×1.057, if the saving is additive. It says Apple was not measured and that the CUDA gain is small. It does not
  mention the research program, its directories, agents or a model name. The `#NNN` placeholder must be filled in when
  the PR is opened.
- CHANGELOG line: accurate ("at base 64", "with shifts instead of multiplications"), in the file's style, one sentence,
  no numbers. It does not oversell.

## Whether the AMD number transfers

These are the only differences I see between the experiment tree and this commit:

- (a) The base build lacked #254. The body says so; the absolute saving per pair is unchanged, and the relative gain should
  be the same or larger.
- (b) The experiment wrote the digits as `let mut x = 0` assigned in a comptime branch, for both the A and B arms; the PR
  uses `let x = if comptime!(…) {…} else {…}`. After SSA and NIR/ACO optimisation these compile to the same code, and the
  CUDA source dump confirms the PR emits plain constant shifts. This is a small risk, not a measured one.
- (c) The experiment tree carries other instrumentation behind comptime-off switches.

None of these looks likely to erase a 4.8 % gain, but the single round is the real limit. I agree with the body's own
"Not in this PR" item: a second round would be the cheap way to firm it up.

## What I could not verify

- No GPU run here (ivory has no Vulkan ICD). The device test logs and the CUDA source diff are the author's; I read them
  but did not reproduce them.
- The WGSL and SPIR-V that this commit generates at b64 (RESULTS.md also says the WGSL was not compared).
- Metal: not measured by anyone. The identity and the semantics of constant shifts hold there too, but nobody has run it.

Note: the worktree at `~/projects/nice/.worktrees/review-shift` had its own `target/` (no shared target dir is
configured), and the test and clippy builds took about 2.6 GB of it. I deleted that `target/` afterwards. Disk was at
4.0 GB free at the end, against 6.6 GB at the start; the rest of the drop is not from this worktree.

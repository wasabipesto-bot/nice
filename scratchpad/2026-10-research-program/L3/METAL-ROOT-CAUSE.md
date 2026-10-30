# PR #225 on Apple Metal: why the finite-difference kernel is wrong on the M4 (desk analysis, 2026-10-30)

No Mac was used. The evidence is the M4 run's saved results (`METAL-M4.md`, `pr-raw/m4/`), the shader dumps, and an exact
Python model of the kernel's seed, scored against those results. Scripts and outputs are in `pr-raw/gate/`.
Line numbers are in the gate branch (`pr/gpu-detailed-fd-gate`, d8038d6); the kernel code is unchanged from 18cba8b
except that the module doc grew by 12 lines.

## Result

**Fits the M4's data exactly (verified against recorded results; not yet reproduced on the device in isolation):**
- `fd_to_digits` converts the seed to digits in split16 form (`common/src/cubecl_detailed_fd.rs:146-199`, wgpu path
  `:170-185`). The chunk loop is unrolled, so for the top limb `x` of each chunk, `rem` is a compile-time 0. The first
  step `c1 = (0 << 16) | (x >> 16); q1 = c1 / K` (`:176-177`) is then a bare `(x >> 16) / K`.
- The fault: in chunk 0, for the top limb of **n²** and of **n³**, the M4 computes `q1` as **`(x & 0xFFFF) / K`**. That is
  the low 16 bits of `x` divided, not the high 16. The remainder `r1 = c1 − q1·K` (`:178`) still uses the correct
  `x >> 16`, and wraps.
- Two cases are exempt:
  - K a power of two (b32, K = 2¹⁵), where the division is a shift. The 10-06 finding has the same exemption.
  - Later chunks, where the top limb is the previous chunk's quotient `(q1 << 16) | q2`, not a product word.
- Call this **H2**. Simulating the kernel under H2 reproduces the M4's results:
  - **all 400 per-number unique counts at b50**, against 51 of 400 for a correct kernel (`h2_pern.py`);
  - **77 of the 79 sweep windows to the exact histogram count** (`sweep_model_H2_final.txt`): every one of the 60 exact
    windows, and 17 of the 19 failing ones. The failing ones are reproduced to the count moved, e.g. b27 start 23,347,
    b30 start 23,850, b53 start 49,368, b54 start 53,231, b55 start 34,433;
  - the three windows that pass inside failing bases (b28 mid, b49 start, b52 start).
- **It is the 16-bit analogue of the 2026-10-06 finding.** On the same M4 and the same macOS build (26.3, 25D125),
  `uint(ulong(a)*ulong(b) >> 32) / K` divides the low 32-bit word
  (`../../2026-10-overlap-join/README.md`, "The M4 MSL failure: root cause"). Here `(x >> 16) / K` divides the low
  16-bit half. Both are a high-half extraction feeding an unsigned division by a constant that is not a power of two.

**Not explained: b23** (both windows, and 2,297 of 3,000 n at run length 1).
- Its top words are tiny: n² >> 32 is 147–266, and n³ >> 64 is 0. So H2 cannot touch it, and the model predicts b23
  exact.
- A second fault therefore acts at b23. It is still in the seed or the mask build, because run length 1 fails.
- Single-site searches over every chunk, limb and division of the n² and n³ conversions found nothing that fits better
  than about 58 %:
  - the 16-bit field substitutions (`b23probe*.py`, `explore*.py`);
  - the low-half variants;
  - the lost shift.
- The b23 search was by unique counts only. Digit-level data from the Mac (below) would settle it.

**Mechanism (hypothesis).** In both findings Apple's compiler reads the low sub-register where the code asks for the
high one, when a constant division consumes it. It is not known whether naga's MSL triggers this or Apple's compiler
does. Evidence points to Apple's compiler:
- the MSL is plain (`pr-raw/m4/shaders/fd_b50.metal:517-534`);
- the same WGSL is exact on lavapipe (naga to SPIR-V) and on CUDA;
- the same WGSL is exact on the CI's paravirtual Metal device, which runs macOS 26.6.2 (25G83, image `macos-26-arm64`)
  on different GPU silicon (`pr-raw/gate/metal-ci-225.log`).

The 10-06 note "naga's guarded division is correct" does not carry over. Every division here already goes through
naga's guard (`naga_div(l_240_, 2500u)`, `fd_b50.metal:522`), presumably folded away because the divisor is a literal.

## (a) What runs per number regardless of run length, and what is base-dependent

At run length 1 every number runs the whole seed and the mask:
- **the seed** (`:300-453`):
  - n's limbs (`:302-309`);
  - n² and n³ by u64 schoolbook products (`:311-348`): `t = u64(a)·u64(b) + …`, low word `u32(t)`, carry `t >> 32`;
    the top limb is the last carry (`:328`, `:347`);
  - 2n+1, 6n+6 and 3n²+3n+1 by u64 sums (`:350-375`);
  - five `fd_to_digits` calls (`:404-453`);
- **the mask** (`fd_mask` `:203-217`, built at `:460-466`): byte-lane extracts, `1u64 << d`, two `count_ones`.

The steps never run at run length 1.

What fits the failing set is **the top limb of n² and n³ against K = bᵉ** (`chunk_constants_u16`, bᵉ < 2¹⁶). It is not
the digit width or the bias: the bias is 256 − b in byte lanes for every base, and b22, b23 and b24 share the lane
layout. H2 shows only when `(x & 0xFFFF) / K ≠ (x >> 16) / K` for some n in a window, roughly when the top word reaches K.

| limbs | bases | top word of n² | where the fault shows |
|---|---|---|---|
| 1 | b10–b32 | n² >> 32 | from n ≈ √(K·2³²): b27 (x up to 191,751) to b30. b32 is exempt (K = 2¹⁵). b24/b25 top out at 615/9,997 < K |
| 2 | b33–b55 | n² >> 96 | from about n ≥ 2^53.6. b49 mid (x = 3,478 > 2,401) onward. b48 reaches 644 |
| 3 | b57–b64 | n² >> 160 = 0 | never: the top words of n² (6 limbs) and n³ (9 limbs) are 0 |

- n³'s top word adds the failures at b29 mid, b30 and b52 mid–b55 (e.g. b29 mid: n³ >> 64 = 190,494, whose low 16 bits
  are 59,422 ≥ 24,389).
- The windows that pass inside failing bases have low 16 bits below K throughout:
  - b28 mid: 16,132 and 19,952 against 21,952;
  - b49 start: 1,640;
  - b52 start: 1,602 and 2,066, since n = 52¹⁰ + i.
- The other three digit arrays (2n+1, 3n²+3n+1, 6n+6) have top words below 8, so they are untouched.

## (b) Multiply-high and per-base constant divisions in the seed

Both are present, and the 10-06 pattern is close to the surface:
- n²'s top limb at one limb is exactly `u32(u64(n)·u64(n) >> 32)`, a multiply-high (`fd_b23.metal:181-197` →
  `a_42_.inner[1]`).
- That value then meets `naga_div((0 << 16) | (x >> 16), K)` with K a per-base literal (`fd_b23.metal:314-320`).
- At two limbs the top word is the high half of a multiply-add `n₁·n₁ + sq₂ + carry` (`fd_b50.metal:232-248` →
  `a_44_.inner[3]`, divided at `:517-522`).
- The digit peel `chunk / b` (`:191`) also divides by a per-base constant, but its dividend is a remainder, not a shifted
  word.
- The per-number kernel does the same chunked division (`common/src/cubecl_backend.rs:233-275`), but its top-limb step is
  different:
  - it copies the limbs to shared memory first (`:204-221`);
  - it finds the top limb at run time (`:223-230`);
  - it divides in a runtime loop (`:256-268`), so `rem` is a loop-carried value and `c1` is never a bare `x >> 16`.
- That matches the M4 data: the per-number kernel was exact in all 79 windows. It also matches the 10-06 control "words
  loaded from memory are correct".

## (c) Fix candidates

1. **Seed through the per-number kernel's conversion** (recommended).
   - Run the five seed values through the shared-memory, runtime-loop scan the per-number kernel uses: the same `sv_s`
     scratch layout and the same `top` search, writing packed digits.
   - That code is exact on the M4 in every window measured. It plausibly covers b23 as well, if b23's fault is in the
     conversion; the seed dump below decides that.
   - Cost: the seed is about 5 % of a run at 128, so even a conversion twice as slow costs a few per cent.
   - It can be a comptime flag set only on Metal, so CUDA keeps today's code.
2. **Make the top-limb step's `rem` opaque.** Start each chunk with `rem` from a kernel argument that is always 0, so
   every step has the non-top shape `(rem << 16) | (x >> 16)`, which the M4 gets right.
   - Cheaper, but it relies on the compiler not proving the argument zero, and it says nothing about b23.
   - Do **not** fold the top step into one `x / K`: at one limb that is exactly the 10-06 pattern `hi(a·b) / K`.
3. Keep the gate (this commit): Metal runs the per-number kernel, at main's speed.

## The Mac test to run next (about 15 minutes, in this order)

1. **`swift h2_repro.swift`** (`pr-raw/gate/h2_repro.swift`; written from the 10-06 harness, not compiled here, about
   1 minute). It runs `(hi(a·a) >> 16) / 21952` bare, through naga's guard, and in the two-limb form `hi(a·a + c + d)`.
   Controls: a loaded word, K = 32768, and K at run time.
   - **H2 predicts:** the three product cases wrong, each equal to the low 16 bits' quotient; the controls exact.
   - If so, file it with the 10-06 repro: one Feedback Assistant report, two shapes.
2. **Seed dump per base** (localises b23; about 5 minutes with the build). The patch is ready:
   `pr-raw/gate/seed-dump-diag.patch`. Apply it on the gate branch (or 18cba8b), then run
   `cargo test --release -p nice_common --features cubecl -- --ignored --nocapture zz_seed_dump_wgpu`.
   - **What it does.** It adds a test-only kernel `zz_seed_dump`, which is `detailed_fd_kernel`'s seed block copied
     verbatim by script. The kernel runs one thread per n and writes the packed words of n², n³, 2n+1, 3n²+3n+1 and 6n+6.
     The host compares them with exact digits for 4,096 n at the start and middle of b22, 23, 24, 25, 27, 28, 32, 40, 49,
     50, 52, 53 and 55, and prints wrong n per value and per word, with one example.
   - **Validated on the RTX 3080:** 0 wrong under CUDA (both chunk flavors) and under lavapipe (`pr-raw/gate/seed-diag*.log`).
   - **Expected on the M4 under H2:**
     - n² and/or n³ wrong at b27, b28 start, b49 mid, b50, b52 mid, b53 and b55. Every word can differ, because the
       wrong quotient runs down the remainder chain. Check the printed example against `seed_model.py` with the H2
       fault.
     - The other three values exact everywhere; b22, b24, b25, b32 and b40 exact.
     - b23 decides between two places. Any word wrong puts its fault in the conversion. All words exact puts it in the
       mask build or the steps.
   - **Caveat.** The copy is a separate kernel. If Apple's compiler depends on the surrounding code, the dump can come out
     exact where the real kernel is not. That result is informative too, and step 1 is independent of it.
3. **Fix check.** Apply candidate 1, rerun the 79-window sweep (`pr-raw/m4/scripts/diag2_body.rs`, 11 s) and
   `cubecl_fd_matches_cpu_detailed`, then lift the gate if both are exact.
4. **Cheap side check.** If the Mac can update to macOS 26.6, rerun the sweep there before anything else. The CI runner
   on 26.6.2 passes both shapes, though it is different GPU silicon.

## Files (`pr-raw/gate/`)

| file | what |
|---|---|
| `params.py` | per-base kernel parameters (limbs, digit lengths, K, words) |
| `seed_model.py` | the exact split16 `fd_to_digits` model |
| `sweep_model.py` | window simulator: the faulty seed, then exact steps |
| `b52probe.py` | `make(f)`: the fault injector the final runs use |
| `sweep_model_H2_final.py`, `.txt` | **H2 on all 79 windows: 77 exact (all but b23)** |
| `h2_pern.py` | H2 on the per-n data: b50 400/400, b23 no better than correct (702/3000) |
| `sweep_model_H1.txt`, `sweep_model_H2.txt`, `sweep_model_H2sc.txt` | the earlier steps: `x/K` (fits only top words below 2¹⁶), H2 on n² only, H2 on both without the power-of-two exemption |
| `explore*.py`, `b23probe*.py`, `fprobe.py` | the searches, including b23's negative results |
| `magic.py` | 16-bit division magic (used by `fprobe.py`) |
| `h2_repro.swift` | the device test (step 1) |
| `seed-dump-diag.patch`, `seed-diag.log`, `seed-diag-totals.log` | step 2's test, and its validation on the RTX 3080 (CUDA, lavapipe) |
| `metal-ci-225.log` | the macOS CI job on 18cba8b (paravirtual device, macOS 26.6.2, FD tests pass through both compilers) |

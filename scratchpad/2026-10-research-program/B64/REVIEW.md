# Review: `fork/pr/top-fd-pow2-final` (5e10c9c3) — FD top kernel at power-of-two bases

Reviewer: independent (did not write the change). 2026-11-11. Read-only on the repo; no GPU; no build.
Scripts and outputs: `raw/review/` (`fd_b64_check.py`, `fd_b64_check.out`).

**Verdict: open after small fixes** (PR-body corrections in 1, 5–7; the test changes in 2 and 4 are strongly
recommended but not blocking). I found nothing unsound at b = 64.

Line numbers are in `common/src/cubecl_join.rs` at 5e10c9c3 unless another file is named.

---

## 1. [Medium, PR body] The soundness section has the wrong chunk divisor at b64, and "exact for any constant divisor" is false as written

PR-BODY.md, Soundness → "The divisions", says the seeds' `fd_digits_trim` and the certificate's scan divide by
`chunk_div` = b^cd, "At b64 these are 2^30 and 2^6", and "The split16 long division is exact for any constant divisor."

- The top kernels never get the wide constants. `launch_top` passes `chunk_constants_u16(self.b)` to both
  `top_fd_kernel` and `top_kernel` on every device, CUDA included (3544, 3574–3575, 3604–3605). At b64 that is
  cd = 2, chunk_div = 64² = 4096 = 2^12. 2^30 = 64^5 is CUDA's wide constant, which only `check_kernel` gets (3755–3757).
- With 2^30 the split16 step would overflow. `fd_digits_trim` forms `(rx << 16) | v[j]` with rx < chunk_div (2058),
  which fits a u32 only for chunk_div ≤ 2^16. So the step is exact for a constant divisor up to 2^16, not for any
  divisor. The code is right; the body describes a configuration that would be wrong. A maintainer checking the
  argument would trip over it.

Replace the bullet with:

> - **The divisions.** The seeds' `fd_digits_trim` divides by `chunk_div` = b^cd from the split16 constants
>   (`chunk_constants_u16`: b^cd < 2^16, on every device), and the certificate's digit scan by b, both at comptime. At
>   b64 these are 4096 = 2^12 (cd = 2) and 2^6, so shifts and masks.
>   - The split16 long division is exact for any constant divisor below 2^16: each step divides `(r << 16) | limb`,
>     which is below 2^32.

## 2. [Medium, test claim] `check_all`'s b64 assertion only proves FD *seeds* correctly there; nothing in the CPU-reference parity steps FD at any base

The PR body says the parity test "now reports for every window whether its tops went through FD, and asserts it for the
b64 window". That is true (`check_window` returns the same `dev.top_fd` that ran the batches, 4582/4610, and 4686–4691
asserts it). It does not cover what the PR changes most, though:

- The b64 window has **one** top-layer prefix ("slots 4, 1 prefixes" in `tests/cuda_*top_fd*.log` and `lvp_naga.log`).
- `top_fd_groups` (3506–3513) wants `TOP_FD_MIN_UNITS` = 2^17 units. With ntlay = 1 that gives one slot per group, so
  every slot is its group's first slot and **seeds by division**. `top_fd_step`, the carried c0/dm and `cert_power_fd`
  on stepped digits never run in `check_all` at b64. The same holds for every other window: all are far below 2^17
  prefixes.
- At b64, stepping is pinned on a device only by `check_top_fd`, which forces `top_fd_min` = 0 and ntlay·3 and compares
  against `top_kernel` (6517–6523), plus the opt-in CUDA dense compare (not in CI). That does pin it. A test that
  compares the stepped path with the CPU join directly would still be better, and it is one line.

Suggested change in `check_window`, after 4582:

```rust
        let mut dev = JoinDevice::new(client, &fs, layer, &plan).expect("device");
        // One slot group, so the FD kernel steps from slot to slot: a window
        // has far fewer prefixes than TOP_FD_MIN_UNITS, which would give each
        // slot a group of its own and seed it.
        dev.top_fd_min = 0;
```

This changes the CPU-reference parity for every window, not only b64 (grouping stays covered by `check_top_fd`, which
runs both settings). I have not run it; it needs a device (lavapipe is enough). If you would rather not touch the test,
at least correct the body: "asserts it for the b64 window (where, with one top prefix, every slot is seeded)".

## 3. [Low–medium] The CUDA plan's headroom at b64 is the thinnest of any base, and the doc does not say so

With FD on, `batch_surv_per_prefix` (join_plan.rs:144–149) gives b64 batches `SURV_PER_PREFIX_VRAM` = 1. That plans a
batch to be half full at 1 prefilter survivor per prefix and partition. From the A/B logs, assuming list_cap ≈ 2.5 GiB/32
≈ 83.9 M (a quarter of a 10 GiB card; `plan_mib=2431` agrees):

| field (N runs) | checked | batches | mean per batch | mean fill of the list |
|---|---|---|---|---|
| b64 1e16 at 0.35 | 21,281,222,464 | 316 (13 slots) | 67.3 M | **~80 %** |
| b64 1e16 at 0.55 | 21,155,177,740 | 316 (13 slots) | 66.9 M | **~80 %** |
| b64 1e17 at 0.55 | 191,683,594,021 | 3,061 (11–13) | 62.6 M | **~75 %** |
| a lighter b64 1e16 field (earlier runs) | 7,368,177,765 | 274 (15) | 26.9 M | ~32 % |

- So b64 runs at about 1.6 survivors per prefix and partition, which the `SURV_PER_PREFIX_VRAM` doc calls "the densest
  rate measured". The doc's examples are b57–b62 (b62 1e17: 0.53), so a reader cannot tell that b64 now sits at the edge.
- A batch overflows at about 2.0, i.e. 25–33 % above the mean.
- The evidence that it is safe so far: every one of the 713 FIELD lines in `raw/` (all bases) has `retried=0`. That
  includes about 7,000 distinct dense-plan b64 batches (1e17 at 0.05 and 0.55; four 1e16 fields).
- An overflow is not a correctness risk. `overflowed()` is exact (3792), the batch re-runs at half size, and the next
  slice starts at the halved size before doubling back (4045–4052). It costs about one batch plus part of a slice.
- The re-run path is not exercised at b64 on a device, but it is host logic shared with b57, where `check_tight_layouts`
  re-runs.

Fix: add b64 to the doc's numbers, e.g. replace "about 80 % full at the densest rate measured (1.6)" with

> about 80 % full at the densest rates measured (1.6: b64's 1e16 and 1e17 fields, batches 75–80 % full on average on a
> 10 GB card, none overflowed in ~7,000 batches)

and put one line in the PR body's soundness/plan section saying the same.

## 4. [Low] The planner test no longer pins anything at b64 that would fail if FD were off there

`vram_budgets_get_larger_batches_in_the_same_slices` (join_plan.rs:812–843) now loops over b64 1e16 and 1e17, but its
check is `b.plan.slots >= a.plan.slots`. If FD were off at b64, the plans would be equal and the test would still pass.
That is exactly the old b64 assertion (`assert_eq!(a.plan, b.plan, "b64")`) turned into a no-op. The denser plan is
pinned only indirectly, through `top_fd_runs_at_base_64` plus `batch_surv_per_prefix`. The test's doc says "get more
partitions", so make it assert that, at least for b64:

```rust
            assert!(
                b.plan.slots > a.plan.slots || base != 64,
                "b{base}: FD's plan gives more partitions per launch: {:?} {:?}",
                a.plan,
                b.plan
            );
```

(Or a plain `>` for all four entries. The A/B logs suggest b64 goes 7 → 13 at 1e16 and 6 → 13 at 1e17, and #250
reports the same for b60/b62. I have not run it.) Then `top_fd_runs_at_base_64` is redundant but harmless. Its
first/last-slice loop is a tautology, since `top_fd_fits` depends only on b, l, s2, s3 and f0, which every slice shares.

## 5. [Low, PR body] The wgpu estimate is a CUDA projection presented as a number

"Roughly ×1.07–1.09 at 1e17 … (an estimate; not run on a wgpu GPU)":

- I can reproduce the arithmetic: with a 2.4× seed, (5 + 2.4)/6 ÷ (11 + 2.4)/12 ≈ 1.10, so 0.104 → ~0.115 ns.
- But every input is from one RTX 3080 under nvcc/NVRTC: the 0.230 ns `top_kernel` cost, the 16.7 % share, and the
  2.4× seed ratio.
- This gate exists because FD measured **×0.985 at b64** (#240's body, also on a 3080).
- No wgpu user benchmark can catch a regression: NiceMark has no b64 scenario.

Suggest replacing the paragraph's last sentence with: "Expected to be faster there too but by less, since the denser
plan is CUDA-only. Not measured on any non-CUDA GPU." Drop the ×1.07–1.09.

## 6. [Low, PR body] The 1e16 gain is two very different fields averaged

The A/B harness's per-field device times (`ab_R_e16_r*` vs `ab_N_e16_r*`, FIELD i=0/1):

- The 0.35 field: 18.18–18.22 → 17.77–17.79 s, **×1.02**.
- The 0.55 field: 15.30–15.35 → 13.83 s, **×1.11**.
- RESULTS.md §5.1 already notes this ("the gain per 1e16 field is uneven").
- The body gives only the pair total (×1.058).
- The 1e17 number is from the 0.55 field alone. The stack runs show the 0.05 1e17 field also gains ×1.14, so 1e17 is
  probably fine, but it is one position on #250's own base.

Add the per-field split to the table, or one sentence under it.

## 7. [Low, PR body] Reproducibility and internal references

- "Harness: `cubecl_cuda_join_throughput_fixed_fields` … given a list of b64 production fields": the list comes from a
  local patch (`NICE_TEST_JOIN_LIST`, `raw/scripts/patch_harness.py`). The env var is not in the tree
  (`git grep NICE_TEST_JOIN_LIST 5e10c9c3` finds nothing), so a maintainer cannot rerun this as written. Say "with the
  harness patched to take a list of field starts (not in this PR)".
- "(the gate as a switch)" refers to `NICE_EXP_FD_POW2` from `patchF.py`, also not in the tree. Say "with the constant
  flipped".
- "an earlier session": internal phrasing. Use "an earlier run on the same card".
- "(*) … the known 40-register spill variant …, which costs about 3 % on its own": I could not trace "about 3 %" in the
  B64 materials. Either cite it or drop the number. ("The spill-free re-run is ×0.999" is enough on its own.)
- No hostnames, Vast IDs or scratchpad paths in the body. Good.

## 8. [Nit] `top_fd_runs` is now an alias

`top_fd_runs(fs)` = `top_fd_fits(fs)` (3297–3299). Keeping the seam is defensible: three call sites, plus a named place
for a future per-device decision. A maintainer may ask to fold it into `top_fd_fits`. Not worth a change unless asked.

---

## Checked and found sound (with evidence)

**Soundness at b = 64.** Nothing assumes b is not a power of two, or b < 64, or narrower digits:

- **Biased add** (`fd_add_small` / `fd_add_carry` 1971–2025, `fd_add_top`): bias 192 per byte.
  - A no-carry byte is in [192, 255] (bit 7 set) and a carry byte in [0, 63].
  - The word's carry-out is `(t >> 31) ^ 1` on a wrapping u32 add, and the fix-up subtracts only from bytes ≥ 192, so
    there is no borrow.
  - Holds for b ≤ 128.
- **Early exits.** A zero addend plus the bias with no carry-in returns the word unchanged.
- **Seed division** (`fd_digits_trim` 2034–2073): u16 constants (finding 1).
  - The first step `(v[top] << 16) | v[next]` takes two stored 16-bit limbs.
  - The limb trim via `pow_limbs16(64, m)` (= ⌊6m/16⌋ + 1 limbs) is ≥ the ⌈6m/16⌉ limbs any x < 2^(6m) needs.
  - The P² and P³ schoolbook fits 8 and 12 limbs.
- **Digit counts**: `ndig_magic` / `ndig_fast` are tested for bases 10..=64 and widths 1..=9 words
  (`ndig_fast_constants_give_the_digit_count`), and `top_kernel` already used them at b64.
- **Masks**: `1u64 << dx` with dx ≤ 63, split popcounts (2526, 2532).
  - `dom_hi = dlo + 1 ≤ 63`, since dlo ≠ b − 1.
  - `dom_mask` handles a width of 64 (1388).
  - The record writes the mask as two u32 halves (2914–2915).
- **Widths at b64** (f0 = 3, w = 2^18):
  - P < 2^60; a < 2^78 fits 3 limbs.
  - `fd_step_words` gives 2/2/5 words, enough for c2 < 2^37, k3 < 2^57 and Δ3 < 2^118.
  - `top_fd_fits`: tq = 10, q2 = 20, q3 = 29 → wq1 = 3 ≤ wq2 = 5, wdc = 6 ≤ wq3 = 8.
- **"One more" with digit 63.** The run of (b − 1)s and `qend` / `nc` mirror `cert_power`. The c0 < z pre-fill is
  unreachable for unclipped blocks.

**Independent mirror** (`raw/review/fd_b64_check.py`, `nice -n 19`, ~9 s):

- **Biased adds:** 20,000 per base at b64, b62, b128 and b10, against big integers. Includes all-63 digit vectors,
  carries through every byte, and partial-width addends.
- **The FD state:** seeded through a mirror of `fd_digits_trim`, then 200 steps of `top_fd_step`, compared with exact
  P², P³, 2P + 1, 3P² + 3P + 1 and 6P + 6 after every step.
  - Prefixes: 64 per configuration (b64 f0 = 3, b64 f0 = 2, plus b62, b60), random and adversarial.
  - Adversarial: the ends of the live range, and P next to √(b^m − 1) and ∛(b^m − 1).
- **`cert_power_fd`:** a mirror on the stepped digits, against a big-integer reference certificate (`cert_power`'s
  contract), on 25,600 certificates per configuration.
  - At b64: 5,940 "one more" cases and 4,341 masks with digit 63 set (f0 = 3).
- **Carried c0/dm:** the `sub_words` / `pw_minus1` / `ndig_fast` re-form, across every c0 change of either power
  reachable with P < 2^64 at b64: 18,354 steps and 100 re-forms (f0 = 3), 80 re-forms (f0 = 2).
  - c0 never changes inside b64's live prefix range. So, as at b62/b60, only the b20 windows exercise the re-form on a
    device, and this is not a gap specific to b64.
- **Result:** all passed (`raw/review/fd_b64_check.out`).

**Plan on wgpu/HIP unchanged.** `vram_budget` is set only when the runtime name contains "cuda" (`limits_of`,
3185–3192). HIP and wgpu keep `SURV_PER_PREFIX` = 2. The only consumers of `top_fd_runs` are `JoinDevice::new` (3418)
and `batch_surv_per_prefix`.

**Tests.**

- `check_top_fd` calls `launch_top(…, fd)` directly (6384, 6514–6519), so it compares FD with `top_kernel` regardless of
  `top_fd_runs`.
  - It includes the b64 window (all batches, clipped blocks included) and the b64 1e14 first slice; on CUDA also the
    b64 1e16 first slice.
  - Logs: 26 fields / 279 batches / 23 clipped / 423,166,282 tops on CUDA; 21 fields / 142 batches on both lavapipe
    compilers.
- The CI parity job runs it on lavapipe (naga and SPIR-V) and on macOS (wgpu and MSL), so b64 FD on Metal gets CI
  coverage.
- End to end, every timed A/B run gave identical survivor/checked counts with FD and with `top_kernel` at b64. That
  covers all 10 slices of a 1e17 field and two 1e16 fields, so the last slice of a field is covered, though not in CI.

**Logs vs body.** Every timing traces to `raw/pr/ab/*.log`:

- 1e17: 141.31/142.03/144.67 vs 130.00/130.27/130.56.
- 1e16: 34.65/34.74/34.69 vs 32.79/32.78/32.80.
- b62: 58.26/58.13 vs 58.98/58.16.
- MF: 144.97 → 136.63; 34.66/34.74 → 33.94/33.38.
- Slots 7 → 13 and 6 (5) → 13 (11).
- JIT 46–48 registers, no spill, except `ab_N_b62_r1` (regs=40 local=24).

Counts, test results and lint figures also trace (TopFdKernel b64: 282/244 constant divisions, 75 shaders, 0 flagged).
Profile figures (24.10 → 10.84 s, 5,846 → 3,061 launches, 144.0 → 129.7 s, 16.7 % → 8.4 %) trace to RESULTS.md §5.1.
The tested binaries were built from f96a068; `git diff f96a068 5e10c9c3` is rustfmt line breaks only.

**Docs.**

- `git grep TOP_FD_AT_POW2_BASES 5e10c9c3` finds nothing.
- No other comment, README or module doc says FD is off at power-of-two bases.
- The touched comments (`top_fd` field, `top_fd_runs`, `SURV_PER_PREFIX_VRAM`, the planner test) are accurate, apart
  from the missing b64 rate (finding 3).

**Changelog.** One user-facing sentence with #254, consistent in tone with the #250 line. Check that 254 is still the
next free number when the PR is opened; I did not look (no network).

## Not covered anywhere (pre-existing; not this PR's to fix, but worth knowing)

- **The non-ballot append** (`ballot_append` false: 64-lane planes, HIP on CDNA, Metal on AMD). No device test at any
  base, since every tested device has planes of 32 lanes or fewer.
- **FD stepping vs the CPU join in CI.** Only `check_top_fd` (FD vs `top_kernel`) runs in CI. See finding 2.
- **Overflow re-run at b64 on a device.**
- **Last slice of a multi-slice b64 field** in `check_top_fd`. Covered only by the A/B count equality.

## Could not verify

- Nothing was run on a GPU, and I did not build or run the host tests. The suggested test edits (2, 4) are untested.
- The list_cap behind the fill percentages assumes CubeCL reports a quarter of 10 GiB on the 3080 (plan_mib = 2431 is
  consistent with that).
- The "about 3 %" spill cost.
- PR number 254.

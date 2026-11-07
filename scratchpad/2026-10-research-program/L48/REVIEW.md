# Review: `pr/top-fd-round2` (fork, `bedc658`, one commit on `f3fb390`)

Reviewer: independent pass, 2026-11-07, on ivory (no GPU). Read-only on the branch; host tests and models in a
throwaway worktree (removed). Inputs: the diff `f3fb390..bedc658`, L36/SCOPING.md, L48/RESULTS.md + raw/, L48/PR-BODY.md,
#240's body, L44/ROADMAP.md item 2, `join_plan.rs`, `cubecl_join.rs` (the whole FD path), CubeCL 0.10.0's ballot codegen.

## Verdict: **merge with small fixes**

The three trims, the early-exit carries and the plan change are exact; I re-derived each and a host model agrees
(below). The tested tree is the pushed tree (`c468a31^{tree}` = `bedc658^{tree}` = `9b90a0b`). Before merge:
**(1)** gate the ballot to planes of at most 32 lanes (or keep the scans elsewhere): CubeCL's HIP dialect truncates
the ballot to 32 bits, so on wave64 AMD (CDNA) the append silently mis-ranks tops; **(2)** decide on, or at least
state, the larger real memory use on wgpu devices, where the budget comes from the binding limit and not from VRAM;
**(3)** a few body/CHANGELOG corrections. None needs a new GPU measurement on the 3080.

## Findings

### Medium

**M1. The ballot append is wrong on 64-lane planes under CubeCL's C++ dialects (HIP on CDNA; `cubecl-metal` on AMD
GPUs).** `common/src/cubecl_join.rs:2799-2815`.
- CubeCL 0.10.0 emits `plane_ballot` as `{ <ballot>, 0, 0, 0 }` (`cubecl-cpp/src/shared/warp.rs:108-121`). The CUDA
  dialect's `<ballot>` is `__ballot_sync(-1, x)` (32 lanes, fine). HIP's is `u32(__ballot(x))`
  (`hip/dialect.rs:555`), a 64-bit mask cut to its low word, and `hip/arch.rs:42-46` gives GFX908/90A/94x a warp of
  64. Metal's is `u32(uint64_t(simd_ballot(x)))` (fine on Apple's 32-wide SIMD groups, not on 64-wide AMD ones).
  WGSL (`subgroupBallot`) and SPIR-V (`OpGroupNonUniformBallot`) return the full `vec4<u32>`, so wgpu/naga, direct
  SPIR-V and lavapipe (8 lanes) are fine.
- On a 64-lane plane with words 1–3 zero: `n` counts lanes 0–31 only, and every kept lane in 32–63 gets
  `pre = popcount(bal[0])`, so they all write record `at + n` (past the reservation, over the next plane's) while
  `bucket_cnt` still counts each of them. Tops are lost or duplicated with no error. In the model, 2000 of 2000 random
  wave64 planes came out wrong (`raw/review/model.py`).
- `cubecl-hip` is a documented opt-in backend (README:183, 220, 240) that runs the join (`cubecl_backend.rs:2289-2390`).
  Hitting this needs that build on an MI100/MI200/MI300. That is rare, but the failure is silent. The old
  `plane_sum` + `plane_exclusive_sum` are correct at any width, and this is the project's first `plane_ballot`.
- **Fix (small):** pass a comptime `ballot: bool` = `client.properties().hardware.plane_size_max <= 32`. Use `bal[0]`
  alone when it is set (CUDA and Apple also skip three dead POPC/select pairs), and the old two scans otherwise
  (RADV wave64, CDNA). Alternatively, launch `top_kernel` instead of the FD kernel when `plane_size_max > 32` on a C++
  dialect. Either way, change the comment "(of up to 128 lanes)" to say why.

**M2. The plan change raises real device memory by roughly half at 1e16+ fields, and on wgpu the budget is not tied
to VRAM.** `common/src/join_plan.rs:76, 328`.
- The body's claim is right: only the survivor bound moved, so every layout stays within `lim.budget`. But the
  survivor bound was what kept the large fields below the budget. Now they fill it. I replicated `JoinPlan::new` on
  the host and asserted equality with the real plan for every row (`raw/review/plans_per_device.txt`). First slice,
  base → PR:

  | device (binding → budget) | b62 1e17 | b60 1e16 | b62 1e16 | b58 1e16 |
  |---|---|---|---|---|
  | CUDA 10 GB (2.5 → 2.5 GiB) | 5→9 slots, 1693→2480 MiB | 4→8, 1599→2472 | 5→9, 1693→2480 | 4→7, 1705→2442 |
  | CUDA 4 GB (1 → 1 GiB) | 5→11, 521→975 | 4→9, 430→786 | 5→11, 521→975 | 4→8, 471→794 |
  | wgpu, 4 GiB−1 binding (→ 4 GiB) | 6→12, 2598→4080 | 6→11, 2658→3935 | 9→15, 2864→4043 | 5→8, 2835→3850 |
  | wgpu, 64-bit indexing (u64::MAX → 4 GiB) | same as above | | | |
  | lavapipe 128 MiB (→ 256 MiB) | unchanged (binding-bound) | | | |

- On CUDA the budget is a quarter of VRAM, so this is safe. On wgpu, `max_page_size` is
  `max_storage_buffer_binding_size` (`cubecl-wgpu/src/runtime.rs:291`), or `u64::MAX` with 64-bit indexing
  (`backend/vulkan.rs:96`). The budget therefore reaches 4 GiB whatever the device's memory. Take a 4–6 GB discrete
  card on Vulkan with a 4 GiB binding limit, or an 8 GB unified-memory Mac. A b60 1e16 field there used to plan
  2.6 GiB and now plans 3.9 GiB. `refit` only learns from layouts the device drops, not from an allocation failure
  or paging.
- This is pre-existing in `JoinLimits::for_buffer`, but this PR is what makes it bite. Nothing in L48 ran on a wgpu
  device at 1e16.
- **Fix:** do one of these. (a) Run one b60 1e16 field on a wgpu device (demoux 9070 XT over SPIR-V, mayalaran M4)
  and say so in the body. (b) Keep `SURV_PER_PREFIX` 2 where the budget is not a known fraction of device memory
  (non-CUDA runtimes). (c) At minimum, state in the body that real use rises to the budget, ~+45–55 % at 1e16+ fields.

### Low

**L1. The re-forming branch is exercised by exactly two test windows, and by no production-size or timed field.**
`cubecl_join.rs:2742-2757`.
- I computed, host-side, every P where the kernel's carried c0 must change. I used the test's own fields, plans and
  batches (`raw/review/c0_transitions.txt`). Transitions occur only in the b20 windows `[58945,160000) (2,3,1)` and
  `[60001,150003)`, at P = 201 (square, c0 6→7) and P = 231 (cube, 10→11). Both are stepped slots inside the device
  test's consecutive batches, on CUDA and on lavapipe.
- Every production plan in the test, every timed A/B field (b62 1e17 whole, b60/b62 1e16 whole, the 1e14 fields) and
  the whole-field b42 1e13 test has c0 constant from plo to phi. So the timed "exact counts" say nothing about this
  branch, and four lanes of #240's test are its only pin. The algebra is right: I checked it on 477 forced re-formings
  in the model.
- **Fix:** add a comment in `check_top_fd` that the b20 windows are the ones that step across a c0 change, so they
  are not trimmed later. Better: a host assertion (the `transitions` helper in `raw/review/review_l48_tests.patch`)
  that the test's fields include a stepped transition for both powers.

**L2. b64 is a consistent −0.3 %, not noise.** In 6 of 6 rounds over both A/Bs the ratio was 0.994–1.000; the
clock-normalised figure is ×0.980 in both. FD is off at powers of two (`TOP_FD_AT_POW2_BASES`), so the larger batch
(6→7) buys no seeds there. Either keep `SURV_PER_PREFIX` 2 where the FD kernel will not run, or write "−0.3 %
(FD off; plan only)" instead of "neutral".

**L3. The survivor list's headroom halves.** It is still adequate, but the doc comment should say so. At the large
fields a batch now overflows above 2.1–3.2 prefilter survivors per prefix and partition, against ~4.1–6.5 before.
The densest measured rate (1.6, dense b57) only binds where the survivor bound sets the slots. At 1e14–1e15 the
16-slot cap binds, so headroom there is ≥ 2.3×. On a 4 GB CUDA card, dense b58 1e15 fills 69 % (was 40 %).
- The overflow path (`run_slice`, `cubecl_join.rs:4112-4180`) is unchanged and exact. An overflowing batch's
  partitions re-run at half the batch size, then one at a time in the re-run layout, then with the top layer halved,
  down to single prefixes, which `MIN_RETRY_CAP` guarantees fit. It terminates.
- Suggest replacing "fill at most half its survivor list at this rate" (`join_plan.rs:69-75`) with the honest
  version: "half at the expected rate; ~80 % at the densest measured (1.6); a batch above 2 re-runs".

**L4. PR body and CHANGELOG accuracy.**
- CHANGELOG (`CHANGELOG.md:14`): "each power's digit count" is wrong. c0 = max(cap, ndig(e^k − a^k)) is where the
  certificate starts, not the power's digit count. Suggest "the position each power's certificate starts at". Also
  "about twice as many partitions per launch" → "up to twice". It is 5→9 and 4→8 at b62 1e17 and b60 1e16, 13→16,
  6→7 at b64, and unchanged at 1e14.
- Measurements table, "cycles" column: the 1e16 rows rest on 3–5 nvidia-smi samples (5 s interval, ~9–20 s runs;
  e.g. `ab2_P2_e16_b62_r1.smi` has 5). b62 1e16 "×1.197" is not credible. Drop the column for 1e16 rows or footnote
  it. The 1e17 row (23 samples) is fine.
- "Parts": "the early-exit carries 3–4 % of the slot". RESULTS §4 has 3.7 % (b62) and 2.6 % (b60), so write "about
  3 %".
- Exactness list: `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` runs `top_cert` (the division
  path, `cubecl_join.rs:5678`), not `cert_power_fd`. It is harmless to list, but the changed certificate code is
  pinned only by `cubecl_cuda_top_fd_matches_the_top_kernel`. Say that, instead of implying three tests cover it.
- "Plan" bullet: my host replica reproduces the slots exactly (9/8/16/7). It gives 2,480 / 2,472 MiB where the body
  has 2,457 / 2,431 MiB, presumably because the device reports slightly under 10,240 MiB. That is immaterial, but
  "2,560 MiB budget" may be a little high.
- RESULTS.md only (not the body): "`plane_sum` (a `REDUX` on sm_86)". `B`'s SASS has 0 `REDUX` (7 `SHFL`).

### Nits (code)
- `cubecl_join.rs:2736-2738`: `fd_step_words(base, f0, limbs)` is evaluated three times. `.min(3)` and `.min(4)`
  silently encode `top_fd_consts`' array sizes (`c2` 3 words, `k3` 4 words, `cubecl_join.rs:2609-2610`). Name them,
  or have `fd_step_words` clamp with the same constants.
- `cubecl_join.rs:2423-2432`: `dd` is written and never read; only the borrow matters. The compiler drops the stores,
  but a borrow-only loop reads more clearly.
- `pw_minus1` (`:2182`): the name hides "b^c − 1 − x". Consider `pow_minus_1_minus`, or keep it and lean on the doc,
  which is good.
- The kernel still allocates and zeroes `d2`/`d3` (`:2606-2617`). They are now scratch for a seed or a re-form only;
  the comment above them could say so.

## The seven checks

**1. The trims are exact.**
- *Carried c0 and dm* (`:2739-2757`, seed `:2779-2788`). The value is re-derived exactly when it could change; it
  does not rely on the "never changed in 1.1e9 lanes" observation. For unclipped consecutive blocks
  d = e^k − a^k is strictly increasing in P. c0 = max(cap, min(ndig d, s)) is therefore non-decreasing, and it moves
  only when d reaches b^c0.
  - With dm = b^c0 − 1 − d ∈ [0, b^c0), and b^c0 ≤ b^(s−1) ≤ a^k < 2^(32·nl), `sub_words`' borrow is exactly
    "d_new ≥ b^c0". Recovering d from the wrapped dm is exact mod 2^(32·nl), with d < 2^(32·nl).
  - At c0 = s, dm is never read again (`cert_power_fd` tests only when `c0 < sp`) and c0 cannot grow, so the
    unchecked wrap is harmless. The seed's `pw_minus1(pw, s3, …)` reads table row s3, which exists (`0..=s3`,
    `:3369-3384`).
  - Carry test: (x mod b^c0) + d ≥ b^c0 ⟺ x mod b^c0 > dm, which is the borrow of dm − rem (`:2419-2433`).
  - Pinned by #240's device test, common path on 26 fields. The re-forming branch is pinned only by the two b20
    windows (L1).
- *Short path above the run* (`:2387-2401`). in_run turns false only at a digit at a position ≥ c0, or before the
  scan when c0 < z. Every later position is then above c0, so the per-digit step reduces to "set the bit in `run`
  and `runc`": `above` is true, `runc` takes the bit since in_run is false, `ends` is false, and `low` adds 0 (so no
  `add_scaled_pow`, as p0 ≥ c0). The branch order rules out `c0 >= wend` there. The run mask is unchanged because
  nothing it depends on (in_run, qend, dlo) can change after the run ends. Pinned by the device test; it runs in
  nearly every certificate.
- *No a/e/clip on interior steps* (`:2654`). plo = s / w and phi = (e − 1) / w (`overlap_join.rs:1063-1064`,
  `1175-1176`), and `fb` carries the same slice's s and e − 1. For plo < P < phi, P·w > s and P·w + w − 1 ≤ phi·w − 1
  < e − 1, so the block is unclipped. The range check `p >= plo && p <= phi` still runs first.
  - `interior_step` implies `step`, so a seed always has a and e. The uninitialised a and e are never read: clipped
    = false, then the step path.
  - Pinned by the device test's 23 batches with a clipped block, and by the windows clipped at both ends (plo/phi
    seed or clip; plo + 1 steps when plo is unclipped).

**2. The ballot.** One ballot gives the plane total (sum of popcounts) and each lane's exclusive rank (popcount of
the bits below the lane, words below wholly). Every lane runs the slot loop and the loop bounds are cube-uniform, so
the ballot sits at a reconverged point. Dead lanes (i ≥ ntlay) contribute 0, `JOIN_WG` = 256 is a multiple of every
plane size, and a plane straddling ntlay just has zeros. The model checks planes of 4–128 lanes: dense and unique.
The one false assumption is that the backend returns all four words: see M1.

**3. Early-exit carries are pure optimisations.**
- Packed digits: for every byte < b ≤ 128, x + bias + 0 keeps bit 7 in every byte, so the fix takes the bias back,
  the word is unchanged, and the carry-out is 0. The state's invariant (digits < b; values below b^q, #240's) holds
  for every base the FD kernel accepts (`top_fd_fits`: b ≤ 64).
- Binary: x + 0 with c = 0 is unchanged, and x + 0xFFFFFFFF + 1 = x with carry 1, so skipping is identical.
- The comptime addend lengths (`fd_step_words`) hold: c2 = 2wδ < 2w², k3 = 6w²δ < 6w³, and Δ3(P−1) =
  3wδ(2Pw − 1) < 3w²·2^(32·limbs+1), since a < 2^(32·limbs). I checked b = 10..64 and every f0 with w < 2^32,
  limbs 1–3: no case where a block fits and an addend has a nonzero word above its bound.
- The model compares old and new on 200,000 random cases at b = 2..128, including forced long ripples: identical.

**4. The plan.** Only `by_survivors` changes (`join_plan.rs:328`). The budget and binding bounds are untouched and
bind first at b62 1e17 / b60 1e16 on a 10 GB card (my replica: bounds [16, 23, **9**, 11] and [16, 19, **8**, 9]),
as claimed.
- On 4–8 GB CUDA the budget binds too, at 7–11 slots, all within a quarter of VRAM. wgpu: see M2. lavapipe and
  128 MiB devices are binding-bound and unchanged.
- No field plans to a layout above its budget, and the `JoinPlan::new` replica assertion held for 77 device × field
  combinations. The overflow re-run is exact and terminates (L3).
- `max_slice_prefixes` with `SLICE_SURV_PER_PREFIX` = 2 is bit-identical to the old cut, so slices do not change on
  any device.

**5. NiceMark b60 ×0.976 and its fix.** The explanation is consistent with the data: `P` cut the sampled b60 window
into 1 slice instead of 2, a wider slice's field certificate prunes less (L1 PROFILE-3: +9.4 % AND pairs at 4 vs 11
slices), and NiceMark seeds every slot, so it gets nothing from the stepped-slot cut. It is plausible rather than
isolated (no profile of the extra pairs), but the fix does not depend on it: the final form's slice cut is
*identical* to the base's for every field and device. The effect therefore cannot recur at other sizes or bases
from this PR. (#249 changes the per-slot footprint and therefore `by_budget` in `max_slice_prefixes`, so it can move
slices; that is #249's to check, see 7.)

**6. Claims check** (body vs RESULTS vs raw):

| claim | raw | ok? |
|---|---|---|
| b62 1e17 107.90→99.76 ×1.082; b60 1e16 21.315→19.923 ×1.070; b62 1e16 ×1.093; b64 ×0.997; 1e14 ×1.014–1.034 | `ab2_table.md`, per-round values match | yes (b64 is −0.3 %, L2) |
| exact counts on every timed field, 0 re-runs | `ab2_table.md` counts/retried | yes |
| NiceMark ×1.029, scenarios ×1.018–1.036 | `nm2_table.md` | yes |
| kernel alone −30.8 / −32.8 % (c), stepped −32.1 / −31.1 %; seed 2.4× a step | `tp2_table.md`; 0.3433/0.1403 = 2.45, 0.3292/0.1380 = 2.39 | yes |
| predicts ×1.08 / ×1.07 | 1 − 0.25·0.308 → ×1.083; 1 − 0.21·0.328 → ×1.074 | yes (it folds the plan's fewer launches into c) |
| 108/107 registers, 0 spills, 2 blocks/SM; SASS 4,472/4,280 | `registers.txt` (P: driver JIT and nvcc agree); P2 has the same kernel (diff P→P2 = join_plan.rs only) | yes |
| SHFL 7→2, VOTE 0→2 | `sass/B`, `sass/P` `.sass`: 7/0 → 2/2 (POPC 8→10) | yes |
| SPIR-V TopFdKernel 280–298 blocks | `blocks_P_spv_l0.txt` | yes |
| plan 9 slots / 2,457 MiB, 8 / 2,431 | slots reproduced; MiB within 1–2 % (L4) | yes |
| "cycles ×1.197" at b62 1e16 | 3–5 smi samples a run | not credible (L4) |
| early exits 3–4 % of the slot | 3.7 / 2.6 % | slightly off (L4) |
| CHANGELOG "digit count", "about twice" | | inaccurate (L4) |

**7. Interaction with #249 (static bucket order).** #249 deletes this PR's whole append block in `top_fd_kernel`
(`plane_sum`/`plane_exclusive_sum`/atomic/broadcast plus the record and bucket writes) and replaces it with
`top_slot(...)`, which uses `plane_sum` + `plane_exclusive_sum` and is shared with `top_kernel`. Expect:
- a textual conflict in that hunk (`:2799-2840`). Whichever lands second should carry the ballot into `top_slot` (on
  `kc = kept && one`; the `!one` fallback is untouched), with M1's gate, or the ballot's ~5 points of the stepped
  slot are lost. Small conflicts are also possible in `top_fd_kernel`'s doc comment and parameter list (#249 drops
  `roots`, `top_b`, `top_count`, `bucket_cnt`, `nroots`, `pdiv_m1`, `key_level`; this PR does not touch them);
- a semantic interaction in the plan: #249 removes `top_b`, `tl` (ntl·nroots·4 per slot), `work` and `cursor` from
  `Footprint::per_slot`. The budget bound at the big fields then loosens, and this PR's survivor bound at 1 takes
  over: on a 10 GB card ~11 slots at b62 1e17, ~9 at b60 1e16 (the survivor bound above). Slices can also widen
  through `by_budget`. The plan numbers in both PR bodies become stale, and the combination should be re-measured
  once, NiceMark's b60 window included (the slice-width effect of 5).

## What I ran (ivory, no GPU; worktree removed afterwards)
- `git fetch fork …`; worktree at `bedc658`; `CARGO_TARGET_DIR` inside it (peak ~2 GB), `nice -n 19`.
- `cargo test --release -p nice_common --features cubecl,cubecl-cuda --lib join_plan:: cubecl_join::`: 11 passed,
  16 ignored (device tests). `cargo fmt --all --check`: ok. `cargo clippy -p nice_common --features gpu
  --all-targets -- -D warnings` (rustc 1.99.1): clean.
- Two review-only host tests, not on the branch (`raw/review/review_l48_tests.patch`):
  - `review_c0_transitions`: every P where the carried c0 changes, for the device test's fields, plans and batches,
    and for the timed whole fields (`raw/review/c0_transitions.txt`);
  - `review_plans_per_device`: a `JoinPlan::new` replica at `SURV_PER_PREFIX` 1 and 2, asserted equal to the real
    plan, over 11 device limits × 7 fields (`raw/review/plans_per_device.txt`).
- `raw/review/model.py`: a Python model of the biased adds, `add_words`/`sub_words` with early exits (200k cases);
  the comptime addend bounds; the carried (c0, dm) state against a fresh c0 and carry test over 3,000 random ranges
  that cross powers of b (477 re-formings); the ballot ranks for planes of 4–128 lanes; and the truncated-ballot
  wave64 case. Output in `raw/review/model_output.txt`.
- Read CubeCL 0.10.0's ballot codegen (`cubecl-cpp` shared/warp.rs, cuda/hip/metal dialects, hip/arch.rs;
  `cubecl-wgpu` wgsl/subgroup.rs, runtime.rs; `cubecl-spirv` subgroup.rs) and #249's diff (`gh pr diff 249`).
- Not run: any device test (no GPU here). The device-test verdicts above come from reading the code and L48's logs.

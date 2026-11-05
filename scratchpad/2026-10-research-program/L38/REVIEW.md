# Review of PR #241 "Overlap join: one 32-byte record per top" (head af21136 on main 6f060a9)

Reviewer: independent read-only review, 2026-11-05. Read the whole diff, every `top_rec` / `TOP_REC_WORDS` site in
`common/src/cubecl_join.rs` and `common/src/join_plan.rs` on the PR head, the production planning path
(`gpu_route::begin_niceonly` → `plan_join` → `run_slices_with` / `refit`), CubeCL 0.10's buffer alignment
(`cubecl-cuda`, `cubecl-wgpu`, `cubecl-runtime` memory pools, `wgpu-core` 29 adapter limits), the PR body,
`L38/RESULTS.md`, `L38/BRIEF.md`, `L37/RESULTS.md` and every table under `L38/raw/` (recomputed the A/B ratios from
`raw/clocks.txt`). Nothing built or run. Line numbers are on af21136.

## Verdict: merge with small fixes

The code is correct as written. Every reader and writer of the four arrays is converted one-to-one, nothing else
touches them, the plan cannot move for any device or base the client can see, and the records are 32-byte aligned on
every backend. CI is green on af21136, including lavapipe (naga and direct SPIR-V) and both macOS Metal jobs. The
measured numbers in the body match the raw data.

The fixes I would ask for are small. One is optional code: tie the three spellings of the record size together. The
rest correct the PR body: the "cycles" method, the scope of "every timed run sat at the cap", "an earlier single
round", the planning argument's wording, and a top-load figure with no source in the write-ups. None of them blocks
merge.

## Findings, by severity

No high or medium findings.

### Low

**L1. The record size is spelled three ways, and nothing ties them together** (code, optional).
`TOP_REC_WORDS = 8` (`cubecl_join.rs:81`) is used only on the host side (`3185`, `3292`, `3530`, `5777`). The kernels
hard-code `8u32` (`522`, `536`, `1683`, `2524`, `2781–2782`), the test slices `[..8]` (`5777`) and the footprint uses
a literal `32` (`join_plan.rs:237`). If someone grows the record (for example to fold `top_b` in), the footprint and
the kernels can drift apart without a compile error. The kernels already use module constants (`TOP_CAP` at `530`).
The file also has a precedent for this case: `NICE_RECORD_BYTES` lives in `join_plan.rs` and is asserted at
`cubecl_join.rs:70`. Suggested fix:
- `join_plan.rs`: `pub(crate) const TOP_RECORD_BYTES: usize = 32;` beside `NICE_RECORD_BYTES`, and
  `top_rec: ntl * TOP_RECORD_BYTES`.
- `cubecl_join.rs:70`: add `const _: () = assert!(TOP_REC_WORDS as usize * 4 == TOP_RECORD_BYTES);`.
- In the kernels, write `TOP_REC_WORDS * g` / `TOP_REC_WORDS * t`. It folds at compile time to the same code.

**L2. The FD-vs-top-kernel test cannot see a missing store of a word that both kernels set to the same value**
(test hardening, a weakness already on main).
`check_top_fd` runs `top_kernel` first and then the FD kernel on the same `JoinDevice`, reusing its `top_rec`
(`5868`, `5873`). `run_tops` reads whatever the buffer holds (`5769–5778`). For an unclipped top both kernels write
word 4 = 0, word 5 = w and word 7 = the field's seed flag (`2529`, `2530`, `2532` against `1688`, `1689`, `1696`). So
if `top_fd_kernel` dropped one of those stores, the stale value from the `top_kernel` run would still compare equal.
- End-to-end CPU parity would catch it: a missing range word empties the join.
- I checked by eye that all eight words are stored on every path: `top_kernel` `1684–1696`, `top_fd_kernel`
  `2525–2532`, the clipped launch through `top_kernel` with `only_clipped`.
- Optional fix, since this PR rewrote every store: refill `top_rec` (and `top_b`) with a sentinel before each
  `launch_top` in `run_tops`. One way is to swap in a handle created from `vec![0xA5A5_A5A5u32; n]`, which needs
  `&mut self`. Alternatively, alternate which kernel runs first per batch.

**L3. The PR body's planning argument is right in its conclusion but loose in two places.** Both are wording fixes
only; see "Q2" below for the derivation.
- *"`JoinPlan::new`'s [survivor bound] is at most `max_binding / (64 · ntl)`"* leaves out two things. First, the
  `.max(1)` floor at `join_plan.rs:318–319`. Second, the re-run layout (`join_plan.rs:341`), whose list may be as
  long as `max_binding / 8` rather than `/16`. Neither changes the outcome:
  - A slice cut by `plan_join` has `ntl ≤ max_binding / 128`, so the batch layout's survivor bound is ≥ 2 and is not
    floored.
  - The re-run asks for one slot, and the record allows `max_binding / (32 · ntl) ≥ 4`.
  - After a refused layout, the ceiling makes `budget ≤ max_binding`. The budget bound is then always at least as
    tight as the record's, because `per_slot > 32 · ntl`.
- *"The record is now the largest per-slot buffer that grows with the top layer"*: at b46, b50 and b64, `tl` has
  eight digit-sum roots, so `tl` is also 32 B per prefix and the two tie. At those bases `largest_per_slot` and
  `per_largest` are identical to main's.

**L4. The "cycles" column cannot be reproduced from the table's own columns** (PR body).
- The column is the median over rounds of the per-round ratio of (s × MHz). Recomputed from `raw/clocks.txt`:
  1.0336, 1.0568, 1.0293, 1.0599. These match the body.
- Multiplying the table's median s by its mean MHz gives a different set: ×1.045, ×1.050, ×1.027, ×1.048.
  RESULTS §6's "4.3 % fewer cycles" at b62 1e17 uses this second method.
- Fix: state the method ("median of the per-round ratios of device seconds × that run's mean clock"), or quote both
  sets. With the second method the clock-normalised range is ×1.03–1.05 rather than ×1.03–1.06.

**L5. "Every timed run sat at the cap (176–180 W, `SW power cap` throttling), at 66–70 °C" is true for the 1e16 and
1e17 whole-field runs only** (PR body).
- Those runs: per-run means 176–180 W, and 291 of 292 load samples flagged `0x4`.
- The 1e14 runs' samples read 147–180 W.
- The NiceMark runs each have one or two samples at load, at 154–171 W and 1485–1950 MHz, so their clock is unknown.
- Fix: scope the sentence to the whole-field runs.

**L6. "An earlier single round on the same box gave ×1.071 … ×1.080 … ×1.061"** (PR body). The screen ran one round
at b62 1e17 but two rounds each at b62 1e16 and b60 1e16 (RESULTS §2; `raw/scr_table.md`). Fix: "an earlier screen
(one round at b62 1e17, two at 1e16)".

**L7. "About 7.6·10^10 top loads per b62 1e17 field" has no source in L37/L38's results or raw data** (PR body).
- The figure appears only in the director's `EXPERIMENTS.md` summary and `L38/BRIEF.md`.
- It is plausible: kept tops × 2 roots, with 3.8·10^10 kept tops ≈ 9 % of the 1e17 / 62³ ≈ 4.2·10^11 blocks.
- Fix: give the derivation (kept tops counted on main × `nroots`), or drop the number. The ablation's 18.6 s carries
  the argument without it.

### Nits

- **N1.** `read_checked` (`3519`, `3527`) shadows its parameter `rec: &BatchRec` with `let rec = …top_rec`, a
  `Vec<u32>`. "rec" already means `BatchRec` throughout the driver (`3907`, `3986`, `4258`). Suggest `let tops = …`.
  The `rec` in `run_tops` (`5769`) reads fine in context.
- **N2.** `rec_len` is computed twice, identically (`3185`, `3292`). A one-line `fn rec_len(&self) -> usize` would
  keep the two bindings in step. Optional.
- **N3.** In the body's register table, the label "`top_kernel` b60 / b62 (clipped blocks) / b64" suggests only b62
  is the clipped launch. In RESULTS §5 both b60 and b62 are the `only_clipped` launch beside FD, and b64 is the full
  launch (FD is off at powers of two).
- **N4.** The body's vector-load paragraph says the two variants "tied on every field … each within its rounds'
  spread". Two corrections:
  - b62 1e17 was a single round, so there is no spread.
  - In time, the vec4 variant was ahead on all three fields: 1.1 %, 0.3 % and 0.9 %. It was even in cycles: S
    1.624·10^11, V 1.628·10^11 at b62 1e17, with V 20 MHz higher.

  "Equal in cycles; V's small lead in time is clock" would be the precise statement. Keeping the scalar loads is
  still the right call.
- **N5.** "The tests below ran on both builds" does not cover two items: the per-round counts of the timed fields and
  NiceMark's whole-field counts ran on the timed build (`a9495ec`) only. The two builds differ only in panic line
  numbers, so this does not matter in practice.
- **N6.** A side effect the body could mention: fewer storage bindings. `join_kernel` goes from 15 to 13 and both top
  kernels from 13 to 10. That helps wgpu adapters with a low `max_storage_buffers_per_shader_stage`.
- **N7.** The body's exactness section lists CUDA and lavapipe only. CI's macOS jobs, wgpu→Metal and CubeCL's direct
  MSL compiler, also ran the `cubecl_join` device tests on af21136 and passed. Worth one line. HIP stays untested, as
  for every join change.
- **N8.** CHANGELOG (`CHANGELOG.md:12`): accurate. Its neighbours (#235, #237, #240) are as technical. If you want it
  shorter: "Speed up the GPU overlap join by storing each top's data in one 32-byte record, so the join reads one
  memory sector per top instead of three ([#241](…))."

## The specific checks

### Q1. Readers and writers: complete and index-equivalent

On main, the four arrays have 52 uses, all in `cubecl_join.rs` and `join_plan.rs`. `git grep` of the PR head (all
`.rs`, `.md`, `.py` and `.toml` files) finds no remaining `top_p`, `top_m`, `top_r`, `top_x` or `Footprint::top`.
Mapping, with word j of the record = word `j mod 2` of old array `j / 2` (p, m, r, x):

| site (PR line) | old | new | check |
|---|---|---|---|
| `top_kernel` store, both launches (`1683–1696`) | `top_{p,m,r,x}[2g + {0,1}]` | `top_rec[8g + 0..7]` | same values, same g = slot·ntlay + idx |
| `top_fd_kernel` store (`2524–2532`) | the same | `top_rec[8g + 0..7]` (r = 0, w; x = tl_mod·pdiv + v, seedf) | same values, same g = slot·ntlay + at + pre |
| join batch load (`535–544`) | `top_m[2t], [2t+1]`, `top_r[2t], [2t+1]`, `top_x[2t], [2t+1]` | `top_rec[8t + 2..7]` | ✓ |
| join `v_part` (`522`) | `top_x[2·t0]` | `top_rec[8·t0 + 6]` | ✓ |
| `check_kernel` (`2781–2782`) | `top_p[2t], [2t+1]` | `top_rec[8t], [8t+1]` | ✓; t is the global top id from `t_id` → stage → list |
| `read_checked` (`3527–3531`) | `tp[2t], tp[2t+1]` | `rec[8t], rec[8t+1]` | ✓ |
| `run_tops` (`5769–5778`) | `[tp,tp,tm,tm,tr,tr,tx,tx][2g+{0,1}], tb[g]` | `rec[8g..8g+8], tb[g]` | same `[u32; 9]` order, so the same sort and comparison |
| `JoinDevice` (`2904`, `3105`) | 4 handles × `max_slots · ntl · 8` B | 1 handle × `max_slots · ntl · 32` B | ✓ |
| bindings (`3203`, `3240`, `3398`, `3422`) | `2 · max_slots · ntl` words each | `rec_len = 8 · max_slots · ntl` | ≤ the allocation (fp uses `ntl.max(1)`) |

- Every path that wrote the arrays writes the record: `top_kernel` (full launch, and `only_clipped` beside FD) and
  `top_fd_kernel`.
- `top_fill_kernel` reads only `top_b`, which is unchanged.
- The overflow halving (`run_partition`, `3976`) builds a new `JoinDevice` per half, so `ntlay` never exceeds the
  allocation.
- `8t + 7 < 2^30`: the record's bytes are at most `slots · per_slot ≤ budget ≤ JOIN_MEMORY_MAX = 4 GiB`, so u32
  indexing is safe.

### Q2. Footprint and plan: the plan cannot move in production

- **Footprint.** `per_slot` changes `4 · (8·ntl)` to `32·ntl`, so the bytes and `JoinPlan::bytes` are unchanged. The
  only places the change can act are `largest_per_slot`, which feeds `JoinPlan::new`'s binding bound
  `max_binding / largest` (`join_plan.rs:321`), and `per_largest` in `max_slice_prefixes` (`361`). Both now see
  32 B per prefix instead of `max(8, 4·nroots)`.
- **Production limits** always come from `ceiling.cap(JoinLimits::for_buffer(max_page_size))`
  (`cubecl_backend.rs:2634`):
  - `for_buffer` gives `budget ≤ 2·max_binding` (`join_plan.rs:97–105`).
  - `cap` keeps that, and when the ceiling is below `max_binding` it makes `budget ≤ max_binding`.
  - On wgpu, `max_page_size` is the adapter's `max_storage_buffer_binding_size` (`cubecl-wgpu` runtime.rs:291), so
    `max_binding` is the real per-binding limit.
- **`max_slice_prefixes`.**
  - `list_cap ≤ min(max_binding/8, budget/32) ≤ max_binding/16`, so `by_survivors = list_cap/8 ≤ max_binding/128`.
  - The record's term is `max_binding/2/32 = max_binding/64`.
  - So the cap, the slices and every slice's `ntl` are main's. The bound `ntl ≤ max_binding/128` holds for every slice
    cut by `plan_join`.
- **`JoinPlan::new`, batch layout** (with the same limits the slices were cut for). Its `list_cap` is the same
  formula, so `by_survivors = list_cap/(4·ntl)` lies in `[2, max_binding/(64·ntl)]`. The record bound
  `max_binding/(32·ntl)` is at least twice that and ≥ 4. Not binding.
- **Re-run layout.** It asks for one slot. The record bound is ≥ 4. Not binding.
- **After a refused layout** (`refit`, or `run_slices_with` re-planning on a lowered ceiling c with slices cut
  earlier):
  - If `c < max_binding`: then `budget' ≤ c = max_binding'`, and `room/per_slot < budget'/(32·ntl) ≤
    max_binding'/(32·ntl)`. The budget bound is always at least as tight as the record's.
  - If `c ≥ max_binding`: `max_binding` is unchanged and `ntl ≤ max_binding/128` still holds.
  - So the record never makes a layout fail that main's would have made.
- **Bases.** The digit-sum root counts at 40–64 are 0, 2, 4, 6 or 8; I computed them with `FieldSetup`'s rule.
  - At b46, b50 and b64 (eight roots), `tl` is already 32 B per prefix, so nothing in the plan changes.
  - At the other bases the argument above is base-independent.
  - Bases with no roots (b43, 47, 51, 55, 59, 63) are residue-empty and never planned.
  - Below 57 (b40–b56) the same holds. CUDA parity covers b50 and b54 after refused layouts.
- **Small devices.**
  - lavapipe (128 MiB binding, 256 MiB budget): `list_cap = 2^23`, slices ≤ 2^20 prefixes, record ≤ 32 MiB per slot,
    record bound ≥ 4 against a survivor bound ≥ 2.
  - The paravirtual Metal ceiling (512/512 MiB) has `budget = max_binding`.
  - The unit tests `small_devices_*` hold the record within `max_binding`
    (`plan.slots * fp.largest_per_slot() <= lim.max_binding`, `join_plan.rs:716`).
  - The A/B logs show `slots` and `plan_mib` identical on both sides for every field (b62 1e17 5/1671; b62 1e16
    13/2050; b60 1e16 4/1566; b64 1e16 6/2151; 1e14 16/1212, 1369, 1413).
- **Test-only limits** can break the body's `budget ≤ 2·max_binding` premise: `small_devices_get_smaller_layouts_or_none`
  uses 16 MiB / 1 GiB, and `with_plans` uses MAX/MAX. Only the expected `None` is asserted there, and it fails for the
  bottom lists (29 MiB) before the record.

### Q3. Alignment and vectorisation

- The join issues six 32-bit scalar loads (SASS: six `LDG.E.CONSTANT` off one base, RESULTS §5), so alignment affects
  speed only, never correctness.
- A record is `[32g, 32g + 32)` bytes from the buffer base, so it is 32-byte aligned whenever the base is. The slot
  stride is `32·ntl` bytes, a multiple of 32 for any `ntl`. No assumption about `ntl` is needed.
- **Buffer bases.**
  - CUDA: CubeCL 0.10 aligns to 512 B (`cubecl-cuda` runtime.rs:76).
  - wgpu: CubeCL aligns to `min_uniform_buffer_offset_alignment`, which `wgpu-core` 29 clamps to at least 32
    (instance.rs:687; Metal reports 64 or 256).
  - The sliced and persistent pools pad every slice to that alignment (`calculate_padding`), so every handle offset is
    a multiple of it.
  - So words 2–7 lie in one 32-byte sector on every backend, as the body says.
- A future vec4 binding would also be aligned (16 | 32).

### Q4. Tests

- **The device test reads the record correctly for both kernels.** `run_tops` builds
  `[r[0..8], tb[g]]` from `rec[8g..8g+8]`, in the same order as main's tuple. Both runs go through the same function
  after their own `launch_top`. The clipped batches (23 on CUDA, 20 on lavapipe) put `top_kernel(only_clipped)`
  beside FD in the second run. Caveat: L2's masking.
- **Backends.**
  - CUDA (RTX 3080, manual): CPU parity incl. b50/b54, the FD test (26 fields / 279 batches / 237,907,266 tops), the
    certificate test, dense b58/b62, whole b42, the 1e14 compare.
  - wgpu with naga and wgpu with CubeCL's direct SPIR-V: lavapipe, locally per RESULTS §3, and in CI on af21136. The
    SPIR-V CI step filters on `cubecl_`, which every `cubecl_join::tests::*` path matches.
  - wgpu→Metal and direct MSL: CI macOS on af21136, green.
  - HIP: not tested, as before.
- **Coverage.**
  - Every record word is read somewhere: words 0–1 by the check, 2–7 by the batch load, 6 also by `v_part` in test
    shapes. So CPU parity exercises the whole layout end to end.
  - The WGSL lint ran (16 shaders, 0 flagged). The only division touching the record, `rec[8t+6] / dm_div`, has a
    loaded dividend, not a half-shift.

## Claims check (PR body against `L38/RESULTS.md` and `raw/`)

| claim | verdict |
|---|---|
| Ablation (L37, 150 W): gathers 18.6 s of 72.4 s join (26 %), 14 % of the 129.7 s field; `tl` 0.35 s, `top_m` 2.5 s, `top_r` + `top_x` 15.7 s; "six times" | ✓ L37 §1 (0.35 + 2.5 + 15.7 = 18.55; 15.7/2.5 = 6.3) |
| "about 7.6·10^10 top loads per b62 1e17 field" | **not in L37/L38 results or raw data** (director's summary and brief only); plausible (L7) |
| A/B medians, rounds, spreads (b62 1e17 3.3 %/1.1 %; b62 1e16 3.0/0.4; b60 3.0/1.9; b64 0.8/0.7) | ✓ recomputed from `clocks.txt` |
| speed-ups ×1.100 / ×1.076 / ×1.060 / ×1.091 and per-round ratios | ✓ (1.0997, 1.0756, 1.0595, 1.0908) |
| MHz main/PR 1427/1502, 1453/1488, 1451/1497, 1417/1475; "35–75 MHz faster" | ✓ |
| cycles ×1.034 / ×1.057 / ×1.029 / ×1.060; "clock-normalised ×1.03–1.06" | ✓ as the median of per-round ratios; ×1.027–1.050 by medians × mean MHz (L4) |
| "10.9 s saved per field" at b62 1e17 | ✓ 120.369 − 109.458 |
| "Every timed run sat at the cap (176–180 W), 66–70 °C" | ✓ for 1e16/1e17 (per-run 176–180 W; samples 65–70 °C); **not for 1e14 or NiceMark** (L5) |
| "An earlier single round … ×1.071 / ×1.080 / ×1.061" | ratios ✓; **two rounds at 1e16**, not one (L6) |
| 1e14: ×0.977 / ×0.990 / ×1.021, neutral within spread | ✓ |
| same slots and layout size on both sides | ✓ every A/B log |
| NiceMark score 6075.4, 6066.3 against 6387.4, 6362.4; ×1.050 (1.051, 1.049); scenarios ×1.036 / ×1.012 / ×1.070 / ×1.083 | ✓ `nm_table.md` |
| top stage alone, medians of 6, unchanged | ✓ `topt_table.md` (within ±0.8 %) |
| nine 32-bit stores per kept top | ✓ RESULTS §5 (SASS: 9 `STG.E`) |
| vector loads tied (108.6/107.4, 8.95/8.92, 21.7/21.5), 4 more registers | numbers ✓, 40 vs 44 ✓; "within its rounds' spread" is moot at b62 1e17 (one round) and V led in time on all three (N4) |
| exactness: FD test 26/279/23/237,907,266; certificate 102,365/33,582/203,413/69,824; dense b58 and b62; whole b42; COMPARE counts; timed-field counts; NiceMark whole-field counts; lavapipe 21/142/1,018,088; lint 16/0; fmt and clippy | ✓ RESULTS §3–4 (the timed-field and NiceMark counts are from the timed build only, N5) |
| "timed build differs from this head only by one rustfmt line join" | ✓ `git diff a9495ec af21136`: that line join, plus "four"→"three" in a doc comment and the CHANGELOG link |
| registers table | ✓ `registers.txt` (main join b64 44/47, PR 47/47/44; top_kernel b64 main 95/95, PR 95/99/95); row label (N3) |
| occupancy unchanged, 5 cubes/SM from shared memory; no spills | ✓ RESULTS §5 |
| Soundness bullets (same values, same bytes, indices < 2^30) | ✓ (Q1) |
| "the plan does not move" | ✓ conclusion; derivation needs the L3 wording |

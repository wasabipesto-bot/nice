# The wide main kernel's word loop on the RX 9070 XT's compiler: what it costs, what can go (2026-11-28)

*Offline on ivory: Mesa 26.0.8 RADV/ACO for GFX1201 on the amdgpu drm-shim (container `g2mesa`), no card. Brief:
`B65/BRIEF-ACO.md`. Scratch branch `exp/mo-wide-aco` from `f503a13c` (worktree `~/projects/nice/.worktrees/mo-aco`).
Labels: **[M]** measured compiler output (ACO instruction counts, registers, LDS, waves); **[P]** the model's number
(cycles; `G2/port/model_rdna4.py`'s assumptions, plus a bank-conflict model whose hardware assumptions are mine and
unverified); **[L]** lavapipe runs (SPIR-V, lavapipe's own plane width 8, not 64). Exactness is not claimed here.*

## Verdict

- **The kill line is not met.** The first idea already removes more than 8 % of the word loop's modelled cycles per
  slot at 12 waves, and the best variant removes 21 % (wide) and 17 % (narrow) of them [P]. Instruction counts below
  are [M]; none of this is a measured speed-up.
- **The best variant (V5: commit `a4fb3543` for both kernels, wide alone at `3ef7b4f1`; the branch head `d762f82b` adds V6, a card control)**: one list entry per
  lane covering four chunks, digit-major slices so that the reads stay bank-conflict-free, and the W 64 transpose
  stores rotated over four chunks. `wide_kernel` b65: word loop 189 → 297 VALU per wave-iteration, but for twice the
  slots (128 → 256): **2.953 → 2.320 VALU cycles per slot (−21 %), and the loop's model bound 2.953 → 2.328 per slot
  (−21 %); the loop is now LDS-bound in the model, 3.4 % above its floor** (the slice reads alone). 120 VGPRs,
  21,504 B LDS, 12 waves per SIMD: occupancy unchanged [M]. With what the change adds outside the loop (more 3b
  setup, the rotation selects, the 64-entry step's larger tail), a round's phase 2 + 3b is ≈ −10 % (wide) and ≈ −6 %
  (narrow) [P, with an assumed list length]. lavapipe parity passes at b40, b65 and b64 [L].
- **The two obvious variants (V1, V2: two or four chunks per lane, chunk-major layout) remove even more VALU but are
  rejected**: they turn today's conflict-free slice reads into data-dependent bank conflicts (factor 1.9–2.1 in my
  model), and the loop is close to LDS-bound already, so they would very probably be slower on the card [P].
- **Yesterday's survivor count and fault hooks cost nothing measurable in this loop**: wide 187 → 189 VALU and 53 →
  54 SALU per wave-iteration, narrow 171 → 169 VALU and 50 → 51 SALU [M]. The hook is a `v_cmp` + `s_and` and four
  `v_cndmask` that replace four `v_mov` in the record branch; the count moved out of the loop.
- **The 18-vs-17-digit gap** is 20 VALU per wave-iteration (189 against 169), of which 10 are digit extraction (digits 16–17
  split over the words' top nibbles cost 3 VALU each instead of 1: +8; the 18th field: +2), 6 the 18th digit's
  address and ORs, 4 the record's word 0 [M].

## 1. The two loops at today's head [M] (listings `B65/aco/head_wide/`, `head_narrow/`, `loop4.txt` in each)

Method as `G2/build4s/box/dump.sh` (`B65/aco/box/dump.sh`): the test binary with `cubecl/spirv-dump`
(`box/build.sh`: own target dir, `-j 2`, nice 19, release without LTO: host code only, CubeCL builds the kernels at
run time), the compile-only path of the parity tests on lavapipe with `MIDOUT_FORCE_W=64` (wide: case
`65:4:10:717171717`, `maxpop` 18 from `WideCaps::for_base(65)`, default batch shape; narrow: slice 712012851),
spirv-val, `aco.sh` → `<kernel>.aco.txt`, `loops.py` (`G2/port/aco.sh` and the g2-cubecl worktree's `aco/`; the
brief's `G2/aco/` does not exist). `box/price.py` adds LDS bytes and the model; `box/table.py` makes the table.

| kernel | VGPRs | LDS B | waves/SIMD | instr | word loop per wave-iteration (128 slots = 2 entries × 64 lanes) |
|---|---|---|---|---|---|
| `wide_kernel` b65, W 64 | 120 | 21,504 | 12 | 2,448 | **189 VALU** (153 in the main block), 54 SALU (10 branches), **41 LDS** (36 slice `ds_read_b64`, 2 + 2 probe, 1 `ds_read2_b32` list), 5 VMEM, 92 waits; 20,992 LDS bytes |
| `g2_kernel` b64, W 64 | 120 | 21,504 | 12 | 2,158 | **169 VALU** (137), 51 SALU, **39 LDS** (34 + 4 + 1), 5 VMEM, 81 waits; 19,968 B |

Both match the earlier notes: wide 120 VGPRs / 21,504 B / 12 waves / 187 vcyc / 41 LDS at `10ddbf17`
(`G2/WIDE2-NOTES.md` §C), narrow 171 / 39 (`BUILD-NOTES.md` §12.2, 171 vcyc). The +2 (wide) and −2 (narrow) are §3.

Model per wave-iteration (SIMD-cycles: VALU 2 × vcyc, wave64 in two passes; LDS bytes / 64, i.e. 128 B/clk per CU):
wide VALU 378, LDS 328 → **VALU-bound, 2.953 per slot**; narrow 338 / 312 → 2.641 [P]. LDS is at 87 % / 92 % of
VALU already: this decides which variants can win.

## 2. Wide against narrow, instruction by instruction [M] (main block of the loop, both entries)

| | narrow | wide | why |
|---|---|---|---|
| slice reads `ds_read_b64` | 34 | 36 | 17 vs 18 digits × 2 entries (both words of a row in one 8-byte read in both) |
| address `v_add_lshl_u32` (dg + q·srow) << 3 | 34 | 36 | one per digit: the extraction and address are already 2 VALU per digit |
| digit extraction `v_bfe_u32` / `v_and_b32 127` | 26 + 8 | 24 + 8 | 7-bit fields at 0/7/14/21 cost the same as 6-bit at 0/6/…/24 |
| digits 16–17: `v_lshrrev` ×2 + `v_and_or_b32` each | — | 8 + 4 | split over the four words' top nibbles: 3 VALU per digit instead of 1 (**+8**; with the 18th field, extraction is 44 against 34: **+10**) |
| OR accumulation `v_or3_b32` + `v_or_b32` | 32 + 2 | 32 + 6 | 18 values per word → 8 or3 + 1 or (**+4**) |
| masks, kmask, ranks, entry decode | equal | equal | `v_bfi`, `v_and`, `v_bcnt`, `v_cmp`, `v_cndmask`, `v_sub` |
| main block VALU | 137 | 153 | +16 |
| record branch | 32 | 36 | word 0 `((p16>>4)+poff) \| d<<16 \| c<<24` (`v_or3` ×2) and 4 more copies, against `dws[3] >> 12` |

The other differences the brief names cost nothing in this loop: the **two-word masks** are two words in both kernels;
**digits 64..b by ballots** and the **pad row** are phase-2 work (lane 0 writes the rows); in phase 3b they are rows
like any other (row index ≤ 66). Per digit the loop is already near the floor of its form: **bfe + add_lshl + one OR
per word-pair = 3 VALU per (entry, chunk, digit)**, both words in one 8-byte read. ACO combined everything I looked for
(shift+add into `v_add_lshl_u32`, ORs into `v_or3_b32`, adjacent words into `ds_read_b64`, the list base into the
read's immediate offset). What it cannot do is share work between lanes: the 16 lanes of a stream extract the same
digits and differ only in the chunk base.

## 3. What yesterday's count and hooks cost here [M] (`pre_*` = `73bc0065`, `head_*` = `f503a13c`)

| | wide 73bc0065 → f503a13c | narrow |
|---|---|---|
| word loop VALU / SALU | 187 → 189 / 53 → 54 | 171 → 169 / 50 → 51 |
| opcodes added | `v_cmp_lg_i32` +1, `v_cndmask_b32` +4, `s_and_b32` +1, `v_min_u32` +1 | same |
| opcodes gone | `v_mov_b32` −4 | `v_mov_b32` −8 |
| VGPRs, LDS, waves | 120, 21,504, 12 (unchanged) | same |
| instructions (kernel) | 2,412 → 2,448 | 2,132 → 2,158 |

`F_SLAB_SPLIT`'s `lost` is one compare per step and a `v_cndmask` per record word; the selects take the place of the
copies that built the record vector, so the loop does not grow. The per-lane survivor count adds nothing to the loop
(the popcounts were there; the sum moved after it, through `s_nl[1]`). The CUDA +1.5 % (FIXES-NOTES) does not show up
in this compiler's word loop; the record branch and the expansion's hooks are where it would be.

## 4. Variants (scratch branch, compile-only; listings `B65/aco/<tag>_{wide,narrow}/`, diffs `B65/aco/diffs/`)

The idea behind all of them: **give each lane one list entry and several chunks**, so a probe's 18 digits are read
from shared memory, extracted and turned into a row address once for 2 or 4 chunks; the extra chunks' rows are a
constant (V1–V3) or per-lane (V4–V5) offset away. Every (entry, chunk) word is the same formula as today,
`!OR(rows of the probe's digits in chunk q) & valid(q) & kept(entry, q)`, and every record holds the same four words;
only which lane computes it changes, and so the records' **order within and across slabs** (the expansion and the
tests treat the records as a set; that is the one thing a card run must not find otherwise). The list's entries per
cube step stay 32 (V1) or become 64 (V2–V5; `my_lslots` counts the same total; `e < nlist + 63 ≤ 639 < pq`'s 640).

| variant (commit) | VGPRs / LDS / waves | instr | loop VALU / SALU / LDS ops | slots | VALU/slot | LDS/slot | bound/slot [P] | reads' bank factor [P] | outside-loop VALU per round | phase 2+3b per round [P] |
|---|---|---|---|---|---|---|---|---|---|---|
| wide head `f503a13c` | 120 / 21,504 / 12 | 2,448 | 189 / 54 / 41 | 128 | 2.953 | 2.562 | **2.953** | 1.00 | — | 1.000 |
| V1 two chunks/lane (`69561026`) | 120 / 21,504 / 12 | 2,401 | 143 / 53 / 39 | 128 | 2.234 | 2.406 | 2.406 (−19 %) | **1.88** → 4.39 | +14 | 1.39 |
| V2 four chunks/lane (`8b8f3f47`) | 120 / 21,504 / 12 | 2,622 | 224 / 73 / 75 | 256 | 1.750 | 2.328 | 2.328 (−21 %) | **2.14** → 4.89 | +42 | 1.58 |
| V3 V2 + skip unkept chunks 1–3 (`06e7a8f0`) | 120 / 21,504 / 12 | 2,651 | 236 / 83 / 75 | 256 | 1.844 | 2.328 (static) | 2.328 | 2.14 | +42 | 1.58 |
| V4 digit-major, chunks (t%16)^4k (`5e95b880`) | 120 / 21,504 / 12 | 2,702 | 297 / 73 / 75 | 256 | 2.320 | 2.328 | 2.328 (−21 %) | 1.00; stores 16 | +46 | 0.95 |
| **V5 V4 + rotated stores (`3ef7b4f1`)** | 120 / 21,504 / 12 | 2,782 | 297 / 73 / 75 | 256 | 2.320 | 2.328 | **2.328 (−21 %)** | 1.00; stores 4 | +90 | **0.90** |
| narrow head `f503a13c` | 120 / 21,504 / 12 | 2,158 | 169 / 51 / 39 | 128 | 2.641 | 2.438 | **2.641** | 1.00 | — | 1.000 |
| V1n two chunks/lane (`69561026`) | 120 / 21,504 / 12 | 2,124 | 132 / 51 / 37 | 128 | 2.062 | 2.281 | 2.281 (−14 %) | 1.88 → 4.15 | +14 | 1.48 |
| V6 = V5 + skip unkept chunks 1–3 (`d762f82b`, wide) | 120 / 21,504 / 12 | 2,814 | 309 / 83 / 75 | 256 | 2.414 | 2.328 (static; 1.55 if masked lanes are free and 46 % of slots unkept) | 2.414 | 1.00; stores 4 | — | — |
| **V5n digit-major + rotated stores (`a4fb3543`)** | 120 / 21,504 / 12 | 2,484 | 278 / 65 / 71 | 256 | 2.172 | 2.203 | **2.203 (−17 %)** | 1.00; stores 4 | +90 | **0.94** |

(`B65/aco/table.md`, from `box/table.py`. "Per round": one wave's phase 2 + 3b per round = steps × loop bound with the
conflict factor on the slice bytes + 2 × the VALU added outside the inner loops + the four transpose stores' conflict
cost; steps = E / entries-per-step + 0.5 with **E = 392.6 listed entries per round, the narrow b64 figure of
`PS/RESULTS.md`, assumed for b65** (not counted here). Phases 1, 3a, setup are unchanged and not in it.)

**Idea 1 — V1, two chunks per lane** (`q = t % 8` covers chunks q and q + 8; 32 streams; the second chunk at a
constant offset folded into `ds_read_b64`'s immediate). VALU −24 % (wide), −22 % (narrow); LDS ops −2. Passes the
8 % line on VALU alone. **Rejected for a reason the instruction count does not show:** today a 16-lane group is one
probe stream reading 16 chunks of one digit row, which the odd row stride puts on 16 distinct bank pairs (the comment
at `gpu.rs`'s `sl`: "(v + q) mod 16"). With 2 streams per group the bank pair is (digit + chunk) mod 16 for two
different digits, and they collide. `box/banks.py` (assumptions: 32 banks × 4 B, a wave64 `ds_read_b64` served 16
lanes per clock, random 18-digit probes): **1.88 clocks per group against 1.00**. In a loop at 87 % of its LDS bound
that makes it slower [P]. The narrow port (V1n) has the same flaw.

**Idea 2 — V2/V3, four chunks per lane**: VALU per slot −41 % (1.750), but 2.14× bank conflicts in the same model;
V3's skip of unkept chunks (a branch per chunk, correct because an unkept chunk's word is masked to 0) adds VALU in the
static count, and saves LDS only if masked-off lanes free LDS bandwidth, which I cannot check offline. Rejected with V1.

**Idea 3 — V4/V5, the layout made for the shared lanes** (the variant to run):
- Slices digit-major, `sl[(v·16 + q)·2 + half]`: a read's 8-byte bank pair is its chunk, whatever the digit, so a
  16-lane group reading 16 distinct chunks is conflict-free for any probes. Same size (`(b+1)|1` rows × 32 words),
  every writer changed with it (transpose stores, the 64..b ballot rows, the pad row `pad·32 + t`; the W < 32
  staging array uses the same index and is copied word for word).
- Lane t covers chunks `c_k = (t % 16) ^ 4k`: a stream's four lanes (st = t / 4) cover all 16 chunks, and in each of
  the four reads the 16 lanes of a group read 16 distinct chunks. The per-lane offsets `c_k·2` are formed once;
  per digit the code is `v_bfe` + `v_lshlrev 5` + 4 × `v_add_lshl_u32` + ORs (`g4r2w_wide/loop4.txt`). (A first try
  with the XOR inside the loop, `g4xw`, cost a `v_xor` + `v_lshlrev` per read: 351 VALU; with deltas relative to
  chunk 0, `g4rw`, ACO added a uniform base per read: 351 again; absolute offsets fixed both.)
- V4's catch: a transpose store (one task = one chunk, lane = digit) now puts all 64 lanes on one bank pair
  (16× per group). **V5** keeps the four tasks' words (chunks pl + 4i) in registers and stores them after the task
  loop, lane l taking task (l + j) & 3 in store j: 4 chunks per store, 4× instead of 16× (today 1×), for 44 VALU of
  selects per wave and round.
- Result: VALU per slot 2.320, LDS per slot 2.328, conflict-free reads by construction: **the loop is LDS-bound in
  the model at 2.328 per slot, 3.4 % above the slice reads' floor of 2.25.** VALU and LDS now balance, so a VALU-only
  trim (e.g. `v_lshl_add(dg, 7, byte offset)` instead of `lshlrev` + `add_lshl`, −18 VALU per iteration) would not
  move the model; a gain beyond V5 needs fewer slice bytes (skipping pad rows or unkept chunks, i.e. reads that
  masked-off lanes do not pay for), which only the card can price.

## 5. What a card run must check (nothing below could be checked offline)

1. **Exactness at 64 lanes.** lavapipe runs 8-lane planes: V5's 3b lane map and the digit-major layout ran there
   [L: `B65/aco/ex/`: wide b40 1234 and b65 717171717 PASS (n for n, every count) for V2, V3, V4, V5; narrow 712012851
   + 318575442 PASS for V1n (with V2 wide) and V5n], but **the W 64 transpose path, its rotated stores and the j = 32
   shuffle stage never ran**: at W 8 the stores go through the staging array. The fault tests on V5 pass [L, `ex/g4rn/`]:
   narrow `accounts_faults_are_loud` (712012851, 257 s) and wide `wide_faults_are_loud` (b65 717171717 + 0, 1,316 s):
   every fault loud as before, `F_PF_DROP` / `F_BAD_PARENT` pass the accounts as before. V6 wide parity PASS (`ex/g4sw/`). The card run: `wide_slices_equal_cpu` b65, `gpu_slices_equal_cpu`,
   the fault tests, all at W 64.
2. **The records' order changed** (same set). Anything that relies on records' slab positions (none found in the
   tests, which sort; the expansion takes records by slab) would show there.
3. **Whether the RX 9070 XT's LDS behaves as assumed**: 128 B/clk per CU, 16 lanes per clock for `ds_read_b64`,
   conflicts by 4-byte bank. If it serves more per clock, V5's VALU (−21 %) is what counts; if conflicts are counted
   otherwise, V1/V2 might not be as bad, and V5's rotated stores might be unnecessary. One timing of head against V5 at
   b65 (and V2 as the control for the conflict model) answers all three.
4. **The step's tail**: 64 entries per cube step instead of 32 wastes more of the last step of a round when lists are
   short. b65's list lengths per round were not counted here (the model assumes 392.6).
5. **Occupancy in practice**: ACO reports 120 VGPRs / 12 waves for every variant; RADV on the card should compile the
   same SPIR-V the same way (same Mesa?), which is worth one `RADV_DEBUG=shaderstats` line.

## 6. Housekeeping

- Branch `exp/mo-wide-aco` (7 commits on `f503a13c`), pushed to `fork` at the end; no pull request; `dev/mo-hooks` not
  touched. The variants are separate commits so V1–V3 can be timed as controls; **V5 for both kernels is `a4fb3543`**;
  the head `d762f82b` is V6 (V5 + skipped reads of unkept chunks 1–3, wide only): the card's answer to item 3's
  masked-lane question; the 46 % unkept share is narrow b64's (PS: 14.19M entries × 16 slots against 123M kept).
- Scripts `B65/aco/box/` (`build.sh`, `dump.sh`, `ex.sh`, `price.py`, `table.py`, `banks.py`); listings per variant
  under `B65/aco/<tag>_<wide|narrow>/` (every kernel's `.spv`, `.spvasm`, `.aco.txt`, spirv-val, `loop4.txt` = the
  word loop with every instruction); `pre_*` = `73bc0065`, `head_*` = `f503a13c`, `g2w` V1, `g4w` V2, `g4kw`/`g4k3w`
  V3 (all chunks / chunks 1–3 skipped), `g4xw`/`g4rw` the two failed address forms, `g4dw` V4, `g4r2w` V5, `g2n`
  V1n, `g4rn` V5n (and V5 wide), `g4sw` V6.
- spirv-val: every module passes except `WscatterKernel` / `Scatter3Kernel` (the known duplicate `ArrayStride`).

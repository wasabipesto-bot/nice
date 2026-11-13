# N21: a leaner walk and prefilter loop in the GPU join (2026-11-13)

Labels: **[M]** measured here, **[D]** derived from measured numbers, **[A]** assumed or taken from elsewhere (cited),
**[E]** an estimate. Instruction counts for the RX 9070 XT are **counts of what Mesa's compiler (ACO) emits for
GFX1201, not timings**; nothing here ran on that card.

## 0. Summary

@@SUMMARY@@

## 1. Setup

- **Experiment branch: fork `exp/n21-walk-loop`** = upstream main `a7a59c11` (#253) + a merge of fork
  `pr/join-prefilter-shift-pow2` (#255, head `42d2afd9`) + a merge of fork `pr/join-survivor-stage-512` (#256, head
  `0f6794a2`; the CHANGELOG conflict resolved by keeping both lines) = `a3a06511`, then the switch commits:
  `82a6e4e2` (P, L, W, M, M32), `a6ddf53e` (U; L's record 16-byte aligned), `75374470` (B), **`2d3e10d3` (D) = the
  head every timing and every listed test used** (binaries X4, Xd4, X4n below). `NICE_EXP_N21` is read by the host
  (`JoinDevice::new`) and passed to `join_kernel` as a comptime bit mask, so one binary holds every variant; 0 = the
  code of `a3a06511` (the ACO dump of mode 0 is the same shader as the unswitched tree's: same hash of the
  instruction listing at b62, §3).
- **Box**: Vast 60456234, RTX 3080 10 GB at a **180 W cap**, driver 580.159.03, i7-5960X (16 threads), toolchain
  1.99.1 (the repo pin). One target directory per tree: `target-E` (X…, X…n), `target-E-dump` (Xd…),
  `target-CM`, `target-CP`, `target-clippy-*`. Binaries and their md5 (`raw/box/out/b_*.out`, `builds*.out`):

| binary | tree, commit | features | md5 |
|---|---|---|---|
| X4 | E `2d3e10d3` | `gpu,cubecl-spirv` (CUDA + wgpu with CubeCL's SPIR-V compiler) | 31ed595c |
| X4n | E `2d3e10d3` | `gpu` (CUDA + wgpu via naga/WGSL) | af403bc7 |
| Xd4 (built under the label Xd3) | E `2d3e10d3` | `gpu,cubecl-spirv,cubecl/spirv-dump` | 5cfd2135 |
| X (earlier switches; dense compares of P, L, W, M) | E `82a6e4e2` | `gpu,cubecl-spirv` | a3dbda5a |
| CM | `exp/n21-popcount-test` `41e47e2d` | `gpu,cubecl-spirv` / CMn: `gpu` | 33468ebb / 152b8f33 |
| CP | `exp/n21-ffs-pop` `be24d187` | `gpu,cubecl-spirv` / CPn: `gpu` | 863cff04 / 7463e7bd |

- **ACO counts** (`raw/scripts/spvdump.sh`, `walkcount.py`, `acotab.py`; method of N16 §C): Mesa 25.2.7's RADV built
  on the box with ACO only (`taskC_build_mesa.sh`); the SPIR-V that CubeCL generates for the join kernel dumped on
  lavapipe by Xd (`CUBECL_DEBUG_SPIRV`, the production field shapes: b60 1e16, b62 1e17, b64 1e17 at N16's starts,
  `NICE_EXP_N21` per variant), and compiled for GFX1201 on RADV's null winsys (`pipec`, no required subgroup size, as
  wgpu creates it: wave64) with `RADV_DEBUG=shaders,shaderstats`. Dumps: `raw/box/spv/<b|d><base>_<n21>/`.

## 2. The loop as it is (mode 0 = main + #255 + #256)

Per entry slot, `while plane_any(x != 0) { if x != 0 { pop; prefilter; if pass { append } } }` (two copies, one per
entry slot; `walk_pf_lean` inlined). A round costs what the wave executes; the pass branch runs when any lane of the
wave passes (about 6 % of walked pairs pass the prefilter, so on a 64-lane wave most rounds with several busy lanes
take it) [A: N17/L51 pass rates].

**ACO, GFX1201, wave64, b62** (`raw/box/spv/d62_0`, first entry slot; b60 identical in count, b64 the same total with
two 32-bit multiplies instead of eight) [M]:

| group | instructions in a round where no lane passes |
|---|---|
| vote and loop control (`v_cmp_lg`, `s_and_b64` + `s_cbranch_scc0`, `s_mov exec` + `s_cbranch_execz`, latch `s_mov exec, -1` + `s_branch`) | 1 VALU + 6 SALU |
| pop: `trailing_zeros` = `v_ffbl` + `v_cmp_eq 0` + `v_cndmask 32`, then `x & (x − 1)` | 5 VALU |
| index (`v_add_lshl`) and the top's three words (`t_dm`, `t_glo`, `t_ghi`) | 1 VALU + 3 LDS |
| F = ah + p·dh, twice (`v_mul_lo_u32` + `v_add`) | 4 VALU (2 multiplies) |
| `seen` as a 64-bit value (`v_or`, `v_mov 0`, `v_lshlrev_b64 32`, `v_or 0`, `v_or3`) | 5 VALU |
| the four digits: `mul_hi(F, 62)`, `F·62`, `mul_hi(F·62, 62)` twice | 6 VALU (6 multiplies) |
| membership: four `v_lshlrev_b64` of `seen`, `v_or3`, `v_or` | 6 VALU |
| six distinctness compares + the sign test: 7 `v_cmp` (each writes an SGPR pair) + 5 `s_or_b64` + `s_nor_b64` | 7 VALU + 6 SALU |
| the pass branch (`s_and_saveexec_b64` + `s_cbranch_execz`) | 2 SALU |
| waits (`s_wait_dscnt`, `s_delay_alu`, `s_waitcnt_depctr`) | 7 |
| **total** | **59 = 35 VALU + 14 SALU + 3 LDS + 7 waits** (8 of the VALU are 32-bit multiplies) |
| + the pass path, when a lane passes and the stage has room (`ds_append` and its lane-offset distribution, the `t_id` load, two `ds_write`, the stage-full test) | + 23 (6 VALU, 6 SALU, 4 LDS, 7 waits) |

N16 counted the whole loop body, both paths: 113; here 111–112 (the pass path's stage-full branch, with its global
atomic, is in the body but skipped by `s_cbranch_execz` while the stage has room).

**NVIDIA SASS, RTX 3080 (sm_86), b62** (the driver JIT of the PTX each process compiled, `ptxjit.py --sass`;
`raw/box/sass/`) [M]: the walk loop is 78 SASS for both paths; a round where no lane passes executes 42: `ISETP` +
`VOTE.ANY` + 2 branches + `BSSY`, `BREV` + `FLO.SH` (the pop's lowest bit), `IADD3` + `IMAD.SHL` (index), 3 `LDS`,
2 `IMAD` (F), 2 `IMAD.WIDE.U32` + 2 `IMAD.HI.U32` (the four digits: ptxas already forms `mul_hi(F, 62)` and `F·62`
with one wide multiply), 2 `LOP3` (seen), 4 `SHF.L.U64.HI` + 2 `LOP3` (membership: one funnel shift per digit), 6
`ISETP.EQ.OR` + 1 `ISETP.LT.OR` (the compares chain through one predicate), `IADD3` + `LOP3` (pop), the branch, and
`BSYNC`/`NOP`/`BRA`. The compares and the membership test are cheap on NVIDIA: the predicate chain costs one
instruction per compare, the funnel shift one per digit. On ACO each compare is a VALU compare into an SGPR pair
plus a scalar OR (wave64 masks are 64-bit), and the multiplies are quarter rate.

## 3. The variants and why each is exact

Each is a bit of `NICE_EXP_N21` on `exp/n21-walk-loop` (combinations are the sums). "Exact" means: for every input
the kernel can see, the variant computes the same pass/fail for every walked pair and appends the same pairs, so the
survivor list holds the same set (order within the list may differ, which nothing reads).

| bit | name | what changes | exactness argument (every input) |
|---|---|---|---|
| 1 | **P** (ffs pop) | the walk's next bit: `find_first_set(x) − 1` instead of `trailing_zeros(x)` | the line runs only inside `if x != 0`; for x ≠ 0 both are the index of the lowest set bit (CubeCL: `FindILsb + 1` and `select(x == 0, 32, FindILsb)` in SPIR-V); x = 0 is the only input where they differ and it cannot reach the line. Host: n/a (identity of the two intrinsics on x ≠ 0); devices: below |
| 2 | **L** (one record per top) | `t_dm`, `t_glo`, `t_ghi`, `t_id` as one 16-byte-aligned shared array of 4-word records, so the walk's loads can merge | storage layout only: the same words, written by the same thread before the same barrier, read at the same top index; 4·u + c < 4·TOP_CAP for u < TOP_CAP |
| 4 | **W** (wide product) | `h = hi32(F·b)` and `F·b mod 2^32` from one 64-bit product | identical words by definition of `mul_hi`; host test `n21_wide_product_is_mul_hi_and_mul_lo` |
| 8 | **M** (popcount test) | the four digits' membership and distinctness as `popcount(A & !seen) == 4`, A = OR of `2^63 >> d` over the four digits (bit-reversed masks) | let D = {g2, g3, h2, h3} as a set; A has one bit per element of D (each digit < b ≤ 64, so each shift places exactly one bit of 64), so popcount(A & !seen) = \|D \ seen\| ≤ \|D\| ≤ 4, with equality iff the four digits are distinct and none is in `seen` — which is exactly today's test (six inequalities and four non-memberships). Digits < 64: `mul_hi(F, b) ≤ ⌊(2^32 − 1)·b / 2^32⌋ < b`, and at b = 64 the shift forms are 6-bit fields. Host test `n21_popcount_membership_matches_the_masks`: every 4-tuple at every base 10–64 against random seen sets, plus 10^7 random tuples, both word forms |
| 16 | M32 | as M with 32-bit one-hots and selects | same argument; same host test (dropped: +4 on ACO) |
| 32 | **U** (two pops per round) | the walk body twice per vote round (`#[unroll] for 0..2 { if x != 0 { … } }`) | each `if x != 0` body pops one bit and handles it exactly as before; the per-lane sequence of pairs is unchanged and the round only ends earlier |
| 64 | **B** (pow2 bit field) | at b = 2^s (b64): `g = (F >> (32 − 2s)) & (b − 1)` instead of `(F << s) >> (32 − s)` | both are bits 32 − 2s … 32 − s of F, for every F (s ≤ 16); host test `n21_pow2_low_digit_is_a_bit_field` (s = 1..8, edges + 10^6 random) |
| 128 | **D** (deferred append) | the walk sets the popped bit in a per-lane mask `pmk` when the pair passes (`pmk \|= select(pass, x_before ^ x_after, 0)`); a second walk over `pmk`'s bits appends them (same stage, same full-stage path) after the chunk's walk | `x_before ^ x_after` is the popped bit, so `pmk` holds exactly the passing pairs' bits of the chunk; the second walk appends each once, through the same code (stage while it has room, else the list with its own reservation). The flush check runs after the batch as before, so the stage's bound and the direct path are unchanged |

## 4. What ACO emits for each variant (GFX1201, wave64) [M]

Per walk round of the first entry slot (the second is the same ±1). **ALU** = VALU + SALU + LDS of a round in which no
lane passes (the waits and `s_delay_alu` hints excluded: they are ACO's scheduling, and they move with every change);
**all** includes them. The pass path is what a round adds when some lane passes (with D: the round of the second walk,
which runs only over the passing pairs' bits). Whole kernel: 96 VGPRs, 14,848 B of LDS, 16 waves per SIMD for every
variant (LDS-bound as in N16; no variant changes occupancy). `raw/aco_table.txt` (`acotab.py`).

| variant (`NICE_EXP_N21`) | b62 all | VALU | SALU | LDS | waits | 32-bit mul | **ALU** | Δ ALU | pass path ALU |
|---|---|---|---|---|---|---|---|---|---|
| 0 default | 59 | 35 | 14 | 3 | 7 | 8 | **52** | — | 16 (23 all) |
| 1 P | 56 | 33 | 14 | 3 | 6 | 8 | 50 | **−2** | 16 |
| 2 L (record not aligned, X) | 57 | 36 | 14 | 1 | 6 | 8 | 51 | −1 (b60: 0) | 16 |
| 2 L (record 16-byte aligned, X5) | 57 | 35 | 14 | 1 | 7 | 8 | 50 | **−2** (one `ds_read_b96`) | 16 |
| 4 W | 59 | 35 | 14 | 3 | 7 | 8 | 52 | 0 (ACO splits the 64-bit product into the same `mul_lo` + `mul_hi`) | 16 |
| 8 M | 55 | 32 | 9 | 3 | 11 | 8 | 44 | **−8** | 16 |
| 16 M32 | 68 | 45 | 8 | 3 | 12 | 8 | 56 | +4 | 16 |
| 9 P+M | 53 | 30 | 9 | 3 | 11 | 8 | **42** | **−10** | 16 |
| 11 P+L+M | 50 | 30 | 9 | 2 | 9 | 8 | 41 | −11 | 16 |
| 15 P+L+W+M | 50 | 30 | 9 | 2 | 9 | 8 | 41 | −11 | 16 |
| 11 P+L+M (aligned, X5) | 48 | 30 | 9 | 1 | 8 | 8 | **40** | **−12** | 16 |
| 128 D | 62 | 39 | 12 | 3 | 8 | 8 | 54 | +2, but no pass branch in the walk | append walk 27 |
| 137 P+M+D | 56 | 34 | 7 | 3 | 12 | 8 | 44 | −8, no pass branch | append walk 27 |
| **b64** 0 default | 59 | 35 | 14 | 3 | 7 | 2 | 52 | — | 16 |
| b64 8 M | 56 | 32 | 9 | 3 | 12 | 2 | 44 | −8 | 16 |
| b64 9 P+M | 53 | 30 | 9 | 3 | 11 | 2 | 42 | −10 | 16 |
| b64 73 P+M+B | 51 | 28 | 9 | 3 | 11 | 2 | **40** | **−12** | 16 |
| b64 137 P+M+D | 57 | 34 | 7 | 3 | 13 | 2 | 44 | −8, no pass branch | append walk 27 |
| b64 201 P+M+B+D | 54 | 32 | 7 | 3 | 12 | 2 | 42 | −10, no pass branch | append walk 27 |
| b60 0 / 9 | 59 / 53 | 35 / 30 | 14 / 9 | 3 / 3 | 7 / 11 | 8 / 8 | 52 / 42 | −10 | 16 |

U (two pops per round, bit 32): the two-pop loop body is 109 instructions against 2 × 56 for P+M+D (d62_169 against
d62_137), so U saves about 1.5 per pair, and only in rounds where some lane has a second bit; not pursued.

**Where M's eight go** (b62, P+M against P): the 7 `v_cmp` + 5 `s_or_b64` + `s_nor_b64` of the compares and the sign
test, the 5-instruction 64-bit `seen` and the 4 `v_lshlrev_b64` + 2 ORs of the membership test (24 instructions)
become 2 ORs (`seen` per word), 4 `v_lshrrev_b64` (the one-hots, from an `s_bfm_b64` constant), 4 ORs (`v_or3` + `v_or`
per word), 2 `v_bfi_b32` (A & !seen), 2 `v_bcnt_u32_b32` (the second accumulates) and one `v_cmpx_eq` that is also
the pass branch's exec mask (16). **P's two**: `v_cmp_eq 0` + `v_cndmask 32` of `trailing_zeros`. **B's two** (b64):
`(F << 6) >> 26` is two shifts on ACO, `(F >> 20) & 63` one `v_bfe_u32`.

## 5. CUDA, RTX 3080 at 180 W [M]

**Method.** One binary (X4, md5 31ed595c), the throughput harness `cubecl_cuda_join_throughput_fixed_fields` (one
untimed 1e14 warm-up field, then the timed field; seconds = its wall time), `raw/scripts/run.sh` + `ab.sh`; modes
interleaved, the order rotated by one each round; **every run started at ≤ 50 °C** (the wait logged as `cooled …` in
each START line, 45–55 s after a b62 run); nvidia-smi every 2 s (median clock and power over samples at ≥ 90 %
utilisation); each process's join kernel replayed through the driver JIT from its own PTX cache (`ptxjit.py`: the
register variant, `regs+local`; 40+24 is the known spill variant, L51 §3.3, about 3 % slower). Nothing else ran on the
box: no build, no test (checked by the gate scripts, `raw/scripts/gate_ab*.sh`). The card is power-capped in every
run (180 W, throttle reason 0x04) at 50–68 °C, not thermally limited. Counts identical in every run of a field.
`raw/ab_table.txt` (`abtab.py`), logs `raw/box/logs/ab_*`.

**A first protocol was discarded** (07:02–07:11, `raw/box/logs/ab1/`): runs started at ≤ 60 °C, the first at 40 °C, and
under the power cap a warmer card runs at a lower clock (1,410 against 1,455–1,485 MHz), so five runs of nearly the
same code drifted from 78.3 to 81.0 s in order of start; one run overlapped untimed tests that a stop file released
by mistake. P and W were then dropped from the timing because their SASS has exactly mode 0's instruction mix (78
SASS in the walk loop, the same opcodes; W's two products are already one `IMAD.WIDE.U32` on NVIDIA).

**b62 1e17** (4 rounds; seconds, clock, register variant; base ÷ mode, > 1 = faster):

| mode | r1 | r2 | r3 | r4 | base ÷ mode per round | median |
|---|---|---|---|---|---|---|
| 0 default | 78.50 (1455, 48) | 78.80 (1455, 48) | 78.74 (1455, 48) | 78.83 (1470, 48) | — | — |
| 9 P+M | 79.44 (1470, 47) | 79.62 (1470, 47) | 79.99 (1470, 47) | 79.60 (1485, 47) | 0.988, 0.990, 0.984, 0.990 | **×0.989** |
| 73 P+M+B (= 9's code at b62: an A/A pair with 9) | 79.79 (1470, 48) | 79.56 (1470, 47) | 79.69 (1470, 48) | 79.68 (1470, 47) | 0.984, 0.990, 0.988, 0.989 | ×0.989 |
| 41 P+M+U | 79.79 (40+32) | 80.91 (40+40) | 81.91 (40+56) | 81.25 (40+48) | 0.984, 0.974, 0.961, 0.970 | ×0.972 |
| 137 P+M+D | 81.38 (40+24) | 80.77 (1478, 47) | 81.38 (40+24) | 81.58 (40+24) | 0.965, 0.976, 0.968, 0.966 | ×0.967 (spill-free r2: 0.976) |

**b64 1e17 and b60 1e16** (3 rounds, after b62; b64 runs 160–169 s, about half of them at 50–66 °C under the cap):

| mode | b64 s (r1, r2, r3; regs) | base ÷ mode | median | b60 s (r1, r2, r3) | base ÷ mode | median |
|---|---|---|---|---|---|---|
| 0 default | 159.94, 160.50, 160.78 (47–48 + 0) | — | — | 14.72, 14.76, 14.78 | — | — |
| 9 P+M | 163.60, 163.62, 161.18 (48 + 16) | 0.978, 0.981, 0.998 | **×0.981** | 14.91, 14.95, 14.88 | 0.987, 0.987, 0.993 | **×0.987** |
| 73 P+M+B | 164.23, 161.23, 164.05 (48 + 16) | 0.974, 0.995, 0.980 | ×0.980 (B neutral against 9) | 14.87, 15.03*, 14.98* (= 9's code) | 0.990, 0.982, 0.987 | ×0.987 |
| 137 P+M+D | 168.37, 168.69, 168.89 (48 + 8–16) | 0.950, 0.951, 0.952 | **×0.951** | 15.12, 15.06, 15.03 | 0.974, 0.980, 0.983 | ×0.980 |

(*) the 40+24 spill variant. At b64 every process of 9, 73 and 137 compiled `join_kernel` to 48 registers + 8–16 B of
local memory and every mode-0 process to 47–48 + 0: there the popcount form's PTX itself draws a spilling allocation.

- **M costs about 1 % on NVIDIA**, as its SASS says: the walk loop grows from 78 to 82 instructions (a round without a
  pass from 42 to 46): the four one-hots are two `SHF` each on a 32-bit machine (`SHF.R.U64` + `SHF.R.U32.HI`) where
  the old membership test was one funnel shift per digit, and the six compares it removes were one `ISETP.EQ.OR` each.
  M's runs hold a slightly higher clock at the same 180 W (1,470 against 1,455 MHz) and are still slower.
- **U forces the spill variant** (40 registers + 32–56 B in every process) and loses 3 %.
- **D loses 2.4–3.5 %** (and its PTX draws the spill variant in 3 of 4 processes): on a 32-lane warp a round with a
  passing lane is rarer than on a 64-lane wave, so moving the append out of the walk saves less than the second walk
  and the mask bookkeeping cost.

## 6. What the counts predict for the RX 9070 XT [E]

**Estimate, not a measurement.** Price per instruction per walked pair: N17's probe added four operations (eight or
nine instructions) to every walked pair and lost 4–7 % of a b62 field, i.e. **0.45–0.85 % per instruction** [A: N17.1];
on NVIDIA the same accounting gives about 0.28 % per SASS instruction (M: +4 SASS per round, −1.1 % [D, §5]). Which
instructions the price applies to is open: the probe's were VALU; SALU and VALU issue from different waves in parallel
on RDNA, so the low end below counts VALU only and the high end every ALU instruction (VALU + SALU + LDS), both from §4.

| variant (candidate) | Δ VALU | Δ ALU | predicted gain at b62 (low – high) | at b64 |
|---|---|---|---|---|
| P (`exp/n21-ffs-pop`) | −2 | −2 | ×1.01–1.02 | same counts |
| M (`exp/n21-popcount-test-wgpu`; on wgpu it is mode 8's code) | −3 | −8 | ×1.01–1.07 | same counts |
| P+M (both) | −5 | −10 | **×1.02–1.09**, central (0.5 %/instr on 5–10) ×1.03–1.05 | the prefilter is 30 % of a b64 field against 26 % at b62: about the same or slightly more |
| P+M+B (B folded into #255) | −7 at b64 | −12 at b64 | — | ×1.03–1.10 |
| D, with P+M | +4 in the walk | −8 in the walk, the 16-instruction pass path moved to a second walk over the passing bits | depends on how many rounds of a wave64 see a passing lane, which nothing here measures | |

The waits ACO schedules (`s_delay_alu`, `s_wait_dscnt`) go up by 4 with M (7 → 11): if they cost an issue slot each,
M's net is −4 instructions per round, not −8. The window measures it.

## 7. Exactness evidence [M]

@@EXACT@@

## 8. Ranking and what I would PR

1. **M off CUDA — `exp/n21-popcount-test-wgpu` @@CMW@@** (one commit on main `a7a59c11`; `cubecl_join.rs` only,
   +74/−22): `walk_pf_lean` takes a comptime `count`; `JoinDevice` sets it for every runtime but CUDA (wgpu on Vulkan,
   Metal, DX12; HIP), so the CUDA kernel is today's code byte for byte and the RX 9070 XT gets −8 ALU instructions per
   walked pair (§4). Host model `pf_count` added to the two existing membership tests. The gate is the measured fact
   that the same form costs 1–2 % on NVIDIA (§5). **Open it as a PR only after the window** measures ≥ ×1.03 on the
   9070 XT (my estimate ×1.01–1.07, §6). Its effect on the M4 (Metal, 6 % of the search) is unknown: Apple's compares
   are per-lane predicates like NVIDIA's, so it may lose ~1 % there; if the window confirms the AMD gain, a later
   check on the M4 can narrow the gate to Vulkan.
2. **P — `exp/n21-ffs-pop` @@CP@@** (one commit on main, 4 lines): −2 VALU per walked pair on ACO, identical SASS
   mix on NVIDIA (A/A there, §5). Too small for the ×1.05 bar alone (×1.01–1.02 estimated); stack it on 1 if the
   window's P+M beats M by ≥ 1 %.
3. **B — fold into #255** (not a branch: it changes #255's own lines). At b = 2^s write the low digit as
   `(f >> (32 − 2s)) & (b − 1)` instead of `(f << s) >> (32 − s)`: ACO emits one `v_bfe_u32` instead of two shifts,
   −2 VALU per pair at b64 (§4); neutral on CUDA (b64 ×0.980 against 9's ×0.981); host test
   `n21_pow2_low_digit_is_a_bit_field` on the experiment branch.
4. Not to PR: D (second-walk append; −2.4 to −4.9 % on CUDA, and on ACO its walk is 2 ALU above P+M's no-pass round —
   it pays only if most wave64 rounds see a passing lane, which the window can test as mode 137), U, L, W, M32, Z.

`exp/n21-popcount-test` @@CM@@ (M on every runtime) is superseded by 1: it is the same kernel on wgpu and loses 1–2 %
on CUDA.

## 9. What did not work

- **W** (one 64-bit product for `mul_hi(F, b)` and `F·b`): a no-op on both compilers. ptxas already forms both
  words with one `IMAD.WIDE.U32`; ACO lowers the 64-bit product back to `v_mul_lo_u32` + `v_mul_hi_u32` (it has
  `v_mad_u64_u32` but does not use it for this pattern).
- **M32** (one-hots per 32-bit word with selects): +4 ALU on ACO.
- **L** (one record per top) needs the record 16-byte aligned: with CubeCL's default placement (X, `82a6e4e2`) ACO
  split the three loads into two `ds_read2_b32` and added an address instruction (−1 ALU at b62, 0 at b60); with
  `SharedMemory::new_aligned(…, 16)` (from `a6ddf53e`) they are one `ds_read_b96`: **L −2 ALU (2 LDS loads) at b62,
  P+L+M −12** (`z62_2`, `z62_11`). Not made a candidate (an estimated ×1.01 alone); a third stackable change if the
  window confirms the price.
- **U** (two pops per round): about −1.5 instructions per extra pair on ACO; on CUDA it forces the spill variant
  (40 registers + 32–56 B in every process) and loses 3 %.
- **D** (deferred append) and **Z** (D without the per-lane branch): on CUDA ×0.95–0.98; on ACO D's walk is 44 ALU
  against P+M's 42 (no pass) / 58 (some lane passes), and Z made it 46 (ACO trades the saved exec-mask SALU for
  VALU selects). D's value on the 9070 XT depends on the share of wave64 rounds with a passing lane.
- Ideas from the brief not built, with the reason: (1) **one `mul_hi` by b² then a split** — exact (F·b² =
  X·2^32 + Δ with Δ < 2^25 gives X = `mul_hi(F, b²)` exactly), but splitting X into its two digits takes a
  multiply-shift and a multiply-subtract (four instructions with the `mul_hi`) where today's form takes three; a
  24-bit fixed point that would make every multiply a full-rate `v_mul_u32_u24` is not exact (Δ reaches 2·b⁴ > 2^24
  at b ≥ 58). (5) **compaction / group walk**: L40/L51 rejected it on NVIDIA; not retried.
- **Process**: the first CUDA protocol was discarded (§5); one `ab.sh` default list was a single quoted word, so the
  first protocol-2 pass timed b62 only and b64/b60 ran as a second pass (same binary, same rules, `gate_ab3.sh`).

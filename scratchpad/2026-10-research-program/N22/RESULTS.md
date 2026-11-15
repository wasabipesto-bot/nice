# N22: the next gain for the RX 9070 XT at bases 62 and 64, found without the card (2026-11-15)

Labels: **[M]** measured here, **[D]** derived from measured numbers by the arithmetic shown, **[A]** assumed or taken
from elsewhere (cited), **[E]** an estimate. Instruction counts for the RX 9070 XT are **counts of what Mesa's
compiler (ACO, Mesa 26.0.8) emits for GFX1201, not timings**; nothing here ran on that card.

## 0. Verdict against the kill criterion

__VERDICT__

## 1. Where a field's time goes on the card after the five PRs (task 1) [D]

`raw/scripts/shares.py` → `raw/shares.txt`. Inputs, all from the card: N17.1's doubling shares (b62 1e17 on a 73.5 s
tree: prefilter 25.9 %, check 16.3 %, AND 11.1 %, walk 6.1 %, transposed copy 0.9 %; b64 1e17 on the 151.6 s tree
without #254: prefilter 30.4 %, check 17.5 %, AND 10.5 %, walk 8.0 %) [M]; N13's full-clock phase timers of mode c
(main c0c357a: top FD 18.21 s, bucket 3.17 s, upload 2.71 s of a b62 field) [M]; the PR gains on the card: #250
×1.041 (b62, N13.1), #251 ×1.12 / ×1.135 (b62 / b64, N21.2), #255 + #256 72.9 → 68.5 s / 136.5 → 117.7 s (N21.2),
#255 alone 150.16 → 142.90 s at b64 (N17.1), #259 ×1.037 / ×1.080 (N21.2) [M]. Attribution [A]: each PR's seconds
come out of the part it changes (#250 the top kernel, #251 the check, #255 and #259 the prefilter); #256's occupancy
gain (12 → 16 waves per SIMD) is spread over the join kernel's parts in proportion; at b64 the top kernel's share
after #254 is the RTX 3080's ratio (B64 §5.1: ×0.445 of the old top) applied to the card's measured 15.6 s saving.
#260 is neutral (T26.1). The parts sum to 58.1 s at b62 and 92.8 s at b64; multiplying the PR gains gives 59.0 s
and 96.0 s.

| part | b62 1e17 (s) | share | b64 1e17 (s) | share | basis |
|---|---|---|---|---|---|
| top certificates (FD kernel, clipped tops aside) | 15.2 | **26 %** | 12.1 | 13 % | N13 timer − #250 [D]; b64 by the 3080's ratio [A] |
| prefilter (walk_pf_lean in the walk) | 14.2 | **24 %** | 24.1 | **26 %** | N17.1 doubling − #255 − #256 − #259 [D] |
| AND (transposed, digit loop + pass masks) | 7.1 | 12 % | 13.5 | 15 % | N17.1 doubling × #256 [D] |
| walk rounds (vote, pop, loads, append) | 3.9 | 7 % | 10.3 | 11 % | N17.1 doubling × #256 [D] |
| check kernel | 3.9 | 7 % | 10.3 | 11 % | N17.1 doubling − #251 [D] |
| join base (batch and entry loads, barriers, stage + flush) | 4.4 | 8 % | 6.8 | 7 % | [A] 5 s / 8 s of the rest, × #256 |
| bucket kernel | 3.2 | 5 % | | | N13 timer [M] |
| upload + host per batch | 2.7 | 5 % | | | N13 timer [M] |
| other (clipped tops, launches) | 2.9 | 5 % | 15.7 (bucket, upload, host, other) | 17 % | the remainder [D] |
| transposed copy | 0.6 | 1 % | | | N17.1 doubling [D] |

What is measured: every input above, on the card. What is inferred: every split of a PR's gain, the top's share at
b64, and the join base (no doubling mode measured it at full clock). The two largest parts are the FD top kernel at
b62 (untouched by the five PRs) and the prefilter at both bases.

## 2. What ACO emits for the integration build (task 2) [M]

**Method** (N21's, `raw/scripts/spvdump.sh`, `loops.py`, `walkcount.py`, `tables.py`): the spirv-dump build of fork
`exp/n22-rdna4` (binaries Ed1/Ed2/Ed3; with `NICE_EXP_N22=0` its kernels are `exp/integration-1114`'s) runs one
production-shaped field on lavapipe (b62 1e17 at N16's 0.45 start, b64 1e17 at 0.55) with `CUBECL_DEBUG_SPIRV`;
every kernel's SPIR-V is compiled for GFX1201 by RADV **built from Mesa 26.0.8** (the version CI's lavapipe is;
ACO only, `raw/scripts/build_mesa.sh`) through a small pipeline program (`taskC/pipec.c`, wave64 as wgpu creates
it). **Mesa 26 removed `RADV_FORCE_FAMILY`**, so the device is the amdgpu no-op DRM shim (`-Dtools=drm-shim`,
`LD_PRELOAD=libamdgpu_noop_drm_shim.so AMDGPU_GPU_ID=gfx1201`; RADV reports "AMD Radeon RX 9070 XT (RADV GFX1201)",
subgroup 64). Every dump sets `NICE_EXP_N22` bit 1, which forces the scan-form plane appends (lavapipe's planes are
≤ 32 lanes, so it would otherwise compile the ballot forms the card never runs). **CubeCL's SPIR-V for one kernel id
differs from run to run** (md5 of the module changes); three dumps of each variant give the same ALU totals, with
the VALU/LDS split moving by one (ACO merges two of the walk's three loads into a `ds_read2` in some modules)
(`raw/aco_repeat.txt`). Dumps: `raw/box/spv/<label>/` (`v62_1` … = Ed2, `a…` = Ed3, `e…` = Ed1), tables
`raw/aco_tables.txt`.

**Whole kernels** (b62 / b64; ACO's shader statistics):

| kernel | VGPRs | LDS | waves per SIMD (limit) | instructions | ACO latency / inverse throughput |
|---|---|---|---|---|---|
| join | 96 | 15,360 B | 16 (LDS and VGPRs both at their 16-wave line) | 1,322 / 1,358 | 353,923 / 96,697; 324,949 / 69,355 |
| FD top | 96 | 1,024 B (2 words, allocation granule) | 16 (VGPRs; N16 saw 84 and 18 on main of 11-12) | 6,658 / 6,253 | 68,013 / 36,217; 56,009 / 27,492 |
| check | 48 | 0 | 32 | 1,123 / 1,045 | 27,012 / 15,342; 21,875 / 11,090 |
| bucket | 48 | 1,024 B | 32 | 451 / 335 | 16,137 / 9,168; 9,578 / 3,412 |

No spills, no scratch, no clamps in any kernel. The join kernel's 15,360 B (N21: 14,848 B before #251's account
words) and 96 VGPRs both sit at 16 waves: freeing LDS alone no longer buys occupancy.

**Join kernel, a walk round in which no lane passes** (first entry slot; the second is the same ±1; ALU = VALU +
SALU + LDS, waits excluded):

| | b62 | b64 |
|---|---|---|
| total ALU (VALU / SALU / LDS) | **44** (33 / 9 / 2–3) | **44** (33 / 9 / 2) |
| vote and loop control (`v_cmp_lg` + `s_and_b64` + `s_cbranch_scc0`, `s_mov exec` + `s_cbranch_execz`, latch `s_mov exec, -1` + `s_branch`) | 1 VALU + 6 SALU | same |
| pop: `trailing_zeros` = `v_ffbl` + `v_cmp_eq 0` + `v_cndmask 32`; `x & (x − 1)` | 5 VALU | same |
| index + the top's three words | 1 VALU + 2–3 LDS | same |
| F = ah + p·dh, twice | 2 `v_mul_lo_u32` + 2 adds | same |
| the four digits | 6 quarter-rate multiplies (`mul_hi`, `mul_lo`) | 4 shifts + 2 shifts (#255's `(F << 6) >> 26`) |
| seen (2 ORs), one-hots (4 `v_lshrrev_b64` of `s_bfm_b64 1, 63`, rematerialised every round), A (`v_or3` + `v_or` per word), `v_bfi` ×2, `v_bcnt` ×2, `v_cmpx_eq 4` | 13 VALU + 1 SALU | same |
| pass branch | 1 SALU | same |
| 32-bit multiplies | 8 (quarter rate) | 2 |
| pass path when a lane passes and the stage has room | +12–13 ALU | same |

This is N21's P+M count minus nothing: #259 is in (M), the cheap pop (P) is not. The round is latency- and
issue-count-bound by N21's calibration (§3); the six quarter-rate multiplies at b62 cannot become 24-bit ones (F is
a 32-bit fraction).

**Join kernel, the transposed AND's digit loop** (one pop of the entry's 64-bit mask, four chunks): **23 ALU**
(16 VALU, 5 SALU, 2 `ds_read2_b32`): `v_or` + `v_cmpx` + `s_andn2`/`s_cbranch_scc0` (loop test), `v_cmp` + 2
`v_cndmask` (which word), `v_ffbl`, `v_add3` + `v_lshl_add` (address), `v_add` + `v_and` (pop), 2 `v_cndmask`
(update), 4 `v_or`, latch. An entry has 2·(f0 + pp) + 2 = 12 digits at both bases, all lanes the same count, so a
wave runs exactly 12 pops per entry slot and chunk group. Each pop waits on its two loads before the ORs.

**Check kernel, one list entry** (the loop body, both gate paths): b62 **765 ALU, 240 quarter-rate multiplies**
(VALU issue 1,510 full-rate units); b64 714 ALU, 114 quarter-rate (1,103 units). The limb products (`nn[i]·nn[j]`,
`sq[k−j]·nn[j]`) are `v_mul_lo_u32` + `v_add` because ACO cannot prove the limbs below 2^24; `put2`'s
`d_div(y, b)` is a 32-bit `mul_hi`; 71 / 90 64-bit VALU (the mask's `1u64 << digit`).

**FD top kernel, one slot of the slot loop** (`raw/topfd_blocks_b62.txt`, `_b64.txt`: every block with its counts and
branches; one loop of 171 / 177 blocks, 5,021 / 4,697 ALU in all paths) [M per block; the path sum E]:

| piece of a stepped, unclipped slot (b62) | ALU | notes |
|---|---|---|
| slot head (range test of P, step test, clip test) | 33 | 64-bit compares `v_cmp_le_u64` ×2, `v_cmp_lg_i64` ×2 |
| `top_fd_step`: five biased packed-digit adds (13 words) | 104 | ~6 per word: `v_add3`, `v_lshrrev 7` + `v_and 0x01010101` + **`v_mul_lo_u32 0xc2`** (the fix-up, quarter rate, 13 per slot), `v_sub`, `v_xad` (carry); +12 per word-extension block when a carry passes the shorter operand |
| `sub_words` ×2 + `add_words` (dm2, dm3, Δ3 in binary) | 89 | each word `v_add_co` + `v_addc` + `v_add_co` + `v_addc` + `v_mov` + `v_lshrrev_b64 32`: the u64 carry costs ~6 per word where a carry chain would be 2; +22 per borrow-extension block |
| `cert_power_fd`, square (5 digit words) and cube (7) | ~420 [E] | per word: below c0 13 (`word_value`: 3 `v_mad_u32_u24`) + 9–46 (`add_scaled_pow`, 3–11 quarter-rate); the word holding c0 67–70 (four digits, each a 64-bit `v_lshlrev_b64` and 6–8 selects); above c0 18–24; c0 differs across a wave's 64 lanes, and each word's paths run as the union |
| `close_cert` | ~110 [E] (167 all paths) | 64-bit masks, `dom_mask`, the forcing tests |
| `top_slot` (scan form, 64-lane planes) | ~122 | **four DPP reductions/scans** of ~13 each: `plane_sum(g)`, `plane_sum(a0)`, and the reduction + scan RADV's uniform-atomic pass wraps around the leader's single `buffer_atomic_add` (it cannot know one lane runs it) |
| a seed (first slot of a group, after a gap or a clipped slot) | ~2,100 | `BB88` alone 1,594 ALU with 254 quarter-rate multiplies at b62 (26 at b64) |
| **a stepped slot, typical path** | **≈ 880 [E]** | no piece above 48 %; the cert's digit words are the largest single block |

**Bucket kernel**: 305 / 201 ALU per bottom entry (88 / 0 quarter-rate: b62's `% base`, `/ base` of digit sums).

**What ACO does badly here** [M, from the listings]: (1) the walk's vote loop (`plane_any` + inner `if`) costs 7
instructions where a per-lane loop costs 5, and `trailing_zeros`' zero case costs 2 the loop cannot reach; (2) the
constant `1 << 63` is rematerialised (`s_bfm_b64`) in every round; (3) b64's `(F << 6) >> 26` is two shifts where
`v_bfe_u32` is one; (4) the check kernel's 12-bit limb products run as quarter-rate 32-bit multiplies (and its
digit split as a 32-bit `mul_hi`) because nothing tells ACO the limbs are small; (5) in the FD top kernel, u64
accumulators for multi-word adds become 6 instructions per word with a `v_lshrrev_b64 32`, the packed-digit fix-up
multiplies by a constant at quarter rate, and the scan-form append pays four DPP sequences per slot; (6) no 64-bit
emulation, no spilled or reloaded loop invariants, no selects that became branches in the hot loops.


## 3. Candidates (task 3)

Every candidate is a bit of `NICE_EXP_N22` on fork **`exp/n22-rdna4`** (from `exp/integration-1114` 8bcee21; head
`c750605e`; one binary holds them all, read by `JoinDevice::new` and passed to the kernels as comptime values; 0 =
the integration build's kernels). Bit 1 (scan-form appends on any plane width) exists for the dumps and lavapipe.

| bit | name | the change | exactness (every input) |
|---|---|---|---|
| 2 | **W**: the walk as a per-lane loop | `while x != 0 { pop; prefilter; append }` per lane instead of `while plane_any(x != 0) { if x != 0 { … } }` (+ bit 4's pop inside it if set) | each lane pops the same bits in the same order and runs the same body on each; only when an idle lane leaves the loop changes (on AMD a divergent loop is one exec-masked loop; CUDA's independent scheduling, the reason for the vote, does not exist there). The stage gets the same pairs; their order in it can differ, which nothing reads (as N21's D/U). No atomic store added (T26B's rule: the append is `ds_append` / `fetch_add`). |
| 4 | P: `find_first_set(x) − 1` pop | as N21's P | x ≠ 0 at the pop (N21) |
| 8 | **B**: b64's low digits as one bit field | `(F >> (32 − 2s)) & (b − 1)` for `(F << s) >> (32 − s)` at b = 2^s | both are bits 32 − 2s … 32 − s − 1 of F; host test `n22_small_division_and_bit_field_are_exact` (s = 1..8, edges + 10^6 random) |
| 16 | **K**: the check's limb arithmetic in 24-bit multiplies | each base-b² limb of n and n² masked with `& 0xFFF` once (an identity: every limb is below b² ≤ 4,096, the top limbs below b² or b because n² < b^s2), so ACO proves the products' factors below 2^24 and emits `v_mad_u32_u24` / `v_mul_u32_u24`; `put2`'s digit split `⌊y/b⌋ = (y·⌈2^20/b⌉) >> 20` | the masks change no value; the division is exhaustively exact for every y < b² at every base 10–64 with the product below 2^32 (same host test); the column sums are the same sums |
| 32 | **A**: fixed-trip AND digit loop | the first 2·(f0 + pp) + 2 pops (12 here; the host computes it) unrolled without the loop test; a pop past the entry's last digit repeats its last digit; the old `while (x \| y) != 0` loop follows for any digits left | OR is idempotent, so a repeated digit leaves the accumulators unchanged and the set ORed is the entry's digits whatever their count (fewer: repeats; more, e.g. a dead mask: the loop after); an empty slot ORs digit 0's words but every use of its pass mask is masked by `vv` (as today) |

**ACO counts per unit of work** (b62 / b64, Mesa 26.0.8, wave64; three dumps each, `raw/aco_repeat.txt`) [M]:

| variant | walk round ALU, no pass | Δ | AND, per entry slot and chunk group (12 pops) | check entry: ALU / quarter-rate / VALU units / ACO inv. throughput |
|---|---|---|---|---|
| base (integration) | 44 / 44 | — | 281 (12 × 23 + 5) | 765 / 240 / 1,510 / 15,342; 714 / 114 / 1,103 / 11,090 |
| W | **40 / 40** (VALU −3…−2, SALU −2) | **−4 / −4** | | |
| P | 42 / — | −2 | | |
| W + P | 40 / 40 | −4 (P adds nothing once W is in: the zero case is gone with the vote) | | |
| B | — / 42 | — / −2 | | |
| **W + B** | — / **38** | — / **−6** | | |
| **K** | | | | **717 / 64 / 932 / 9,445** (−6 % ALU, −38 % issue); **694 / 0 / 741 / 7,496** (−3 %, −33 %) |
| **A** | | | **213** (208 + 5: 17.3 per pop) **−24 %** | |

Occupancy is unchanged by every variant (join 96 VGPRs, 15,360 B, 16 waves; check 48 VGPRs, 32 waves).

**Predicted gain on the card** [E]. Price per walk-round ALU instruction from the card (N21.2, calibrated on the same
loop in the same field shapes): M's −8 took 68.54 → 66.09 s at b62 and 117.7 → 109.0 s at b64, P's further −2 took
→ 65.34 s and → 107.1 s: **0.31–0.37 s per instruction per b62 field, 0.95–1.09 s per b64 field**. Those are
seconds of walk rounds, which no later PR changed in number, so they carry over to the integration fields (b62
58–59 s, b64 93–96 s; §1). For the AND and the check (no card calibration of their own) the count model prices the
saved fraction of a part's instructions at its §1 share; the issue model prices K's saved VALU issue instead (the
check is a pure-ALU kernel at 32 waves per SIMD, and the card's per-check cost is 2× the 3080's, the ratio of their
32-bit multiply rates: plausible but untested).

| candidate | b62 1e17 | b64 1e17 | basis |
|---|---|---|---|
| **W** | ×1.021–1.026 | **×1.040–1.048** (central ×1.045) | 4 instructions × the card's price |
| **W + B** | as W | **×1.060–1.075** | 6 × the price (B is a two-line change to #255's own lines; N21 recommended folding it into #255) |
| K | ×1.004 (count) – ×1.026 (issue) | ×1.003 – **×1.038** | the check's 6.7 % / 11.1 % × −6 % / −3 % of its instructions, or × −38 % / −33 % of its VALU issue |
| A | ×1.016–1.024 | ×1.019–1.029 | the AND's 12 % / 15 % × the digit loop's 24 % × its 70–85 % of the AND [E]; less if the AND is LDS-latency-bound |
| W + B + K + A (all, for scale; four changes) | ×1.04–1.08 | ×1.11–1.16 | products of the rows |

**Not built, with the reason** (instruction counts from the listings, §2): the FD top kernel's append with a 64-lane
ballot on SPIR-V (two of its four DPP sequences, ≈ 24 of ≈ 880 per slot: ≈ ×1.007 at b62); `add_words` /
`sub_words` as 32-bit carry chains (≈ 30 of ≈ 880: ≈ ×1.009); the step's fix-up multiply (13 quarter-rate per slot,
no shorter exact form in instructions); L (one 16-byte record per top, −1 to −2 LDS a round, N21: needs its own
layout change); hoisting `s_bfm_b64` (ACO's rematerialisation; −1 SALU, and at b64 only by reversing the digits'
order, which costs it back). None of the FD top kernel's pieces is above half of a slot, so no single exact rewrite
there reaches the 15 % of the kernel that ×1.04 at b62 would need.


## 4. CUDA, RTX 3080 [M]

__CUDA__

## 5. Exactness [M]

__EXACT__

## 6. Files

__FILES__

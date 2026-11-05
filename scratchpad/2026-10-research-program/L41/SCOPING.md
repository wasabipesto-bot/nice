# L41 SCOPING: the prefilter's arithmetic and the per-wave base, read from SASS (2026-11-05; no GPU, nothing built)

**Sources.** SASS of the post-#241 base (`af21136` = upstream main `6f060a9` + #241): `L40/raw/box/sass/M/join_kernel_b6{0,2,4}_1.sass`
(1080 / 1088 / 1056 instructions; L39's `B` is the same count). Its walk loops match main's (`L37/raw/box/sass/A/join_kernel_0_b62.sass`)
instruction for instruction. #241 changed only the batch load: one record, six LDGs off one base. `L37/raw/box/sass/` was already unpacked;
there is no tgz, and only modes 0/5/7/8 have SASS. Kernel source: `git show af21136:common/src/cubecl_join.rs` (`join_kernel`, `walk_pf`);
CPU derivation: `common/src/cpu_join.rs` (`CpuJoin::prefilter`, `prefilter_digits`, `SmallDiv`). Counts: `raw/classify.py` (per part and
per pipe, b62); per-field budget and candidate arithmetic: `raw/budget.py`.

**Everything below is instruction counts and a documented pipe model, not measurements.** Per-field unit counts come from L37/L40's counters
(plane-rounds 1.284·10^11, plane-chunks 1.97·10^10, plane-groups 5.36·10^9 at b62 1e17). Plane-waves (~3.1·10^9) and plane-batches are
estimated from L39's entry-load count. The 1.3 slots per plane holding entries is an assumption.

## Summary

- **One walk round as compiled (b62, per entry slot): 110 SASS, 74 on the common path, plus the 16-instruction stage in ~39 % of rounds.**
  - Loop control: 4.
  - Lane guard: 4.
  - Pop: 6.
  - Residue test: 5.
  - `nand += 1`: 1.
  - **`walk_pf`: 51.**
  - Tail: 3 (`sync_plane` compiles to a `NOP`).
  - The second slot's loop is an identical copy.
  - b60: `walk_pf` 49. b64: 42, because `% 64` and `/ 64` become masks and shifts.
- **`walk_pf` is ALU-pipe work.** Of its 51 instructions, 36 go to the integer ALU pipe (`LOP3`/`SHF`/`ISETP`/`SEL`), 11 to IMAD, 3 are LDS.
  - On sm_86 the ALU pipe takes one warp instruction per 2 cycles per SMSP (CUDA guide: 64 results/clk/SM for integer add, shift, logic
    and compare). IMAD has its own pipe at the same rate.
  - So `walk_pf` needs ≥ 72 SMSP-cycles of ALU per round against 51 of issue. L37 measured 66 per round.
  - b64's `walk_pf` has 35 ALU ops, the same as b62's 36. Under this model a b64 round costs what a b62 round does.
  - Inside `walk_pf`, the **digit extraction** is 20 instructions (12 ALU): unpacking `ac`/`pc` 4 (loop-invariant, redone every round),
    `D` and the seed flag 2, `mod b²` 6, `/ b` and `% b` 8.
  - The **64-bit one-hot masks and their tests** are 26 (24 ALU): the constant 1, 4 × (`SHF.L.U32` + `SHF.L.U64.HI`), 2 ORs, 2 compares,
    `seen` (2 `SEL`, 2 ORs), 7 mask tests, `PLOP3` + `BRA`.
  - The two multiply-adds the pair actually needs are 2 IMADs.
- **The join's budget per b62 1e17 field** (`raw/budget.py`): ~1.46·10^13 warp instructions, 7.7·10^12 of them on the ALU pipe.
  - That is ~41 s of issue and ~44 s of ALU at 1.3 GHz, against a ~61 s post-#241 join (72.4 s on main, L37, minus L38's 10.9 s, scaled).
    **The join is mostly ALU-pipe-bound.**
  - Walk rounds are 71 % of its instructions and 77 % of its ALU ops; `walk_pf` alone is 45 % / 60 %.
  - The AND is 13 % / 12 %. It is LDS-bound within its phase, which is why its measured time (5 %) is below its share.
  - Per-chunk work is 8 %; per-batch work (top gather + transposed copy) 5 %; the wave loads 2.5 %; work items 0.5 %.
- **What a wave costs** (post-#241; per plane-wave, ~6.35 chunks):
  - ~115 instructions of entry loads and key-level terms.
  - ~260 per batch for the gather and transposed copy (232 of them the copy, 141 ALU).
  - ~60 per chunk of bookkeeping (stage check, 2 barriers, pass words, walk exits).
  - ~750 non-walk, non-AND instructions in all: ~3.5× the AND's useful payload (~215 LDS + OR).
  - The AND as compiled is ~620, 13 of its 21 instructions per digit being digit-extraction overhead. The walk rounds are ~3,300.
  - Recomputed needlessly: the whole wave load per top batch of a work item (~2.3 batches per work item), `pc` per wave (key-independent),
    and the AND's digit positions per group.
- **Ranked candidates** (% of the join's warp instructions / ALU ops at b62 1e17; time = s per field at L37's 150 W scale, two
  estimates):

  | # | candidate | Δ per unit | % join instr | % join ALU | time estimate | exactness |
  |---|---|---|---|---|---|---|
  | **1** | **FX: fixed-point digit extraction** in `walk_pf` (one IMAD per power, then two multiplies by b; no mod/div, no unpacking) | −15 instr, −11 ALU per round | **−13.2 %** | **−18.2 %** | −7 to −8 s (**12–13 % of the join**, ~6 % of the field) | **exact by construction** (proof §3.1); host exhaustive test + parity list |
  | **2** | **MT: membership by 64-bit shift + 6 pairwise compares** instead of building four one-hot masks | −8 / −7 | −7.1 % | −11.6 % | −4 to −5 s (6–8 %) | **exact by construction** (same predicate) |
  | **3** | **GM: seed-gated top masks** in shared (plain δ̂, no per-pair `SEL`s or flag test) | −3 / −3 | −2.6 % | −4.9 % | −1.4 to −2.1 s (2–3.5 %) | **exact by construction**; +2 KiB shared, still 5 cubes/SM |
  | **1–3** | **lean `walk_pf` (FX + MT + GM): 51 → 25 instructions, ALU 36 → 15** | −26 / −21 | **−22.9 %** | **−34.9 %** | **−12 to −15 s (20–25 % of the join, 10–13 % of the field)** | exact by construction |
  | 4 | RC: residue test moved to clipped chunks only (per-chunk clip word), `nand` by popcount | −6 / −3 per round, +2–3 per chunk | −4.3 % | −4.2 % | −2 to −4 s (3–6 %); one LDS round trip off each round's chain | exact by construction; clipped-path parity |
  | 5 | TT: transposed copy as a warp shuffle transpose (5 `SHFL.BFLY` stages per word) | −190 / −110 per thread-batch | −3.5 % | −3.9 % | 0 to −1.7 s (0–3 %; L37 priced the copy at ~0 behind the old gather) | exact by construction; 32-lane planes only |
  | 6 | BG: branch-free lane guard (no `BSSY`/`BSYNC`/guard branch, clamped index) | −4 / 0 | −3.5 % | 0 | 0 to −1.5 s | needs parity (garbage lanes masked) |
  | 7 | WH: wave load hoisted out of the batch loop for single-wave buckets | −57 % of wave loads | −1.3 % | −0.9 % | ≤ 1 % by instructions; the list→entry latency part unmeasured (L39) | exact by construction |
  | 8 | AU: AND digit loop at a fixed 2k = 12 trips | −2 per digit | −1.1 % | −1.1 % | ~0.5 s | relies on \|entry mask\| = 2k; parity |
  | 9 | PC: `pc` = (2ρ, 3ρ²) mod b² in the bucket kernel | −17 per slot-wave | −0.5 % | −0.2 % | ~0.1 s | exact; costs a third ext word |

  - **Only FX alone and the lean bundle clear the brief's bar** (≥ 10 % of the join's instructions, ≈ 5 % of the field).
  - RC rides along cheaply.
  - The rest are below 4 % each.
  - Rejected, with reasons in §3:
    - one-hot masks through a shared lookup table or a select on the word half;
    - popcount distinctness (kept only as MT's fallback);
    - the residue test after `walk_pf`;
    - an early-exit split of `walk_pf`;
    - caching the AND's digits in registers (4 cubes/SM).
- **Recommended first prototype: the lean `walk_pf` as one comptime switch with cumulative levels** (§6):
  - FX, then + MT, then + GM, then + RC.
  - Codegen and exactness come first; then a one-binary screen at b62 1e17 / b60 1e16.
  - **Kill if level 3 (FX + MT + GM) is below ×1.03 at b62 1e17.** That would mean the round is not ALU/issue-bound as modelled.

## 1. One walk round as compiled (b62, entry slot 0, `0x2a90`–`0x3160`; `raw/classify.py`)

Pipes: **ALU** = `LOP3`/`SHF`/`ISETP`/`IADD3`/`SEL`/`PLOP3`/`VOTE`; **FMA** = `IMAD*`; **XU** = `BREV`/`FLO`/`POPC` (16 results/clk/SM);
**MIO** = `LDS`/`STS`/`ATOMS`/`SHFL`/`S2R`; **CBU** = branches, `BSSY`/`BSYNC`, `NOP`.

"Chain" = on the round's dependency chain. In a divergent round the whole warp issues the body whatever the number of live lanes, so every
instruction costs an issue slot. The chain sets the round's latency.

| part | SASS | instr | ALU | FMA | other | chain | notes |
|---|---|---|---|---|---|---|---|
| loop control | `ISETP x≠0`, `IMAD.MOV`, `VOTE.ANY`, `@!P BRA` | 4 | 2 | 1 | CBU 1 | yes | `while plane_any(x != 0)` |
| lane guard | `ISETP` (again), `BSSY`, `IMAD.MOV`, `BRA` | 4 | 1 | 1 | CBU 2 | yes | `if x != 0`; reconverges at `BSYNC` |
| pop | `BREV`+`FLO.U32.SH` (ctz), `IADD3`+`LOP3` (x &= x−1), `IADD3` (jc + ctz), `IMAD.SHL` (×4) | 6 | 3 | 1 | XU 2 | yes | |
| residue test | `LDS t_rhi`, `LDS t_rlo`, `ISETP.GE`, `ISETP.LT.OR`, `BRA` | 5 | 2 | 0 | MIO 2, CBU 1 | **yes**: an LDS round trip before `walk_pf`'s LDS | never rejects in the interior (5 pairs in 1.02·10^12, L37) |
| `nand += 1` | `IADD3` | 1 | 1 | | | no | |
| **`walk_pf`** | `0x2bc0`–`0x2ef0` | **51** | **36** | **11** | MIO 3, CBU 1 | | ↓ |
| · top operands | `LDS t_dm`, `t_lo`, `t_hi` | 3 | | | MIO 3 | `t_dm` yes | |
| · unpack | `ac & 0xFFFF`, `ac >> 16`, `pc & 0xFFFF`, `pc >> 16`, `D = dmv & 0xFFFF`, seed = `dmv & 0xFFFF0000 ≠ 0` | 6 | 6 | | | D yes | the four `ac`/`pc` unpacks are loop-invariant; ptxas re-does them every round (40 registers) |
| · mul-add | `x2 = a2 + p2·D`, `x3 = a3 + p3·D` | 2 | | 2 | | yes | the only arithmetic the pair needs |
| · `x mod b²` | 2 × (`IMAD.WIDE` magic, `SHF >>11`, `IMAD x − q·3844`) | 6 | 2 | 4 | | yes | |
| · `h = x / b`, `g = x % b` | 2 × (`SHF >>1`, `IMAD.WIDE` magic /31, `SHF >>4`, `IMAD x − 62h`) | 8 | 4 | 4 | | yes | b60: no pre-shift (49 total) |
| · one-hot masks | `IMAD.MOV 1`, 4 × (`SHF.L.U32` + `SHF.L.U64.HI`), 2 `LOP3` (at_k) | 11 | 10 | 1 | | yes | the 64-bit shifts are 2 instructions each; no cheaper generic form exists |
| · compares | `g2 == g3`, `h2 == h3` | 2 | 2 | | | no | |
| · seen | 2 `SEL` (seed ? top : 0), 2 `LOP3` (∪ entry) | 4 | 4 | | | no | |
| · mask tests | `seen & at_k`, `(seen ∪ at_k) & at_k1`, lo and hi words, to a predicate | 7 | 7 | | | yes | |
| · combine + branch | `PLOP3`, `BRA` | 2 | 1 | | CBU 1 | yes | |
| stage (taken in ~39 % of rounds) | warp-aggregated `ATOMS` (`S2R`×2, `VOTEU`, `FLO`, `POPC`×2, `ISETP`, `LOP3`, `ATOMS`, `SHFL`, `IADD`, `ISETP`, `BRA`) + `LDS t_id` + 2 `STS` | 16 | 3 | 1 | XU 3, MIO 7, UNI 1, CBU 1 | yes when taken | p = 1 − 0.939^7.95 (7.95 live lanes per round, 6.1 % pass) |
| stage overflow (> 1024 staged; rare) | global `ATOMG` + 2 `STG` | 20 | | | | | |
| tail | `BSYNC`, `NOP` (= `sync_plane`), `BRA` | 3 | | | CBU 3 | yes | |
| **common path (no stage)** | | **74** | **45** | **14** | XU 2, MIO 5, CBU 8 | | **80.3 issued per round with the stage at p = 0.394** |

**Cost per round.** The round issues ~80 warp instructions and needs ~92 SMSP-cycles of ALU. L37's measured marginal costs give
~107 SMSP-cycles per plane-round: walk 31, `walk_pf` 66, stage ~10.

- `walk_pf`'s 66 cycles sit between its issue count (51) and its ALU time (72).
- The walk part's 31 cycles exceed its 23 instructions; its chain holds the residue test's LDS round trip and the `BREV`→`FLO` pair.

**The round's chain** is roughly 200 cycles (no stage):
- VOTE→BRA, then the guard;
- `BREV`→`FLO`→`IADD3`→`IMAD.SHL`;
- LDS (residue)→2 `ISETP`→BRA;
- LDS `t_dm`→unpack→IMAD→3-step mod→3-step div→IMAD→SHF→3 `LOP3`→`PLOP3`→BRA;
- `BSYNC`.

With ~5–7 of an SMSP's 10 resident warps walking at a time, about 2.7 are needed to cover it. **So the round is issue/ALU-bound, not
latency-bound.** The lean body below shortens the chain in proportion (~120–130 cycles for ~45 issued) and stays issue-bound.

**Other bases** (`L40/raw/walkloops.txt` + `raw/classify.py`):

| base | walk loop | before the stage | `walk_pf` instr | `walk_pf` ALU |
|---|---|---|---|---|
| b60 | 108 | 69 | 49 | 34 |
| b62 | 110 | 71 | 51 | 36 |
| b64 | 105–106 | 63–64 | 42 | **35** |

## 2. The join's warp-instruction budget per b62 1e17 field (post-#241; `raw/budget.py`)

| unit | count per field | instr per unit | instr | % | ALU % |
|---|---|---|---|---|---|
| walk round (74 + 16 × 0.394) | 1.284·10^11 (L37/L40) | 80.3 | 1.03·10^13 | **70.8** | **76.7** |
| chunk: head, pass words, two walk exits, stage check (2 `BAR`s, `ATOMS`, `SHFL`), tails | 1.97·10^10 (L40) | 60 | 1.18·10^12 | 8.1 | 3.8 |
| AND group: per slot with entries 18 + 12 digits × 21 (×1.3 slots) | 5.36·10^9 (L40) | 358 | 1.92·10^12 | 13.2 | 12.5 |
| wave: setup 20 + per slot 66–73 (6 `LDG`, ~50 key-level) | ~3.1·10^9 (from L39) | 115 | 3.6·10^11 | 2.5 | 1.6 |
| batch: top gather 32 (7 `LDG`) + transposed copy 232 (141 ALU, 21 LDS) | ~3.0·10^9 | 241 | 7.2·10^11 | 5.0 | 5.2 |
| work item | 1.28·10^9 | 55 | 7·10^10 | 0.5 | 0.2 |
| **total** | | | **1.46·10^13** | | **7.7·10^12 ALU** |

At 1.297 GHz on 68 SMs this is 41.3 s of issue and 43.8 s of ALU-pipe time. The join was 72.4 s on main at 150 W (L37), and is ~61 s
after #241.

- About 70 % of the post-#241 join is ALU-pipe time.
- ptxas agrees with that diagnosis: throughout the kernel it rewrites moves, constant shifts and adds as `IMAD.MOV`/`IMAD.SHL`/`IMAD.IADD`/
  `IMAD.U32`. It does that to balance against a busy ALU pipe.
- **Within the AND phase the limit is LDS, not ALU.** Per digit there are 4 LDS with ~2-way conflicts (L34): 8 wavefronts against the SM's
  1 per clock, i.e. 8 SM-cycles of MIO against 5.5 of ALU. The AND's issue overlaps other warps' ALU-bound walks, which is why L37 measured
  it at 5 % of the join (0–2 % in cycles) despite 13 % of the instructions.

## 3. `walk_pf`: cheaper formulations

Production shape at b57–64: k = 6, k2 = 8, **mid = 2**, f0 = 3, key level. Already constant-folded by the comptime shape:
- e1 = e2 = kb = bk = b2k = 0;
- `v_digits` = 0;
- σ = r0;
- `p2 = 2ρ`.

The prefilter tests the two base-b digits (g = low, h = high) of x2 = (A2 + P2·D) mod b² and x3 = (A3 + P3·D) mod b².
- A, P < b² are the entry's (`ac`, `pc` halves); D < b² is the top's.
- The test: g2, g3, h2, h3 pairwise distinct, and none of them in seen = entry mask ∪ (seed ? top certificate : ∅).

This is `cpu_join::prefilter`. `prefilter_digits` peels the digits with `SmallDiv` and folds `seen` as it goes; the GPU form is the same
predicate.

### 3.1 FX: fixed-point digit extraction (−15 instructions, −11 ALU per round; exact by construction)

Represent x / b² as a 32-bit binary fraction and read the two digits off with two multiplies by b. Choose:
- per top (batch load, once per thread per batch): **δ̂ = ⌈D·2^32 / b²⌉**, computed as D·Q + ⌈D·R / b²⌉ with 2^32 = Q·b² + R comptime
  (~6 instructions, the only division a sum);
- per entry (wave load): **α̂ = A·C**, with C = ⌈2^32 / b²⌉ (one IMAD per power).

Per pair:
```
F  = α̂ + P·δ̂            (IMAD, wraps mod 2^32)
h  = hi32(F·b)           (IMAD.WIDE.U32; lo32 = F')
g  = hi32(F'·b)          (IMAD.HI.U32)      → 3 FMA-pipe instructions per power, 0 ALU
```

**Proof.**
1. Write C·b² = 2^32 + ε1 and δ̂·b² = D·2^32 + ε2, with 0 ≤ ε1, ε2 < b².
2. Write x = A + P·D = q·b² + r.
3. Then (α̂ + P·δ̂)·b² = q·b²·2^32 + r·2^32 + Δ, where Δ = A·ε1 + P·ε2, so 0 ≤ Δ < 2b⁴.
4. Hence α̂ + P·δ̂ = q·2^32 + F0 with F0 = (r·2^32 + Δ) / b², an integer, below 2^32 because r ≤ b² − 1 and Δ < 2^32. So F = F0.
5. F·b² = r·2^32 + Δ, so ⌊F·b² / 2^32⌋ = r whenever Δ < 2^32.
6. The two multiplies split F·b² exactly: F·b = h·2^32 + F′, F′·b = g·2^32 + F″. So ⌊F·b² / 2^32⌋ = h·b + g with g < b.
7. Therefore (h, g) are r's base-b digits.

- The condition is Δ < 2^32. Δ < 2b⁴ ≤ 2^25 at b64: a margin of 128×.
- With the seed flag carried in δ̂'s bit 0 (level 1, before GM), it must keep the error one-sided:
  δ̂′ = ((δ̂ + 1) & ~1) | seed, i.e. δ̂ + 0…2. Then Δ < 4b⁴: still exact to b = 181. The flag is `δ̂′ & 1`.
- α̂ = A·C itself fits a word: A·C ≤ (b² − 1)(2^32/b² + 1) < 2^32 for b ≤ 256.
- b64 is the special case ε = 0 (δ̂ = D << 20), and the same code works there.
- **Exact for every b the join runs, by construction; no parity-sensitive approximation.**
- Host tests that cost nothing:
  - δ̂ = the true ceiling for every D < b², b = 2…64;
  - max Δ < 2^32 per base;
  - a host mirror of old and new `walk_pf` on random tuples per base, checked against `SmallDiv`'s digits.

**Saves per round:**
- the four `ac`/`pc` unpacks (the entry keeps α̂2, α̂3, P2, P3 unpacked: **+4 registers**, 40 → ~44, still ≤ 48 for 5 cubes/SM);
- the `D` unpack;
- 6 `SHF` and 4 IMADs of the mod/div.

Old 22 instructions (12 ALU, 10 FMA) → new 7 (1 ALU for the seed flag, 6 FMA).

**Wave load:** +2 IMAD (α̂) and −4 (the two packs) per slot.

**Fallback:**
- If registers bite, keep P2|P3 packed (+2 registers; 2 ALU unpacks stay; −13/−9 instead).
- Small test shapes with k < mid (bk ≠ 0) or mid ≠ 2 keep today's code under a comptime branch.

Side effects:
- `walk_pf` then has no division at all. The Apple Metal divide-by-constant bug class (`cert_power`'s note) no longer applies there.
- `u32::mul_hi` exists on every CubeCL 0.10 backend: `__umulhi` on CUDA and Metal, `OpUMulExtended` on SPIR-V, emulated on WGSL.

### 3.2 MT: membership tests by 64-bit shift + 6 compares (−8 instructions, −7 ALU; exact by construction)

**Today:** build four one-hot 64-bit masks (8 `SHF` + the constant), OR them in pairs, then run three mask tests per word and two compares.

**Instead:**
- `hit = lo32(seen >> g2) | lo32(seen >> g3) | lo32(seen >> h2) | lo32(seen >> h3)`: one `SHF.R.U64` each, then 2 `LOP3`s, the second
  testing bit 0 into a predicate;
- the six pairwise inequalities as a chained `ISETP.NE.AND` sequence.

Predicate: pass ⟺ the four digits are pairwise distinct and none is in seen. That is today's
`g2≠g3 ∧ h2≠h3 ∧ (seen ∩ at_k = ∅) ∧ ((seen ∪ at_k) ∩ at_k1 = ∅)`, unrolled. Same predicate, so exact by construction.

Count: 2 (seen) + 4 + 2 + 6 + `PLOP3` = 15 ALU, against 22 ALU + 1 FMA today.

**Verify in the prototype's SASS** that `(u32)(u64 >> s)` is one `SHF.R.U64`. The `1u64 << g` pairs in today's SASS show SHF handles 0–63
in its 64-bit forms.

**Alternatives considered:**
- **Lookup table** (`1u64 << g` from a 64-entry shared table). Replaces 8 `SHF` by 4 `LDS.64`: random indices (bank conflicts), +1 LDS round
  trip on the chain, MIO shared with the AND. Rejected.
- **Select on the half** (`lo = g < 32 ? 1 << g : 0`). `ISETP` + `SHF` + 2 `SEL` per mask, worse than the `SHF` pair. Rejected.
- **Popcount distinctness.** popc(seen ∪ {four bits}) = popc(seen) + 4, where popc(seen) = 2k + popc(gated top mask). That uses entry ∩ top
  = ∅ for AND-passing pairs and \|entry mask\| = 2k. Cost: 14 ALU + 2 `POPC`, which is XU, already 2–3 per round. About equal to MT but
  leans on two invariants and the XU; kept as the fallback if the 64-bit shift compiles badly.

### 3.3 GM: seed-gated top masks (−3 instructions, −3 ALU; exact by construction)

The batch load writes `t_glo/t_ghi = seed ? mask : 0` (2 `SEL` + 2 `STS` per thread per batch) and `t_dh` = δ̂ (no flag bits). `walk_pf`
loses the flag test and the 2 `SEL`s.

Shared memory, per cube:
- today ~16.0 KiB (six 1 KiB top arrays, `t_tr` 2 KiB, stage 8 KiB);
- +2 KiB → 18 KiB + 1 KiB reserved = 95 KiB for 5 cubes ≤ 100 KiB: **still 5 cubes/SM**;
- with RC, `t_rlo/t_rhi` can leave shared (the clipped path reads the record from global), back to 16 KiB.

### 3.4 The lean `walk_pf` (FX + MT + GM): 51 → 25 instructions, ALU 36 → 15

```rust
// per pair; ah2, ah3, p2, p3 the entry's (registers), dh = t_dh[jt2], glo/ghi = t_glo/t_ghi[jt2] (3 LDS, as today)
let f2 = ah2 + p2 * dh;                 // wrapping
let f3 = ah3 + p3 * dh;
let h2 = f2.mul_hi(base); let g2 = (f2 * base).mul_hi(base);
let h3 = f3.mul_hi(base); let g3 = (f3 * base).mul_hi(base);
let seen = (u64::cast_from(mhi | ghi) << 32u64) | u64::cast_from(mlo | glo);
let hit = u32::cast_from(seen >> u64::cast_from(g2)) | u32::cast_from(seen >> u64::cast_from(g3))
        | u32::cast_from(seen >> u64::cast_from(h2)) | u32::cast_from(seen >> u64::cast_from(h3));
(hit & 1u32) == 0u32 && g2 != g3 && h2 != h3 && g2 != h2 && g2 != h3 && g3 != h2 && g3 != h3
```

Expected SASS:
- 3 `LDS`;
- 2 IMAD + 2 `IMAD.WIDE` + 2 `IMAD.HI` (FMA);
- 2 + 4 + 2 + 6 + 1 ALU;
- 1 `BRA`.

Per round, the FMA pipe needs ~26 cycles against the ALU's ~44, so ALU stays the binding pipe but only just. The round goes from 74 issued /
45 ALU to 48 / 24 on the common path.

### 3.5 The residue test: fold it, do not reorder it (RC: −6 per round; exact by construction)

The test costs 5 instructions in every round (6.4·10^11 per field) to reject 5 pairs per field (L37). It also puts an LDS round trip in
front of `walk_pf`'s LDS on every round's chain.

**Moving it after `walk_pf`** would run it only in the ~39 % of rounds where a lane passes. But `nand` (the in-range join survivors, an
exact count the tests compare) needs it for every pass bit. Rejected.

**Cheaper-test-first** gains nothing in SIMT unless a whole warp rejects:
- `walk_pf` rejects 93.9 % per lane, so with ~8 live lanes all reject in 60 % of rounds — and that already skips the stage;
- an early exit after the k-level digits (~70 % per lane) fires for a whole warp ~6 % of the time, for less than the branch costs.

**The exact form (RC)**, from the top's record (`top_kernel` writes `[a − pw0, e − pw0 + 1)`, `top_fd_kernel` `[0, w)`):
- A top is clipped iff `rlo ≠ 0 || rhi ≠ w`. These are only the field's edge blocks.
- Clipped tops set their bit in a per-chunk shared word (`s_cw[c].fetch_or`, rare atomics; zeroed before the end-of-batch barrier).
- After forming the chunk's pass words, if `s_cw[jc/32] ≠ 0` (one uniform LDS + branch per chunk), clear the out-of-range bits of the
  clipped tops (rare path).
- `nand += popc(pm & vv)` per slot (`POPC` + `IADD`).

The same pairs reach `walk_pf`, and `nand` is the same count. The rounds lose 2 LDS, 2 `ISETP`, a `BRA` and the `IADD3`.

### 3.6 The rest of the round's bookkeeping

- **Loop control, guard and tail** (11 instructions) are mostly CBU and `IMAD.MOV`.
  - BG drops the guard (`ISETP`, `BSSY`, `IMAD.MOV`, `BRA`) and the `BSYNC`: lanes with x = 0 run the body on a clamped index
    (`jc + (ctz & 31)`), and their result is ANDed with x ≠ 0.
  - That saves −4 issued and 0 ALU per round. It needs a parity run.
- **Pop:** `BREV`+`FLO.SH` could be `FLO` of `x ^ (x & (x−1))` (one XU op fewer, one `LOP3` more). That is the wrong trade on an
  ALU-bound loop.
- `IADD3 jc + ctz` + `IMAD.SHL` could become one IMAD with a pre-scaled jc (−1 ALU); ptxas chose otherwise because jc is uniform. Micro;
  not ranked.
- `sync_plane` is a `NOP`. Keep it: per the kernel's comment, without it ptxas adds `YIELD` and registers.

## 4. The per-wave base after #241: what every thread does besides the entry loads (b62 SASS)

| unit | where | instr | ALU / FMA | what |
|---|---|---|---|---|
| work item | `0x0000`–`0x0360` | 55 | 10 / 22 | `work[]` 4 `LDG`, `seg`/`counts` gathers, `lbase` |
| batch: top gather | `0x0370`–`0x0560` | 32 | 6 / 5 | `tl` + one record (6 `LDG` off one base), D and flag, 6 `STS`; barrier |
| batch: transposed copy | `0x0570`–`0x13e0` | **232** | **141** / 65 | 15 `LDS.128`, 2 `LDS.64`, 1 `LDS`; per bit `SHF.R` + `IMAD.SHL` + `LOP3`; 2 `STS`; barrier |
| wave: setup | `0x13f0`–`0x1520` | 20 | 6 / 5 | defaults for `mlo/mhi/rr/vv/ac/pc` |
| wave: per slot | `0x1530`–`0x1940` (slot 1: 73) | 66 | 25 / 34 | list `LDG` → 5 dependent `LDG`s (14 instr with addresses); key level ~51: q/c3 unpack 6, t2/t3 2, `mod b³` 8, `% b`, `/ b` 8, mask ORs 7, `ac` pack 2, **ρ, p2, p3, `pc` pack 17 (key-independent)**, vv 1 |
| chunk | head, pass words, slot-1 walk entry, stage check, tails | ~60 | ~15 ALU, ~20 uniform | stage check = `S2R`, `VOTEU`, `FLO`, 2 `BAR`, `ATOMS`, `SHFL`, `ISETP`, `BRA` (10) |
| AND group, per slot | setup 18 + 12 × 21 | 270 | 137 / 45 | per digit: 4 `LDS` + 4 OR payload; 13 overhead (`ISETP`, `SEL`×3, `BREV`, `FLO`, `IADD3`, `IMAD`×3, `LOP3`×2, `BRA`) |
| flush (≥ 512 staged) | `0x3900`–`0x3b50` | 38 | | rare |

**Against the useful AND work** (per plane-wave: ~6.35 chunks, ~1.73 groups, ~41 rounds, 1.3 slots with entries; the measured
plane-chunk, plane-group and plane-round counts over the estimated plane-waves):

| part | instructions | share of the wave |
|---|---|---|
| AND payload (4 `LDS` + 4 OR per digit) | ~215 | — |
| AND as compiled | ~620 (2.9× its payload) | 13 % |
| wave load | ~115 | — |
| per-batch gather + copy | ~235 | — |
| per-chunk bookkeeping | ~380 | — |
| work-item share | ~25 | — |
| base total (wave load + batch + chunks + work item) | ~750 (~3.5× the useful AND) | 16 % |
| walk rounds | ~41 × 80 ≈ 3,300 | 71 % |

**Recomputed where it need not be:**
- **Once per work item, not per top batch:** the whole wave load. The work item's key digit and entry list are fixed, and a work item runs
  ~2.3 batches (3.9·10^8 cube-waves / 1.6·10^8 items).
  - Hoisting the load out of the batch loop when the bucket is one wave (≤ 512 entries; the average is ~336) saves ~57 % of wave loads
    (WH): 1.3 % of the join's instructions.
  - It also saves the same share of the dependent list→entry latency that L39 left as the only remaining suspect for the wave's cost. Its
    size is unmeasured.
- **Once per entry, in the bucket kernel:** ρ = r0 mod b², p2 = 2ρ, p3 = 3ρ² (`pc`), 17 instructions per slot-wave and key-independent
  (PC; 0.5 %).
  - Needs a third ext word: `q1` has only 10 spare bits.
  - L39 found extra bytes cost 0.1–1.8 %. Not worth it.
- **Once per wave, not per group:** the AND's digit positions. 13 of the 21 instructions per digit re-extract the same 12 digits every
  group: ~7 % of the join's instructions, but LDS-bound and mostly hidden.
  - Caching the digits needs +3 registers per slot. With FX's +4 that is past 48, i.e. 4 cubes/SM. Rejected.
  - A fixed 2k-trip unroll (AU) removes 2 per digit (1.1 %). It relies on \|entry mask\| = 2k for every listed entry, which holds by the
    bucket kernel's distinct-and-new filter; empty slots OR harmless words, since pass words are masked by `vv`.
- **The transposed copy** (232 per thread per batch, 141 ALU) was free behind the old gather (L37: ~0). After #241 it may not be.
  - A warp-level 32×32 bit transpose of the chunk's lo and hi words (5 `SHFL.BFLY` stages per word, ~40 instructions) works on the values
    each warp just gathered, and saves the barrier between gather and copy (TT; −3.5 % instructions, −3.9 % ALU).
  - It needs 32-lane planes (CUDA, Metal, RDNA wave32); the current loop stays elsewhere.
  - Price it first with L37's mode-9 ablation on the post-#241 base.

## 5. Ranked candidates (b62 1e17; instruction-count and pipe-model estimates, not measurements)

Time estimates use two bounds:
- the L37 marginal cost of the part touched (`walk_pf` 24.18 s, walk 11.29 s per field at 150 W) scaled by the fraction of its instructions
  (low) and of its ALU ops (high) removed;
- the removed ALU ops at 64 lanes/clk/SM, 68 SMs, 1.297 GHz.

The post-#241 join is ~61 s and the field ~118 s at that scale.

| rank | candidate | % join instr | % join ALU | s per field | % of join | exactness | cost / risk |
|---|---|---|---|---|---|---|---|
| 1 | **FX** fixed-point digits | 13.2 | 18.2 | 7.1–8.0 | 12–13 | by construction (§3.1) | +4 registers (or +2, −2 ALU less) |
| 2 | **MT** shift membership + compares | 7.1 | 11.6 | 3.8–5.1 | 6–8 | by construction | check the 64-bit shift's SASS |
| 3 | **GM** gated top masks | 2.6 | 4.9 | 1.4–2.1 | 2–3.5 | by construction | +2 KiB shared (5 cubes/SM kept) |
| **1–3** | **lean `walk_pf`** | **22.9** | **34.9** | **12.3–15.3** | **20–25** | by construction | the above together |
| 4 | **RC** residue test per clipped chunk | 4.3 | 4.2 | 1.8–3.8 | 3–6 | by construction; clipped-path parity | a per-chunk uniform branch |
| 5 | TT shuffle transpose | 3.5 | 3.9 | 0–1.7 | 0–3 | by construction | 32-lane gate + fallback |
| 6 | BG branch-free guard | 3.5 | 0 | 0–1.5 | 0–2.5 | parity | index clamp |
| 7 | WH wave-load hoist | 1.3 | 0.9 | 0.4 + latency | ≤ 1 + ? | by construction | longer register live ranges over the batch loop |
| 8 | AU fixed-trip AND | 1.1 | 1.1 | ~0.5 | ~1 | invariant + parity | |
| 9 | PC in the bucket kernel | 0.5 | 0.2 | ~0.1 | ~0 | by construction | a third ext word |

**Realisation.**
- The ablation priced memory-latency parts at over twice what L38 then realised in cycles.
- These targets are issue/ALU-bound per round (L37 §1: 66 slots of `walk_pf` per round against 51 instructions). L40's walk change
  realised its instruction estimate in cycles (×1.06–1.12).
- So expect ~60–100 % of the bundle's estimate in cycles, i.e. ~6–13 % of the b62 1e17 field.
- Wall time under a power cap can come out higher: fewer ALU ops per round is less energy per round.

**Interactions.**
- **L40's group walk** on a 45-instruction round: its pick (19) and selects (~10) are a larger share. At rounds ×0.65 it nets ~0 on large
  batches and loses on small ones, so don't revive it on the lean body without a re-count.
- **L37's H1 mode 2** (45 registers) plus FX's +4 passes 48 registers, i.e. 4 cubes/SM. Don't combine.

## 6. Prototype plan for a GPU day

**Build** one branch `exp/join-lean-pf` on `af21136` (or on main once #241 lands), host env `NICE_EXP_JOIN_PF` → comptime, cumulative levels:

| level | contents |
|---|---|
| 0 | base |
| 1 | FX: δ̂′ (seed in bit 0, §3.1) in `t_dm`; α̂2, α̂3, P2, P3 unpacked in registers |
| 2 | 1 + MT |
| 3 | 2 + GM: `t_dh`, `t_glo/t_ghi` |
| 4 | 3 + RC: `s_cw` clip words, `nand` by popcount, `t_rlo/t_rhi` out of shared |

Expected SASS at b62, round before the stage (instructions / ALU):

| level | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| instructions | 71 | 56 | 48 | 45 | 39 |
| ALU | 45 | 34 | 27 | 24 | 21 |

1. **Host tests first** (ivory-free, on the box):
   - δ̂ = ⌈D·2^32 / b²⌉ for every D < b², b = 2…64;
   - max Δ < 2^32 per base;
   - a host mirror of old and new `walk_pf` on 10^7–10^8 random (A2, A3, P2, P3, D, masks, seed) per base 57–64, plus every r with the
     worst Δ.
2. **Codegen gate before any timing** (`regs.sh`, L40's `walkloop.py`, this `classify.py` at b60/b62/b64):
   - registers ≤ 48 and no spills, i.e. 5 cubes/SM. Otherwise use level 1′ with P2|P3 packed;
   - each level's round within ~20 % of the table above. If a level saves under half its predicted ALU ops (e.g. the 64-bit shift splits
     into two), fix codegen before timing.
3. **Exactness**, on level 4, plus level 1 for the arithmetic: the usual CUDA list.
   - CPU-reference parity incl. b50/b54 and the b57 frontier/clipped partitions;
   - #240's FD test; #235's certificate test;
   - dense b58/b62; whole b42;
   - 1e14 compare at b57/60/62/64 (counts unchanged);
   - lavapipe naga + direct SPIR-V (WGSL's emulated `mul_hi` and u64 shifts; 8-lane planes);
   - WGSL lint; fmt/clippy.
4. **Screen** (one binary, levels 0–4 interleaved, 2 rounds):
   - fields: b62 1e17 (1 field), b60 1e16 (2), b62 1e16, b64 1e16;
   - record SM clock;
   - run the walk counters (`NICE_EXP_JOIN_ROUNDS` from L40) on level 4. Plane-rounds must equal the base's: this change is per round, not
     per count;
   - model expectation at the 150 W scale: level 3 −12 to −15 s per b62 1e17 field (×1.11–1.15), level 4 another −2 to −4 s.
5. **Kill criteria:**
   - **level 3 below ×1.03 at b62 1e17** (under a quarter of the model): the round is not ALU/issue-bound as modelled. Stop work on the round
     body and record what the model missed;
   - a level that costs a cube per SM or adds spills and cannot be fixed within the day: drop that level;
   - any count difference is a bug, not a trade-off. These are exact by construction.
6. **A/B** if level 3 or 4 screens ≥ ×1.05 at both b62 1e17 and b60 1e16:
   - base vs the best level, 3 interleaved rounds, the 1e14 set, **NiceMark ≥ 6 rounds from the start**;
   - the change cuts every round and adds ~10 instructions per thread-batch, so small batches (MSD-strong, L40's failure) should not lose.
     Check it.
   - Bar as before: ≥ 5 % at b62 1e17 and b60 1e16, no NiceMark scenario below ×0.98.
7. **If time is left:**
   - L37's mode 9 (no transposed copy) on the post-#241 base, to price TT before building it;
   - L37's modes b/p on the winning level, to re-price `walk_pf` on the new body.

**Not on the day:**
- BG, WH, AU, PC: each ≤ 3.5 % of the instructions, below the bar alone. Revisit only if the bundle lands and the profile has moved.

## 7. Caveats

- **The pipe model** (ALU and IMAD each 16 lanes/clk/SMSP, issue 1/clk/SMSP, `POPC`/`FLO` 16/clk/SM) is the CUDA programming guide's
  sm_86 throughput table, not a measurement. The containers have no profiler counters.
  - Supporting evidence: L37's 66 slots per round for 51 `walk_pf` instructions, and ptxas's IMAD-for-ALU substitutions.
  - Treating `IMAD.WIDE`/`IMAD.HI` as half rate does not change the conclusions: the lean body's FMA load stays below its ALU load.
- **Per-field units:** rounds, chunks and groups were measured (L37, L40). Waves and batches are inferred from L39's entry-load count (5
  sampled batches scaled to the field). The AND's 1.3 slots per plane is an assumption (±30 % moves the AND's share between ~10 and 16 %).
- **The critical-path latencies** (~4–5 cycles ALU/IMAD, ~25–30 LDS) are typical published values, used only to check that the round
  stays issue-bound.
- **Nothing was built or run.** The only files written are `L41/SCOPING.md`, `raw/classify.py` and `raw/budget.py`.

# L47 SCOPING: the check kernel after the stack (2026-11-07; reading and arithmetic, no GPU)

Code read: `check_kernel`, `launch_batch` (`common/src/cubecl_join.rs`) and `candidate_check`
(`common/src/cubecl_backend.rs`) on fork `pr/join-static-buckets` **87958fd** (= main + #241 + #246 + #249 +
the stage-once-per-batch rider), copies in `raw/*_87958fd.rs`. SASS: `L44/raw/sass/check_kernel_b6{0,2}_1.sass`
(nvcc sm_86, 38 registers, 0 spills; the check kernel is byte-identical on 87958fd: #246/#249 do not touch it or
`candidate_check`). Tags: **[M]** measured by the lead cited, **[D]** derived by arithmetic, **[E]** estimate/model.

Scripts (`raw/scripts/`, all `python3`, no dependencies): `joinsim.py` generates real join survivors of a field
by the join's own conditions; `sasscost.py` prices SASS paths by address range; `warpsim.py` runs the survivors
through the current kernel and the alternatives warp by warp (→ `raw/warpsim.txt`); `budget47.py` the budget by
category and the calibration (→ `raw/budget47.txt`); `dmodel.py` the proposed kernel's op count (→
`raw/dmodel.txt`); `andonly.py` the price of an unprefiltered survivor (→ `raw/andonly.txt`). Survivor samples
in `raw/surv/` (gzipped JSON lines).

## Summary

- **Budget per survivor (current kernel):** **1,046 warp-instructions per warp-iteration = 32.7 issue slots per
  survivor** at b62 1e17 (1,050 / 32.8 at b60 1e16) [D: SASS × 80,000 simulated survivors per field]. Split:
  long division 27 %, chunk digit extraction + masks + duplicate test 28 %, **per-pass scaffolding 29 %**
  (setup, top-limb trim loop, branch/tail), prologue 8 %, cube multiply 6 %. The division is **12 instructions
  per limb**, not 49 (49 is the 4-limb unrolled loop body; L44 §3c misread it). Warps run all five n² passes in
  97 % of iterations and **build and scan n³ in 70 % (b62) / 75 % (b60) of them** (one lane in 26 passes n² on
  its own), which L44's model left out. Measured 146 ps per check (L45: 9.14 s, 6.258e10 checks, ~1538 MHz) =
  61 SMSP-cycles per survivor = 1,955 per warp-iteration → **0.535 instructions issued per SMSP-cycle** (b60
  0.563): the kernel issues at about half rate.
- **Wave count:** 1024 cubes × 256 threads, 6 cubes/SM (38 regs, 9 KiB shared, and the 1,536-thread limit all
  give 6) → **3080: 408 resident, 2.51 waves run as 3; 4090: 768, 1.33 → 2; 4060: 144, 7.11 → 8**; 3090 2.08 → 3,
  A100 1.58 → 2. Cost on a 3080: **6–16 % of the check** [E] (6 % if 3 cubes/SM still saturate the SM, 16 % if
  throughput needs all 6; 0.535 IPC at full occupancy points to the upper half). The host cannot size the grid
  to a batch (the survivor count exists only on the device; batches launch without a sync), CubeCL reports SMs on
  CUDA only. Fix: a **device-side work counter** (each warp grabs the next chunk of the list), which makes any
  oversubscribed grid exact-tail on every runtime.
- **Per-part estimates** (b62 1e17 / b60 1e16 field shares on the post-#249 + FD-round-2 field, ~80.1 s / ~15.9 s):

  | part | what | check kernel | field [E] |
  |---|---|---|---|
  | (a) | work counter (+ grid headroom) | −6 to −16 % | alone: ×1.007–1.019 / ×1.008–1.023 |
  | (b) | seed with known digits: bottom 16 always; top 17.4 / 15.9 (record change) | B: −30 %; B+C: −57 % (instr.) | B ×1.035; B+C needs the top kernels' record — dominated by (c) |
  | (c) | **base-b² direct check (design D)**: no long division at all | **−65 % instructions** (1,046 → ~327; pipe bound 363) | with (a): **×1.05–1.09, central ×1.07 / ×1.06–1.12, central ×1.085** |
  | (d) | list layout, write-back | write-back free; list + record gather = the **memory floor** (1.8–2.5 TB / field at b62 1e17) | bounds (c): the reworked kernel is co-limited by DRAM |

- **Go / no-go: GO** (predicted 4.5–8.6 % of the field at b62 1e17 and 5.5–10.7 % at b60 1e16, under the cap,
  against the 3 % kill line), with one gate first: the memory floor is unmeasured, and if a gather-only kernel
  takes > 6.3 s per b62 1e17 field the rework cannot save 3 % → stop.
- **Prototype (one day):** step 0 (45 min of box) prices the gather floor and the wave loss with env knobs on the
  current kernel; then a new `check_kernel` (base-b² digits, low-n³ gate, work counter; `candidate_check` and the
  stride path untouched), a codegen gate (≤ 48 registers, 0 spills, no local or shared memory, ≤ 360 issued per
  warp-iteration on the b62 common path), new count-mode device tests that compare every survivor's distinct-digit
  count with the CPU (the existing tests compare empty hit lists everywhere but b10), and the usual A/B (§6).

## 1. What the check does now

**Launch** (`launch_batch`): after the join, `check_kernel` with `CubeCount::Static(CHECK_CUBES = 1024)`, 256
threads, grid-stride over the list; its `ran` counter must reach 1024. Arguments: the list, the join's `checked`
count (read on the device as the list length), `top_rec`, `w_f0 = b^f0`, comptime `base, limbs, chunk_digits,
chunk_div, wide`, and `pre_limbs = 0` (the stride path's low-digit prefilter is off: every list entry already
passed the join's prefilter).

**List** (`surv`): two words per survivor, written by the join's flush: `t` (index of the top's 32-byte record
in `top_rec`) and `r0 = n mod b^f0`. **Per survivor** the kernel loads `t, r0` (coalesced) and the record's
words 0–1 (P; one random 32-byte sector), rebuilds `n = P·b^f0 + r0` (3 limbs at b60/b62) and calls
`candidate_check`:

1. n² in binary (6 limbs; 5 used: n² < 2^146), copied to a shared-memory scratch (`sv_s`: 256 × 9 words per cube).
2. **n² scan**: each pass divides the whole remaining number by `chunk_div = b^5` (`wide` flavour on CUDA: per
   limb a 64-bit by constant division by multiply-high, 12 instructions), trims zero top limbs (a loop over shared
   memory), and extracts the remainder's 5 digits (independent multiply-highs by `b^i` magics), OR-ing `1 << d`
   into a 64-bit mask with a running duplicate word; a duplicate ends the lane's scan after that chunk. Passes at
   b62 1e17 divide 5, 4, 3, 2, 1 limbs; the last is the most-significant chunk (digit loop until zero). n² is
   tested **against itself only**, from digit 0.
3. If n² had no duplicate: n³ = n²·n built in the scratch (7 limbs used), scanned the same way (8 passes: 7, 6, 5, 5,
   4, 3, 2, 1 limbs) against the n² mask.
4. `popcount(mask) == b` → one atomic + 4 stores to `nice_out` (never taken in production: no nice number is known
   above base 10).

**Sizing and load per batch** (6.27e10 / 1.63e10 checks per field from PROFILE-3; L45's fields 6.258e10 /
1.544e10 [M]):

| field | plan | batches | checks / batch | per thread (262,144) | check s / batch (3080, 180 W) |
|---|---|---|---|---|---|
| b62 1e17 | new (L48: 9 slots) | 4,009 | 1.56e7 | 60 | 2.28 ms |
| b62 1e17 | 87958fd (5 slots) | 6,439 | 9.7e6 | 37 | 1.42 ms |
| b60 1e16 | new (8 slots) | 675 | 2.41e7 (L45 field 2.29e7) | 92 | 3.28 ms |
| b60 1e16 | 87958fd (4 slots) | 1,350 | 1.2e7 | 46 | 1.64 ms |

**Waves** (1024 cubes; 6 cubes/SM on sm_80–90: 38 regs → 10,240 per cube, 6 per 64 K; 9 KiB shared; and 1,536
threads on sm_86/89). Loss range = [per-SM granularity, 1 − x/⌈x⌉] (throughput-bound vs latency-bound tail):

| device | SMs | resident cubes | waves needed | run | tail loss [E] |
|---|---|---|---|---|---|
| RTX 3080 | 68 | 408 | 2.51 | 3 | 6–16 % |
| RTX 3090 | 82 | 492 | 2.08 | 3 | 4–31 % |
| RTX 4060 | 24 | 144 | 7.11 | 8 | 1–11 % |
| RTX 4070 / 4080 | 46 / 76 | 276 / 456 | 3.71 / 2.25 | 4 / 3 | 3–7 % / 4–25 % |
| RTX 4090 | 128 | 768 | 1.33 | 2 | 0–33 % |
| A100 / H100 SXM | 108 / 132 | 648 / 792 | 1.58 / 1.29 | 2 / 2 | 5–21 % / 3–35 % |

The same grid at a register count above 40 (5 cubes/SM, 340 resident on a 3080) is **3.01 waves → 4**: any
rework that adds registers makes the fixed grid worse, so (a) is not optional with (c).

## 2. The instruction budget per survivor

**Survivors are simulated, not assumed random.** `joinsim.py` ports `Base::cert` (cap k = 6, the closure) and the
join's conditions (t = L − 3, k = 6, p = 2, f0 = 3, k2 = 8): a survivor is n = P·b³ + r0 with P a full top
block whose certificate M passes, the 16 output digits at positions 0–7 of n² and n³ distinct and disjoint from M,
and n mod (b − 1) a root. P is sampled uniformly over the field (L30's starts, the L45/L46 timed fields), every
r0 of a kept top is enumerated by a digit DFS. **Validation [D vs M]:** kept tops 3.85e10 vs 3.816e10 measured
(b62 1e17), 6.95e9 vs 6.89e9 (b60 1e16); survivors per kept top **1.643 vs 1.640**, 2.215 vs 2.240. 80,000
survivors per field, grouped in 2,500 warps of 32 (list order carries no digit pattern).

**SASS walk** (`sasscost.py`, b62; b60 is the same code, 704 vs 712 instructions):

| piece | instructions | of which FMA (IMAD, IMAD.WIDE) / ALU / LDS+STS / branch |
|---|---|---|
| prologue: 2 + 2 LDG, n, n² (59), top limb | 86 | 38 / 27 / 6 / 8 |
| one limb of the long division (4-limb unrolled body = 49) | 12 | 7 (4 wide) / 3 / 2 / — |
| interior chunk: 5 digits, masks, duplicate word | 45 | 11 / 33 / 0 / 1 |
| most-significant chunk | 8 + 13 per digit | |
| pass scaffolding: head 15, `top >= 4` preamble 7, trim loop 7 per zero limb + 4, branch 3, tail 11 | ~45–50 | mostly ALU and branch |
| n² pass at 5 / 4 / 3 / 2 / 1 (MS) limbs | 161 / 147 / 129 / 118 / 129 | |
| n³ multiply + setup | 95 | 39 / 39 / 9 / 6 |

**Per warp-iteration** (`budget47.txt`), b62 1e17 (b60 within 1 %):

| category | instr / warp-it | per survivor | share |
|---|---|---|---|
| prologue | 86 | 2.69 | 8.2 % |
| n² long division | 190 | 5.95 | 18.2 % |
| n² chunk digits + masks + dup | 243 | 7.59 | 23.2 % |
| n² pass scaffolding | 246 | 7.70 | 23.6 % |
| n³ multiply + setup (70 % of warps) | 67 | 2.08 | 6.4 % |
| n³ long division / digits / scaffolding | 90 / 49 / 54 | 6.04 | 18.5 % |
| exit + epilogue | 20 | 0.62 | 1.9 % |
| **total** | **1,046** (FMA 349, ALU 469, MIO 68, branch 150) | **32.7** | |

- **Lanes die late and warps die later.** n² against itself can first fail at digits 8–9 (pass 2): lanes die in
  pass 2 / 3 / 4 / 5 at 25 / 49 / 16 / 6 %, and 3.8 % pass n² (b60 4.3 %). With 32 lanes, a warp runs all five
  passes in 97 % of iterations and the cube in 70 % (b60 75 %).
- **Calibration:** issue bound 1,046 cycles (2×ALU 937, 2×FMA 697; 988 if IMAD.WIDE takes two FMA slots) against
  **1,955 measured** → 0.535 IPC (b60: 1,050 vs 1,863 → 0.563). The kernel is neither pipe- nor DRAM-bound at that
  rate (its gather is 0.20–0.27 TB/s); the loss is dependency latency in the serial limb chains, the scratch round
  trips and branchy scaffolding — and the wave tail (§1), which this factor includes.
- **Against the older figures:** PROFILE-3's 86.5 ps per check was the slope of a fit with a 1.92 ms per-batch
  intercept (collinear with the check count, L44 §1.6); the total, 146 ps (L45), is what the kernel costs. The
  "300 ps per unprefiltered check" is not supported: AND-only survivors cost **936** per warp-iteration (29.3 per
  survivor, cube in 49 % of warps; `andonly.txt`), *less* than prefiltered ones, because the prefilter's
  survivors are likelier to pass n² and drag their warp into the cube. Since #246 every list entry is prefiltered
  anyway.

## 3. The rework, part by part

### (a) Grid and work distribution

- **What is known where:** the plan (`JoinPlan`) knows slots, `list_cap`, `nice_cap`, bytes; `JoinLimits` the
  largest binding and budget; nothing about SMs. CubeCL 0.10's `HardwareProperties::num_streaming_multiprocessors`
  is `Some` on CUDA, `None` on HIP and wgpu; threads per SM and the kernel's register count are not reported. The
  batch's survivor count is on the device only (the check reads the join's `checked` itself; `launch_batch` returns
  before anything runs), so no host-side grid can fit a batch. (`CubeCount::Dynamic` could, but then `ran`'s
  expected cube count is device-determined.)
- **Design:** keep a fixed, oversubscribed grid (raise `CHECK_CUBES` to 2048 for headroom on 132+ SM parts) and
  hand out the list through **one device counter per batch**: a warp takes the next chunk of 32·K entries with one
  plane-aggregated atomic (K = 4: one atomic per ~128 survivors, ~1.2e5 per b62 1e17 batch). Cubes that start
  after the list is exhausted exit at once, so the tail is one chunk per warp on any device, any occupancy, any
  runtime; `ran`/`expect` are unchanged (every launched cube still counts itself). The counter word rides in the
  per-batch `ran` buffer (a fifth word that `ensure_ran` ignores), so no extra create per batch. CUDA-only
  alternative: `CHECK_CUBES = SMs × 6` (one wave) + static stride, which leaves a per-warp variance tail (~5 %).
- **Estimate [E]:** removes the 3080's tail, **6–16 % of the check**: 0.55–1.46 s at b62 1e17, 0.13–0.35 s at
  b60 1e16 → alone ×1.007–1.019 / ×1.008–1.023 on the ~80 / ~16 s fields. With (c) it is required (the reworked
  kernel may sit at 5 cubes/SM, where 1024 cubes run 4 waves on a 3080).

### (b) Seeding with what is already known

- **What is known at the check:** the bottom's 16 digits (positions 0–7 of n² and n³: the AND's 12 and the
  prefilter's 4) are distinct and disjoint from the top's mask; the top's certificate covers positions ≥ c2' of n²
  and ≥ c3' of n³. Simulated (`warpsim.txt`): **c2' = 16 (87 %), 17 (12.5 %), 18 (0.5 %); c3' = 28 (58 %), 29
  (40 %), 30 (1.5 %); 17.4 certified digits on average at b62 1e17** (b60: c2' 16 in 96 %, c3' 28 in 97 %, 15.9
  digits). So the unknown middle is **28.6 digits at b62 1e17** (n² positions 8–~16: 8.1, n³ 8–~28: 20.4) and 28.1
  at b60 — of 62 / 60 that the kernel converts now (25 always, n³'s 37 in 70 % of warps).
- **The top part needs a record change.** The record's mask M is the certificate *after* closure: it can include
  a forced digit f that belongs to a run position below c' (the d → d + 1 position), which a scan of the middle
  must still convert. Seeding the scan with M rejects a candidate whose digit there is f — exactly the
  potentially nice ones (unsound); counting with M accepts some that are not. Exact use needs c2', c3' and the
  forced bits per top: 1 + 5 + 6 + 2 × 7 = 26 bits, which fit word 7 (now the seed flag 0/1), written by
  `top_fd_kernel` and `top_kernel` (their `qend + 1` and `close_cert`'s `f0/f1`), and the join's two reads of
  word 7 (`seed != 0`, `seed << 16`) mask bit 0. That touches the FD kernel (25 % of the field, 110 registers).
- **Estimates [E, warpsim + model]:** **B** (the roadmap's (ii): n² scanned from digit 8 of ⌊n²/b⁸⌋ after an
  exact division, mask seeded with the 16 low digits, which the check must rebuild from n mod b⁸, ~137
  instructions): lanes then die in the first middle chunk in 82 %, warps run 2–4 passes and the cube in 20 %;
  **727** per warp-iteration (−30 %) → ×1.035 at b62 1e17. **B+C** (also seeding the certified digits, stopping
  below them; needs the record change): lanes die in the first chunk in 98.6 %, cube in 1.7 % of warps; **~455**
  (−57 %) → ×1.06–1.07. Both are dominated by (c), which needs no record change and no seeding: in (c) the low
  digits come out of the same carry pass as the rest at ~6.5 instructions per digit, and the top's certificate
  would only sharpen the n³ gate (cube in 4.6 % → ~1 % of warps, ≈ 10 instructions per warp-iteration, ~0.2 % of
  the field). **The top-certificate part: no-go.**

### (c) The arithmetic: a base-b² check with no long division (design D)

The cost is not the division instruction; it is the shape — a long binary number divided again and again (O(limbs²)),
a scratch round trip per limb, a trim loop and a branch frame per 5 digits, and a cube built in 70 % of warps
because n² is not tested against n³'s known digits. The brief's form (exact division by b⁸, then FX-style fixed
point per chunk) is design B's arithmetic: it removes the low passes but keeps the scan. "Eight digits from one
32-bit remainder" is not available: b⁸ > 2³² at every join base (5 digits fit at b62, `chunk_div = 62⁵`).

**D, per survivor (comptime per base and shape, as the join kernel already is):**
1. Load `t, r0` (one 64-bit load) and record words 0, 1, 6 — P and **word 6 = P mod b^(k2−f0)** (both top kernels
   write `tl_mod·pdiv + v`; the host's `tlay` word 4 is P0 mod b^(k2−f0−p)): the same sector as today. Prefetch the
   next survivor's two loads before computing this one.
2. H = ⌊n / b^k2⌋ = (P − word6) / b^(k2−f0) **exactly**: a 64-bit subtract, a shift by the power of two in
   b^(k2−f0), one multiply by the odd part's inverse mod 2³² (H < b⁵ ≤ 2³⁰ at L ≤ 13). 4 instructions.
3. n's base-b² limbs (7 at b62, 6 at b60) from r0, word 6 and H: 5 magic-constant divisions by b or b² of values
   < 2³⁰. ~20 instructions.
4. **n² by schoolbook in base b²**: 28 products (21 at b60) of limbs < b² ≤ 4096; every column sum is < 7·4095² +
   carry < 2²⁸, so all of it is u32 IMADs. **Normalise** the 13 limbs: q = mul_hi(x, ⌈2⁴⁰/b²⌉) >> 8 (exact for every
   x < 2²⁸ since x·(M·b² − 2⁴⁰) < 2²⁸·2¹² = 2⁴⁰), remainder by one IMAD. **Split** each limb into its two digits
   (y·⌈2¹⁸/b⌉ >> 18, exact for y < 2¹²). **Mask**: `1 << d` as two 32-bit shifts, OR-accumulated (3-input LOP3).
5. **Gate:** the low g = 10 digits of n³ from the truncated product (n² mod b¹⁰)·(n mod b¹⁰) (15 products, 5
   limbs); a lane goes on only if popcount(mask) = s2 + 10 (all of n² and n³'s low 10 digits distinct).
6. **Rest of n³** (76 more products, 14 limbs, 27 digits) only if a lane of the warp passed; nice iff popcount = b
   (s2 + s3 = b; the top limbs' digit counts are comptime, so no leading zero is ever counted).
Power-of-two bases (b64) turn every magic into a shift. No `/` or `%` on a shifted value anywhere (Apple's M4 bug
class), no u64 division: one flavour for CUDA, HIP and wgpu instead of today's wide/split16 pair.

**Gate probabilities (warpsim, 80,000 survivors each):**

| gate | b62: lanes past | warps past | b60: lanes | warps |
|---|---|---|---|---|
| n² + n³ low 8 | 0.68 % | 19.9 % | 0.71 % | 20.1 % |
| **n² + n³ low 10** | **0.15 %** | **4.6 %** | 0.15 % | 4.7 % |
| n² + n³ low 12 | 0.025 % | 0.8 % | 0.019 % | 0.6 % |
| n² + n³ low 8 + certified n³ (record change) | 0.054 % | 1.7 % | 0.088 % | 2.8 % |

**Op count [E] (`dmodel.txt`, g = 10):** b62 common path 315 (ALU 176, FMA 127), rest of n³ 256 × 4.6 % →
**327 issued per warp-iteration = 10.2 per survivor; pipe bound 2×ALU = 363 cycles = 0.348 of today's 1,046**
(g = 8: 386; g = 12: 372). b60: 308 issued, bound 349 = 0.333. The masks are the largest single item (75 ALU at
b62); moving a third of the ORs onto IMAD adds (exact: a popcount of the sum equals the term count iff no carry,
i.e. iff the digits are distinct) balances the pipes at ~340. Registers [E] 40–48 (n²'s 13 limbs and n's 7 stay
live for the cube), no shared memory, no local arrays (every index comptime), ~600 instructions of code.

**Time [E]:**
- Compute: today's 0.535 IPC applied to D's bound → 678 cycles per warp-iteration → **3.2 s** per b62 1e17 field;
  at 0.75 (branch-light, no scratch) → 2.3 s. b60: 0.74 / 0.55 s.
- **Memory floor (d):** per survivor the list's 8 bytes plus the record's 32-byte sector. Survivors of one (top,
  root) pair sit in one join work item's stage, hence adjacent in the list: 1.49 survivors per (top, root) at b62,
  1.67 at b60 (simulated), so 0.60–0.67 sectors per survivor if those repeats hit L1/L2, 1.0 if not. **1.84–2.50
  TB per b62 1e17 field** (0.42–0.62 TB at b60) at a sustained 0.60–0.68 TB/s (79–89 % of the 3080's 760 GB/s) =
  **2.7–4.2 s** (0.62–1.03 s). Today's kernel moves the same bytes at 0.20–0.27 TB/s, so the rework turns the check
  from issue- into DRAM-co-limited.
- **D ≈ max(compute, memory) = 2.7–4.2 s, central 3.4 s at b62 1e17 (from 9.14); 0.62–1.03 s, central 0.81 at
  b60 1e16 (from 2.22).**

### (d) The list layout and the write-back

- The write-back is one atomic and four stores on a hit (never); the count read is one warp-aggregated atomic per
  thread; `cube_done` one barrier per cube. **Nothing to gain.**
- The bytes are the list (8 B, coalesced) and the record sector (32 B, random within a work item's segments). The
  only way below the floor is to stop gathering P: carrying it in the list needs a third word per staged survivor
  and P per top in the join's shared memory (+5–6 KiB → the join drops from 5 to 4 cubes/SM): **no-go** (L44 §3f).
  Kept: one 64-bit list load and a one-ahead prefetch, both free.

### Estimates, together [E]

| | b62 1e17 | b60 1e16 |
|---|---|---|
| check now (L45, 180 W) [M] | 9.14 s | 2.217 s |
| D | 2.7–4.2 s (3.4) | 0.62–1.03 s (0.81) |
| (a) on D (6–16 % of D) | 0.16–0.67 s (0.34) | 0.04–0.16 s (0.08) |
| saved: 9.14 − D·(1 − tail) | 5.2–6.9 s (6.1) | 1.25–1.70 s (1.49) |
| under the cap (84 % kept, #246's issue-trim rule, L44 §1.5; 70–100 %) | 3.6–6.9 s (5.1) | 0.88–1.70 s (1.25) |
| **field: post-#249 + FD round 2 (~80.1 s / ~15.9 s)** | **×1.05–1.09 (×1.068)** | **×1.06–1.12 (×1.085)** |
| field: 87958fd as is (86.68 / 17.05 s, L46.1) | ×1.04–1.09 (×1.063) | ×1.05–1.11 (×1.079) |
| share of the field afterwards | ~4 % | ~5 % |

The roadmap's ×1.045–1.06 / ×1.05–1.07 rested on −44 to −59 % of the check at a 9.5–11.4 % share; D is −63 % of
the check's seconds (central; −66 % with (a)) at an 11.4–13.9 % share, but capped by the memory floor, not by its instructions.

## 4. Exactness

- **By construction:** D computes the unique base-b digits of n² and n³ by a different route: n's base-b² limbs
  from the identity n = H·b^k2 + word6·b^f0 + r0 (H by exact division), integer schoolbook columns that never
  overflow u32 (bound above, a `const` assertion per base), carry normalisation with magic quotients proven exact on
  their whole input range (x·(M·d − 2^k) < 2^k as `const` assertions per base, plus a host test over every x),
  and a digit split proven the same way. The decision is unchanged (popcount of the digit mask = b over exactly s2
  + s3 positions). The gate is a necessary condition (a repeat among any subset of positions rules n out), so it
  only drops non-nice n. Nothing from the join is trusted beyond P and word 6, which the join's prefilter already
  depends on (its D digits).
- **What tests the result today:** only hit lists, and they are empty almost everywhere. `check_all` asserts
  `[69]` on b10 [47, 100) (the one real nice number; a brute force here finds none in the b20/b25/b30 windows, and
  none is known above base 10); every other window, the b57 frontier partitions, tight layouts, slices, refused
  layouts, the production shape, `NICE_TEST_JOIN_FULL_FIELD` (b42 1e13: join = reference = stride), the 1e14
  `NICE_TEST_JOIN_COMPARE` and the dense fields compare **empty** hit lists. The survivor and `checked` counts are
  the join's (the check only reads `checked`). So an over-rejecting check passes every test except b10 — the
  v3.2.14 bug class `candidate_check`'s comment warns about.
- **Tests the rework adds:** (1) **count mode** (comptime, like `probe`): the kernel writes every list entry's
  distinct-digit count (gate bypassed); compare with the CPU's count for every n, on real lists from
  `check_window` at b50/b54/b57/b58/b60/b64 and the production-shape b57 partitions, plus a synthetic list of
  adversarial n (digits 0 and b − 1 at limb boundaries, field ends, the largest n per base, n² distinct with an
  n³ repeat at each position class); (2) **gate mode**: the lanes passing the gate = the CPU predicate; (3) host
  tests of the arithmetic (a CPU mirror of the limb code against u128/U256 digits, 10⁸ random n per base 40–64;
  exhaustive magic checks, like #246's `fx_digits_are_exact_everywhere`); (4) b10's 69 through the new kernel; (5)
  every existing test, with `candidate_check` untouched so the stride path stays an independent reference in
  FULL_FIELD and COMPARE; exact counts on every timed field (b62 1e17 1,020,844,021,499 / 62,584,252,554).

## 5. Go / no-go

**GO.** Every reading of the estimate clears the 3 % kill line (low end 4.5 % at b62 1e17, 5.5 % at b60 1e16);
the central reading clears the A/B's ×1.05 at both fields. The risk is one number nobody has measured: how fast the
3080 serves the check's sector gather. Step 0 measures it before any build. With D's compute at 2.3–3.2 s, the
saving is about 0.84 × (9.14 − max(floor, ~2.7 s)) at b62 1e17: **floor > 6.3 s → stop** (< 2.4 s, 3 %);
**floor ≤ 4.5 s → build** (≥ 3.9 s, ×1.05 on the ~80 s field); in between the build clears 3 % but likely not
×1.05 at b62 1e17 (b60's check share is larger): decide on b60's floor. Not pursued: the top-certificate seeding
(needs the FD kernel's record, ~0.2 %), design B (dominated), carrying P in the list (join occupancy).

## 6. Prototype plan (one day)

**Base:** `pr/join-static-buckets` (87958fd) or main once #249 is in; independent of L48's FD PR (the check reads
only P and word 6, which both keep). Touches `check_kernel` (a new body), `launch_batch` (counter word, cube
count), the test module; not `candidate_check`, the plan, the list or the record.

0. **Box, 45 min (~$0.15), before building D:** an `exp/` branch with two env knobs on the *current* kernel —
   `NICE_EXP_CHECK=gather` (the loads only, folded into a never-true compare: L37's device) and `CHECK_CUBES`
   408 / 1024 / 2048 — profiled b62 1e17 and b60 1e16, 2 rounds. Gives the memory floor (gate above) and which end
   of 6–16 % the wave tail is (408 cubes vs 1024).
1. **Ivory, CPU, ~2 h:** the CPU mirror of D's arithmetic (same limb layout and magics) against u128/U256 digits;
   the `const` assertions; exhaustive magic tests.
2. **~3 h:** the kernel (comptime base, s2, s3, f0, k2, g; `probe`, count and gate modes) and the work counter.
   **Codegen gate** (NVRTC → driver JIT, L45's `ptxjit.py` route, b60/b62/b64): ≤ 48 registers, 0 spills, no
   LDL/STL, no shared memory; common path ≤ 360 issued per warp-iteration at b62 (model 315); lavapipe naga + SPIR-V
   compile at b58–b64. If registers exceed 48, compare 4 vs 5 cubes/SM in the screen before anything else.
3. **Box:** count-mode and gate-mode device tests; `check_all` (b10 → [69], windows, b57 frontier, tight
   layouts, slices, refused, production shape); `NICE_TEST_JOIN_FULL_FIELD`; 1e14 COMPARE b57/60/62/64; dense
   fields; exact counts on every timed field.
4. **Box, ~2 h (~$0.5), 180 W 3080:** screen g ∈ {8, 10, 12} and K ∈ {1, 4} on b62 1e16 (1 round); then the A/B
   against the base binary, 3 interleaved rounds: **b62 1e17, b60 1e16, b62 1e16, b64 1e16, 1e14 at b57/60/62/64,
   NiceMark 6 rounds**; profiled check seconds beside the unprofiled field; SM clock per run.

**Kill:** step 0's floor > 6.3 s at b62 1e17; A/B < ×1.05 at both b62 1e17 and b60 1e16 → keep (a) alone as a
rider if it shows ≥ 1 %; any NiceMark scenario < ×0.98; exactness failing twice. If the A/B shows the kernel at
its DRAM floor, the next lever is the gather, not the arithmetic.

## Files

- `SCOPING.md`: this file.
- `raw/scripts/joinsim.py` (survivor generator, certificate port), `sasscost.py` (SASS path costs), `warpsim.py`
  (warp model of CUR, B, B+C and D's gates), `budget47.py` (budget and calibration), `dmodel.py` (D's op count),
  `andonly.py` (unprefiltered survivors).
- `raw/warpsim.txt`, `raw/budget47.txt`, `raw/dmodel.txt`, `raw/andonly.txt`: their outputs.
- `raw/surv/*.jsonl.gz`: 80,000 simulated survivors per field (b62 1e17 at 7997740455941656911841, b60 1e16 at
  1366406074057412100454; seeds 1, 2), with P, M, c2', c3' and the forced bits.
- `raw/check_b6{0,2}_compact.sass`: the check kernel's SASS without encodings; `raw/*_87958fd.rs`: the source read.

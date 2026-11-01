# L31 SCOPING: a second pass on the overlap join's GPU top kernel (2026-11-01)

Branch `exp/top-cert-2` on the fork (no PR): PR #235's head `6e7475e`, the profile timers (`fc9c47e`, a cherry-pick of `rp/gpu-profile-3`'s `2ab1694`), then `6b83790` (breakdown stages, candidates (a) and (b)) and `3eb8e5e` (candidate (c)). All behind env switches; unset, the kernel is #235's. Raw logs: `raw/box/` (the box's `/root/logs`); scripts `raw/*.sh`; analysis `raw/scripts/bd.py` and `raw/scripts/ab.py`.

**Summary**
- **Verdict: go, by a thin margin, for all three changes together.** (a) + (b) + (c) clears the 5 % bar at b62: **×1.056 and ×1.055 at 1e16** (two sets of 3 rounds) and **×1.053 at 1e17** (3 rounds; per round ×1.038–1.075), and ×1.047 at b60 1e16. All of it is bit-identical. The two candidates the task named do not clear the bar alone: (a) gives ×1.02 and (b) ×1.01 (×0.995 at b60). Most of the gain is (c), a third change the breakdown turned up. (a) + (c) without (b) gave ×1.062 at b62 1e16 but only ×1.021 at 1e17, so (b) is worth somewhere between 0 and 3 % on top. Section 8 lists what a PR needs, starting with an M4 run for (b).
- **Breakdown of the top kernel at b62 1e16** (subtractive stages, profiled, 2 rounds within 0.1 %; b60 in brackets):
  - a, e and the clip, with the launch: 5.5 % (5.9 %)
  - a^j and e^j, `powers16`: 9.6 % (9.5 %)
  - d = e^j − a^j and **the binary search for ndig(d): 13.9 % (15.9 %)**
  - **long division of a^j by b^2 in 16-bit limbs: 32.9 % (32.8 %)**
  - digit extraction, the run/dup selects, x mod b^c0: 21.6 % (18.6 %)
  - carry test: 3.5 % (7.1 %)
  - closure: 4.7 % (1.5 %)
  - bookkeeping inside the kernel (the writes and bucket atomics of the 32 % that certify): 8.3 % (8.7 %)
  - `top_scan` + `top_fill` add 16 % of the kernel's time again (1.17 s against 7.44 s).
  - The top phase is 36 % of profiled device time at b62 (29 % at b60); the kernel alone 31 % (24 %).
- **Candidate (a), e^j − a^j from δ = e − a:** bit-identical. Top kernel ×0.934 (b62) and ×0.982 (b60); whole field **×1.020 (b62), ×1.016 (b60)**.
- **Candidate (b), division-free digit step** (Möller–Granlund 2/1 division by b^5 in u32 words, digits by multiply-high): bit-identical, no division by a constant in the new code. Top kernel ×0.962 / ×1.016; whole field **×1.011 (b62), ×0.995 (b60)**. It cuts the static SASS by 200 instructions but costs 5–6 registers, and probably lengthens each step's dependency chain. On CUDA the compiler's own constant division was already a multiply.
- **Candidate (c), found by the breakdown: ndig(d) from d's bit length and one compare**, instead of the binary search over the power table. Bit-identical. Top kernel **×0.86** at b62; whole field **×1.042 (b62), ×1.039 (b60)**.
- **Combined** (whole field, medians): (a)+(c) ×1.062 (b62 1e16), ×1.021 (b62 1e17; rounds ×1.062, 1.020, 1.019), ×1.031 (b60). All three ×1.056 / ×1.055 (b62 1e16), **×1.053 (b62 1e17)**, ×1.047 (b60). (a)+(b) ×1.026 (b62), ×1.020 (b60). The run-to-run spread is 1–4 %, so single-variant differences under about 2 % are not resolved.
- **Exactness:** each switch and the combinations pass PR #235's certificate test on CUDA with #235's counts (102,365 intervals, 33,582 kept, 203,413 scanned above c0, 69,824 with the carry); the test now also checks (a)'s d, a² and a³ word for word against the full powers. Lavapipe: the test passes with all three on naga and on the direct SPIR-V compiler, and with (a)+(c) on naga. Join parity passes on CUDA with (a)+(b), (a)+(c) and all three, and on lavapipe's direct SPIR-V compiler with all three.
- **SPIR-V blocks and the WGSL lint:** TopKernel at b57 has 478 SPIR-V blocks on #235, 366 with (a)+(c) or (c) alone, 370 with (b), 258 with all three: every candidate shrinks it. CI's WGSL lint flags 0 sites with all three and with (a)+(c).

## 0. Setup

- **Box:** Vast 58613135 (`nice-research-topcert2`) on machine m139250, which also hosted `nice-research-l30-pr` (another RTX 3080 box) throughout, so the host CPU was shared.
  - RTX 3080 **10 GB**, driver 580.159.03, CUDA 12.8 toolkit, PCIe gen 3 x8.
  - **Power capped by the host at 180 W** (default and max 320 W; `raw/box/power.txt`, `raw/box-info.txt`). Under the A/B it sat at the cap: median 1,440–1,500 MHz, 179–180 W (`raw/box/ab/*.smi`). Absolute seconds are a 180 W 3080's; the A/B is one binary on one box.
  - Host Xeon E5-2630 v4, cgroup quota 9.6 CPUs, 62 GB.
- **Binaries** (`raw/build.sh`; `cargo test --release -p nice_common --features gpu --no-run`):
  - `exp` = `6b83790`, test binary `cd647507`: CUDA exactness of (a) and (b), the breakdown, and the profiles of (a), (b) and (a)+(b).
  - `exp2` = `3eb8e5e`, test binary `d8b63569`: the A/B, the new-variant profiles, the exactness of (c).
  - The sources on the box were checked against the commits (md5 of `cubecl_join.rs`).
- **Switches:** `NICE_EXP_TOP_STAGE=1..7` (the breakdown), `NICE_EXP_TOP_DIFF=1` (a), `NICE_EXP_TOP_BARRETT=1` (b), `NICE_EXP_TOP_NDIG=1` (c). They are comptime parameters of the kernels, read at launch, so each setting compiles its own kernel and unset compiles #235's.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L29's starts (b60 1366406074057412100454, b62 7997740455941656911841), one 1e14 warm-up field per process. "s/field" is the harness's `per_field` (wall per field, two fields in flight). The profile is `NICE_EXP_GPU_PROFILE=1` with one extra sync between `top_kernel` and `top_scan`, so `topk=` is the kernel alone.
- **Order** (box clock, UTC): builds 04:00–04:12; smoke test 04:13–04:21; CUDA exactness 04:22–04:30 (lavapipe builds beside it); breakdown 04:30–04:41; exp2 build 04:41–04:44; A/B 04:44–05:48 with nothing else on the box (b62 1e16, b60 1e16, the new variants' profile, b62 1e16 base/dn/all, dn's profile, b62 1e17 × 2, b60 1e16 base/dn); then CUDA exactness of (c), SASS counts and lavapipe builds side by side; lavapipe checks; a third 1e17 round last, alone.

## 1. Breakdown (`raw/bd.sh`, `raw/bd-analysis.txt`)

`NICE_EXP_TOP_STAGE=k` runs the kernel up to stage k, XORs everything computed so far into a sink, and keeps a top only if the sink equals a value it never takes (`pw[1] ^ 0x9E3779B9`). Nothing is certified, so the bookkeeping and the later phases do no work, but the kernel's launch shape is unchanged. Each stage's cost is the difference to the stage before. Stage 0 is the whole kernel.

#### b62 1e16, 1 field, profiled (2 rounds)

Whole field 23.95 s profiled device time; top phase 8.61 s; `top_kernel` 7.44 s; `top_scan` + `top_fill` 1.17 s; 4,508,762,994 certified tops of 13.9 G (prefix, partition) pairs.

| stage | `top_kernel` s (rounds) | step s | share of the kernel |
|---|---|---|---|
| 1: a, e, clip (+ launch, `tlay` loads) | 0.408 (0.410, 0.406) | +0.408 | 5.5 % |
| 2: + a², e², a³, e³ (`powers16`) | 1.119 (1.117, 1.122) | +0.711 | 9.6 % |
| 3: + d = e^j − a^j, ndig(d) (binary search) | 2.154 (2.150, 2.158) | +1.035 | 13.9 % |
| 4: + long division of a^j by b² (16-bit limbs) | 4.606 (4.603, 4.609) | +2.452 | 32.9 % |
| 5: + digits, run/dup selects, x mod b^c0 | 6.213 (6.210, 6.216) | +1.608 | 21.6 % |
| 6: + carry test | 6.475 (6.474, 6.476) | +0.262 | 3.5 % |
| 7: + closure | 6.827 (6.822, 6.831) | +0.351 | 4.7 % |
| 0: whole kernel (+ bookkeeping) | 7.441 (7.363, 7.519) | +0.615 | 8.3 % |

#### b60 1e16, 1 field, profiled (1 round)

Whole field 39.32 s; top phase 11.36 s; `top_kernel` 9.60 s; scan + fill 1.76 s; 6,869,484,234 certified tops.

| stage | `top_kernel` s | step s | share |
|---|---|---|---|
| 1 | 0.565 | +0.565 | 5.9 % |
| 2 | 1.474 | +0.909 | 9.5 % |
| 3 | 2.997 | +1.523 | 15.9 % |
| 4 | 6.146 | +3.149 | 32.8 % |
| 5 | 7.934 | +1.788 | 18.6 % |
| 6 | 8.615 | +0.681 | 7.1 % |
| 7 | 8.758 | +0.143 | 1.5 % |
| 0 | 9.597 | +0.839 | 8.7 % |

- The stages are subtractive, so a step's cost includes whatever the compiler could no longer drop or overlap. The sum is exact; the split is approximate. Stage 3 is the clearest: (c) removed 1.05 s of the kernel at b62 (section 4), against 1.035 s measured for the step.
- **The task's five buckets at b62:** computing a^j and e^j 9.6 %; the digit conversion of a^j 54.5 % (long division 32.9, digit extraction and its run/dup/remainder bookkeeping 21.6); the carry test 3.5 % (17.4 % with d and the ndig search it needs); certificate assembly and closure 4.7 %; top-fill/scan bookkeeping 8.3 % inside the kernel plus 1.17 s in `top_scan` + `top_fill` (13.6 % of the top phase). Launch and a/e 5.5 %.
- **Static SASS** (`raw/box/sass/`, `raw/box/sass2/summary.txt`):
  - Method: the kernels' CUDA source from `CUBECL_DEBUG_LOG`, compiled offline with nvcc 12.8 `-arch=sm_86 -O3`, which may differ from NVRTC's flags. Static counts do not see loop trip counts: the binary search is a small loop that runs about 6 times.
  - #235's top kernel at b62: 5,320 instructions, 87 registers (2 blocks of 256 per SM), no spills. 2,260 of the instructions are IMADs, 472 of those `IMAD.WIDE`, the compiler's multiply-high for the division by 3,844.
  - Per variant (`exp2` build):

  | variant | instructions | registers |
  |---|---|---|
  | #235 | 5,336 | 86 |
  | (a) | 5,216 | 80 |
  | (b) | 5,120 | 91 |
  | (c) | 5,304 | 100 |
  | (a)+(c) | 5,216 | 89 |
  | (a)+(b) | 5,016 | 91 |
  | all three | 4,936 | 98 |

## 2. Candidate (a): e^j − a^j from δ = e − a (`powers_diff`)

- δ = e − a fits one u32 word in the top kernel (δ < w, and w is a u32). The kernel forms a² and a³ as before, then e² − a² = δ(2a + δ) and e³ − a³ = δ(3a² + 3aδ + δ²) in 16-bit limbs, and packs them as the words `cert_power` used to compute as y − x. e² and e³ are never formed.
- At b62 (3 words) that is 56 limb products instead of 108 plus two subtractions. The test kernel's arbitrary intervals reach widths of 2^40, so `powers_diff` takes δ's width as a comptime `dw`: 1 in the top kernel and for the test's production-shaped groups (asserted), `limbs` for the arbitrary ones.
- **Exact:** the certificate test passes on CUDA (`raw/box/x/cert_diff.log`) with #235's counts, and checks (a)'s d², d³, a² and a³ word for word against `powers16` + `sub_words16`. Join parity on CUDA with (a)+(b) passes (`raw/box/x/parity_both.log`).
- **Speed:** top kernel 7.44 → 6.95 s (×0.934) at b62, 9.60 → 9.43 s (×0.982) at b60. Static SASS 5,216 (−104). Registers fall from 87 to 80, which allows 3 blocks per SM instead of 2. The kernel gain at b62 (6.6 %) is larger than the 2 % static cut, so occupancy may be part of it (not followed up). Whole field ×1.020 (b62), ×1.016 (b60), inside two rounds' spread.

## 3. Candidate (b): a division-free digit step (`cert_power32`)

- a^j in u32 words. Each pass divides by B = b^k, the largest power below 2^32 (b62: k = 5, B = 916,132,832; 8 passes for the cube instead of 19), with the Möller–Granlund 2/1 step: the dividend normalised by B's leading zeros (2 bits at b62), q̂ from the precomputed reciprocal v = ⌊(2^64 − 1)/(B·2^sh)⌋ − 2^32 by `mul_hi` and a multiply, then two corrections (the second is rare but needed for exactness). The chunk's 5 digits come out by `mul_hi(x, m) >> s` with a magic m the host checks to be exact for every x < B (all bases 10–64 here; a one-correction form is compiled otherwise). x mod b^c0 is assembled in u32 words with `mul_hi`. All constants are comptime; there is **no `/` or `%` by a constant in the new code**.
- CubeCL's `mul_hi` lowers to `__umulhi` on CUDA, `OpUMulExtended` on SPIR-V, and a u64 product and shift on WGSL. The u64 form is a HI32 value, but nothing divides it, which is the pattern the Metal rule and the lint are about; it still needs an M4 run before it ships anywhere near Metal.
- The pass and the digit magic were checked in Python against big integers before the device tests (`raw/scripts/check_host_math.py`).
- **Exact:** certificate test on CUDA passes (`raw/box/x/cert_bar.log`), same counts.
- **Speed:** top kernel ×0.962 (b62), ×1.016 (b60); whole field ×1.011 (b62), ×0.995 (b60). Static SASS 5,120, 200 fewer than #235's: `IMAD.WIDE` 472 → 156, `IMAD` 1,788 → 1,495, `LOP3` and `SHF` 760 fewer, but 108 `IMAD.HI` and 1,080 more `IADD3`/`SEL`/`ISETP` for the corrections and carries. 91–93 registers (still 2 blocks per SM).
- Why the 2.4× fewer division steps do not show up as time was not measured. A likely part: one MG step's remainder feeds the next through about nine dependent operations (multiply-high, add, multiply, subtract, two compare-and-selects) against about five for the 16-bit step, and at 2 blocks per SM there is little else to overlap with.
- On CUDA the old constant division was already a multiply-high and a shift, so alone (b) has little to remove (×1.01). On top of (a)+(c) it measured ×0.994 at b62 1e16 and ×1.031 at 1e17 (section 5); that is unresolved. #235 is already Metal-safe by construction (16-bit limbs, the first step on two limbs), so (b) adds no safety there, only the removal of every constant division from the certificate.

## 4. Candidate (c), from the breakdown: ndig(d) from the bit length (`ndig_fast`)

- `cert_power` found c0 = max(cap, ndig(d)) by a binary search over [0, sp]: about 6 iterations, each a 9-word compare against `pw` in global memory with a branch per word, for each power.
- With L = bit length of d, at most one power of b lies in (2^(L−1), 2^L], so ndig(d) is c or c + 1 for c = ⌈L·log_b 2⌉ − 1. c comes from a host-searched multiply-shift ((L·m + a) >> s, checked for every L up to 32·nl), and one branch-free compare with b^c picks. c is clamped to sp first, which reproduces the search's min(ndig, sp).
- **Exact:** the certificate test passes on CUDA with (c) alone, with (a) + (c) and with all three (`raw/box/x2/cert_{ndig,dn,all}.log`), and on lavapipe with all three; join parity on CUDA with (a) + (c) and with all three (`raw/box/x2/parity_{dn,all}.log`). The multiply-shift was checked on the host for every bit length up to 288 at every base the test uses, and against big-integer ndig for random d (`raw/scripts/check_host_math.py`, `raw/check_host_math.txt`). The profiled runs certify the same 4,508,762,994 tops at b62 1e16 in every variant.
- **Speed:** top kernel 7.51 → 6.46 s (**×0.861**) at b62, profiled, 2 rounds each (`raw/box/ab/prof_*`); the step it replaces measured 1.035 s, and (c) saved 1.05 s. Whole field **×1.042 (b62), ×1.039 (b60)**.

## 5. A/B (`raw/ab.sh`, `raw/chain2.sh`, `raw/chain3.sh`; `raw/ab-analysis.txt`)

One binary (`exp2`), switches by env, rounds interleaved, medians; "per round" is base's time over the variant's in the same round. dn = (a) + (c); all = (a) + (b) + (c). Each "s/field" line's counts are survivors / full checks / found: found = 0 everywhere, and survivors move by a few in 10^7 between runs in every variant, base included (the stage overrun's timing, as in L29); the exactness evidence is section 6. Every timed run sat at the 180 W cap: per-run median 1,432–1,500 MHz, 179.2–179.8 W, at most 52 °C (`raw/ab-analysis.txt`).

- Two b62 1e16 sets were run, about 30 minutes apart. Base moved by 0.3 % between them (17.896 and 17.943 s); dn's and all's ratios are from the second.
- b62 1e17 is one dense field (30.6 M top-layer prefixes); a 1e17 run takes 195–210 s. Its rounds differ by 2 % in base itself.

<!-- AB-BEGIN -->
#### b62 1e16, 2 fields: all six variants

| variant | s/field (rounds, in run order) | spread | median | / base | speed-up (medians) | speed-up per round |
|---|---|---|---|---|---|---|
| base | 17.216, 17.896, 17.920 | 3.9 % | **17.896** | ×1.000 | **×1.000** | ×1.000, ×1.000, ×1.000 |
| diff | 17.228, 17.597, 17.542 | 2.1 % | **17.542** | ×0.980 | **×1.020** | ×0.999, ×1.017, ×1.022 |
| bar | 17.158, 17.707, 17.754 | 3.4 % | **17.707** | ×0.989 | **×1.011** | ×1.003, ×1.011, ×1.009 |
| ndig | 17.022, 17.170, 17.199 | 1.0 % | **17.170** | ×0.959 | **×1.042** | ×1.011, ×1.042, ×1.042 |
| both | 17.448, 17.507, 17.339 | 1.0 % | **17.448** | ×0.975 | **×1.026** | ×0.987, ×1.022, ×1.034 |
| all | 16.670, 17.067, 16.950 | 2.3 % | **16.950** | ×0.947 | **×1.056** | ×1.033, ×1.049, ×1.057 |

- base: 163510216650 / 10030871168 / 0; 163510219593 / 10030868224 / 0; 163510210466 / 10030876927 / 0
- diff: 163510221112 / 10030866999 / 0; 163510231475 / 10030856479 / 0; 163510214851 / 10030872171 / 0
- bar: 163510220326 / 10030867168 / 0; 163510222803 / 10030864092 / 0; 163510226898 / 10030860463 / 0
- ndig: 163510237128 / 10030851617 / 0; 163510228535 / 10030859532 / 0; 163510209580 / 10030877305 / 0
- both: 163510216689 / 10030870392 / 0; 163510232930 / 10030855310 / 0; 163510232636 / 10030856209 / 0
- all: 163510219332 / 10030868545 / 0; 163510232407 / 10030856012 / 0; 163510220528 / 10030866872 / 0

#### b62 1e16, 2 fields: base, dn, all (second set)

| variant | s/field (rounds, in run order) | spread | median | / base | speed-up (medians) | speed-up per round |
|---|---|---|---|---|---|---|
| base | 18.299, 17.915, 17.943 | 2.1 % | **17.943** | ×1.000 | **×1.000** | ×1.000, ×1.000, ×1.000 |
| dn | 17.370, 16.889, 16.900 | 2.8 % | **16.900** | ×0.942 | **×1.062** | ×1.053, ×1.061, ×1.062 |
| all | 17.010, 16.998, 17.058 | 0.4 % | **17.010** | ×0.948 | **×1.055** | ×1.076, ×1.054, ×1.052 |

- base: 163510236007 / 10030852518 / 0; 163510214917 / 10030872569 / 0; 163510244447 / 10030843781 / 0
- dn: 163510221744 / 10030866002 / 0; 163510222625 / 10030865317 / 0; 163510224739 / 10030863945 / 0
- all: 163510219489 / 10030868041 / 0; 163510228519 / 10030858953 / 0; 163510222921 / 10030865169 / 0

#### b60 1e16, 2 fields: all six variants

| variant | s/field (rounds, in run order) | spread | median | / base | speed-up (medians) | speed-up per round |
|---|---|---|---|---|---|---|
| base | 40.675, 40.468 | 0.5 % | **40.572** | ×1.000 | **×1.000** | ×1.000, ×1.000 |
| diff | 39.719, 40.165 | 1.1 % | **39.942** | ×0.984 | **×1.016** | ×1.024, ×1.008 |
| bar | 40.646, 40.897 | 0.6 % | **40.772** | ×1.005 | **×0.995** | ×1.001, ×0.990 |
| ndig | 38.601, 39.482 | 2.3 % | **39.041** | ×0.962 | **×1.039** | ×1.054, ×1.025 |
| both | 39.761, 39.755 | 0.0 % | **39.758** | ×0.980 | **×1.020** | ×1.023, ×1.018 |
| all | 39.051, 38.431 | 1.6 % | **38.741** | ×0.955 | **×1.047** | ×1.042, ×1.053 |

- base: 459049836396 / 32549370505 / 0; 459050299419 / 32548938966 / 0
- diff: 459050584030 / 32548676963 / 0; 459050392043 / 32548841005 / 0
- bar: 459051035570 / 32548248310 / 0; 459050559321 / 32548694189 / 0
- ndig: 459049968617 / 32549250232 / 0; 459050682577 / 32548582480 / 0
- both: 459051183719 / 32548111808 / 0; 459050830690 / 32548454472 / 0
- all: 459050620655 / 32548638074 / 0; 459050421142 / 32548831538 / 0

#### b60 1e16, 2 fields: base, dn

| variant | s/field (rounds, in run order) | spread | median | / base | speed-up (medians) | speed-up per round |
|---|---|---|---|---|---|---|
| base | 40.411, 39.957 | 1.1 % | **40.184** | ×1.000 | **×1.000** | ×1.000, ×1.000 |
| dn | 39.113, 38.819 | 0.8 % | **38.966** | ×0.970 | **×1.031** | ×1.033, ×1.029 |

- base: 459050539416 / 32548727012 / 0; 459050140774 / 32549079802 / 0
- dn: 459049983263 / 32549233178 / 0; 459049788431 / 32549424871 / 0

#### b62 1e17, 1 field

| variant | s/field (rounds, in run order) | spread | median | / base | speed-up (medians) | speed-up per round |
|---|---|---|---|---|---|---|
| base | 207.624, 203.604, 203.255 | 2.1 % | **203.604** | ×1.000 | **×1.000** | ×1.000, ×1.000, ×1.000 |
| dn | 195.547, 199.537, 199.430 | 2.0 % | **199.430** | ×0.979 | **×1.021** | ×1.062, ×1.020, ×1.019 |
| all | 193.120, 196.191, 193.332 | 1.6 % | **193.332** | ×0.950 | **×1.053** | ×1.075, ×1.038, ×1.051 |

- base: 1020728420483 / 62692676677 / 0; 1020728405810 / 62692687429 / 0; 1020728368346 / 62692725478 / 0
- dn: 1020728339905 / 62692751184 / 0; 1020728401803 / 62692693929 / 0; 1020728293393 / 62692792272 / 0
- all: 1020728358272 / 62692729498 / 0; 1020728360038 / 62692731975 / 0; 1020728459632 / 62692639474 / 0
<!-- AB-END -->

## 6. Exactness

| check | result |
|---|---|
| certificate test (`cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`), CUDA, `exp`: (a), (b), (a)+(b) | ok, 102,365 intervals, 33,582 kept, 203,413 scanned above c0, 69,824 with the carry, each (`raw/box/x/cert_{diff,bar,both}.log`) |
| the same, `exp2`: (c), (a)+(c), (a)+(b)+(c) | ok, same counts (`raw/box/x2/cert_{ndig,dn,all}.log`) |
| (a)'s d², d³, a², a³ against `powers16` + `sub_words16`, word for word, inside that test (new) | 0 mismatches in every run with (a) |
| join parity (`cubecl_cuda_join_matches_the_cpu_reference`), CUDA: (a)+(b); (a)+(c); all three | ok (`raw/box/x/parity_both.log`, `raw/box/x2/parity_{dn,all}.log`) |
| certificate test on lavapipe, naga (WGSL), all three | ok, same counts (`raw/box/lvp/cert_naga_all.log`) |
| certificate test on lavapipe, direct SPIR-V, all three | ok, same counts, 206 s, no stack overflow (`raw/box/lvp/cert_spv_all.log`) |
| certificate test on lavapipe, naga, (a)+(c) | ok, same counts (`raw/box/lvp/cert_naga_dn.log`) |
| join parity on lavapipe, direct SPIR-V, all three | ok: every window b10–b64, the b57 frontier partitions, tight, sliced and refused layouts, the production shape; 111 s, no stack overflow (`raw/box/lvp/par_all_spv.log`) |
| smoke run of all four switch settings at 300 samples before the full tests | ok (`raw/smoke.log`) |
| certified tops at b62 1e16 in the profiled runs | 4,508,762,994 in every variant (base, (a), (b), (a)+(b), (c), (a)+(c), all) |

Not run: #235's other checks (dense fields, the whole b42 field, join = stride, the host suite, fmt and clippy). The breakdown stages are not results and were not checked.

## 7. SPIR-V blocks and the WGSL lint (lavapipe)

Lavapipe (Mesa llvmpipe, LLVM 20.1.2) on the box, `exp2`'s naga and direct-SPIR-V test binaries (`2802fc5e`, `9302cc8d`). CI's lint step, `wgsl_dump_for_lint`, compiles TopKernel at b57 on the production shape, so its dump gives both the WGSL for the lint and, run on the SPIR-V binary, the block count (`raw/scripts/blocks.py`, L29's counter).

| TopKernel b57, SPIR-V blocks (`raw/box/lvp/blocks_*.txt`) | blocks |
|---|---|
| #235 (switches off) | 478 (L29's table: 478) |
| (a) | 478 |
| (b) | 370 |
| (c) | 366 |
| (a) + (c) | 366 |
| (a) + (b) + (c) | 258 |

- (c) removes the binary search and its branch per word. (b) runs 5 and 8 passes (square, cube) instead of 13 and 19, and each pass carries two branches. (a) has no data-dependent branches, so it changes nothing here.
- The other join kernels are unchanged (JoinKernel 135, TopScanKernel 88, TopFillKernel 11).
- **Every base, all three switches** (join parity dump, `raw/box/lvp/blocks_par_all.txt`): TopKernel b64 270, b60 264, b57/b58 258, b54 210, b50 198, b40 180, b10 102 blocks, against #235's 496 at b64 (L29). (a)+(c) was only counted at b57 (366, against 478); at b64 it should land near 384, since #235 itself adds 18 blocks from b57 to b64.
- **WGSL lint**, CI's command and require list, on the dump with all three switches and with (a)+(c): 15 shaders, **0 flagged**, exit 0 (`raw/box/lvp/lint_{all,dn}.txt`). The new code has no `/` or `%` by a constant: (b) is multiply-high and shifts, (c) a multiply-shift, (a) multiplies and adds. The kernel's remaining constant divisions (#235's long division when (b) is off, the bookkeeping's `% (b − 1)`) are unchanged.

## 8. Verdict and what a PR would need

**Against the bar** (a whole-field win of ≥ 5 % at b62):

| change | b62 1e16 | b62 1e17 | b60 1e16 | verdict |
|---|---|---|---|---|
| (a) e^j − a^j from δ | ×1.020 | – | ×1.016 | below the bar |
| (b) division-free digit step | ×1.011 | – | ×0.995 | below the bar |
| (c) ndig from the bit length | ×1.042 | – | ×1.039 | below the bar alone |
| (a) + (c) | ×1.062 | ×1.021 | ×1.031 | mixed |
| (a) + (b) + (c) | ×1.056, ×1.055 | **×1.053** | ×1.047 | **meets it, narrowly** |

**Recommendation: a PR with all three, if (b) passes on the M4.** Its gain is small and the margin over 5 % is inside the noise, so the PR body should say ≈ 5 % at b62 and 4–5 % at b60 on a 180 W 3080. If (b) fails on the M4, or a reviewer does not want it, (a) + (c) alone is 2–6 %, below the bar. In that case park (a) and keep (c) for the next PR that touches `cert_power`: it is a short, self-contained change and gives ×1.04 by itself.

**What a PR needs:**
1. **M4 (mayalaran) for (b):**
   - `mul_hi` lowers to a u64 product shifted right by 32 in WGSL, which naga turns into `ulong` arithmetic in MSL. That is the HI32 shape behind the Apple bug; here nothing divides it, which the bug needs, but it has to be seen to work.
   - Run the certificate test and join parity on Metal.
   - (c)'s `countLeadingZeros` and (a)'s multiplies should come along in the same run.
2. **SPIR-V blocks:** done here. With all three, TopKernel is at most 270 blocks at any base (b64), against #235's 496, so the compile-stack margin grows. Re-count on the PR's final code with `blocks.py`.
3. **WGSL lint:** CI's command passes with 0 flagged sites. (b) and (c) contain no division by a constant; once (b) is in, the long division of #235 is gone from the top kernel.
4. **Code, from the experiment to a PR:**
   - Drop the switches, `NICE_EXP_TOP_STAGE`, the sink and the profile cherry-pick.
   - `cert_power32` replaces `cert_power` in `top_cert`. The 16-bit `cert_power` can go, or stay as a test reference beside the lockstep scan.
   - `powers_diff` with `dw` = 1 in the top kernel. The test keeps the general `dw` and its word-for-word check against `powers16` + `sub_words16`.
   - `ndig_fast` replaces the binary search in both scans.
   - Host tests for `chunk32`, `mg_consts`, `digit_magic` and `ndig_magic` at every base 10–64 and every `nl` in 1–9. Their search loops panic if a base has no constant; they could become a const table instead.
   - Rewrite `cert_power`'s doc: its Metal paragraph explains the 16-bit limbs, which (b) removes.
   - Run fmt and clippy (the experiment code has not been through them), the dense-field and whole-b42 checks, join = stride, and the host suite, as #235 did.
5. **Measure what this did not:** b64, NiceMark, an uncapped card, and more 1e17 rounds of (a) + (c) against all three. The 1e17 rounds disagree by 3 % on how much (b) adds.
6. A one-line CHANGELOG entry.

**Not pursued, for the record** (from the breakdown):
- The long division is still the largest stage even with (b) (static count only; its breakdown was not re-run).
- Digit extraction with the run/dup selects is 22 % and runs on u64 masks; two u32 halves might be cheaper.
- `top_scan` + `top_fill` cost 16 % of the kernel again.
- The kernel runs 2 blocks of 256 per SM at 86–100 registers. (a) alone drops it to 80, which allows 3, and (a)'s kernel gain at b62 (6.6 %) is larger than its 2 % static instruction cut. Occupancy may therefore matter; this was not followed up. (a)+(c) and all three are back at 89 and 98 registers.

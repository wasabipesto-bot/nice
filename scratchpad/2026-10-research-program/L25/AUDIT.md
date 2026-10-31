# L25: the Apple Metal half-width-shift division, audited across the GPU kernels (upstream 472c9a0)

## Bottom line for the maintainer

**At the bases in production today, no nice-only, detailed or browser kernel should give wrong results on Apple GPUs.
One production kernel does carry the miscompiled pattern, and it would give wrong results at bases 49-55.**

- **Where the pattern is.** It occurs in two kernels, both from an unrolled split16 long division whose first step has a
  remainder of literal 0, so the dividend is `word >> 16`.
  - **The overlap join's `top_kernel` (`cert_power`):** 28-64 sites per base.
  - **The stride kernel's low-digit prefilter:** 6 sites, and it runs only at bases ≤ 40.
- **Why the join's live bases are safe.** In `top_kernel` the shifted word is the top limb of n² or n³. That limb is 0 at
  bases 40-44 and 57-64, so the bad division always gets 0 and has nothing to corrupt.
- **Where it goes wrong.** At bases 49-55 the inputs are the same as those that broke #225's FD seed on the M4, so the
  join would certify tops wrongly on a Mac. That means lost survivors, so a nice number could be missed. Those bases lie behind
  the live frontier (b57-64), but a rescan or verification claim run on a Mac would hit it.
- **The prefilter.** It passed the M4's probe test (b30/b34/b40) in its current paired-`%` form in August, on the same
  macOS.
- **Everything else is clean.** Every other kernel either has no constant division of a half-width shift, or keeps the
  remainder loop-carried at run time:
  - the join's bucket, join and check kernels;
  - the stride enumeration;
  - the per-number detailed kernel;
  - the browser kernel.
- **The fix.** Branch `pr/metal-halfshift-top-kernel` on the fork removes the pattern from `top_kernel` at no measurable cost.
  - It is exact on CUDA and lavapipe.
  - Its survivor and check counts are identical to main over three production fields each at b58 and b62.
  - It still needs one M4 run to confirm.

## 1. The pattern and a value model that predicts it

The pattern is defined in `L3/METAL-FIX.md`. Apple's GPU compiler (M4, macOS 26.3) miscompiles these, for a constant K
that is not a power of two:
- `naga_div(x >> 16u, K)`;
- `(x >> 16u) % K`;
- `uint(ulong p >> 32) / K`.

A site has the pattern only if its dividend is a bare half-width shift after literal zeros fold away. Whether it is
actually wrong then depends on the value:
- **H2 model.** The M4 returns the quotient of the low 16 bits instead, at every K tried except 12167 (b23), which has
  its own garbage. The remainder is computed by multiply-subtract from the wrong quotient.
- **A word of 0 is safe.** Both halves give 0, and inputs 0-2 came back exact even at K = 12167.
- **The model fits the observed failures.** `analysis/h2_model.py` applies H2 to the split16 long division of n² and n³
  (the `cert_power` code, which is the same code as the pre-fix FD seed's `fd_to_digits`) over each base's range
  (`analysis/h2_model.out`, `analysis/topwords.out`).
  - It predicts wrong digits at b25, b27-b30, b49, b50 and b52-b55, and nothing elsewhere. b32 and b64 have
    power-of-two K.
  - That is exactly the FD seed's M4 failure set, with b23 added by the K = 12167 quirk.
  - b45, b47 and b48 have a nonzero top word, but it is below K. They are predicted exact and were exact in the M4's
    pre-fix seed test.

| bases | top 32-bit word of n² / n³ (limbs 2L / 3L) | first split16 dividend on M4 |
|---|---|---|
| 40-44, 57-64 | 0 / 0 | 0: safe |
| 45, 47, 48 | 0-1108 / 0 | below K: exact under H2, and exact in the FD seed on the M4 |
| 49, 50 | 1640-120370 / 1-637 | n² wrong for 76-98 % of n |
| 52-55 | up to 2^32 / up to 2^31 | n² and n³ wrong for 95-100 % of n |
| 20-32 (tests only) | various | b25, b27-30 wrong (b23 quirk) |

## 2. Method and evidence

1. **Source.** Every `/`, `%` and `/=` in `#[cube]` code (`cubecl_backend.rs`, `cubecl_join.rs` and `cubecl_web.rs`;
   there are no other cube modules). That is 92 lines: `analysis/div_sites_raw.txt`.
2. **WGSL dumps.** On the RTX 3060 box (lavapipe as the wgpu device), main 472c9a0 with `--features gpu`, and
   `CUBECL_DEBUG_LOG` set while a box-local driver test (`scripts/l25_dump.rs`) ran each kernel once per base.
   - Bases 40, 58, 60, 62 and 64 (`raw/dumps/b*/`).
   - At b58-64 the join and stride runs used production field starts (the throughput test's), so every join kernel
     compiled with its production comptime parameters.
   - The b64 stride kernel compiled nothing, because the MSD filter left no range in the window. Its source differs from
     b62's only in constants, and its K is 4096.
   - Split per kernel into `raw/wgsl/*.wgsl` (plus `.info.txt` with the comptime parameters).
3. **Scanner.** `analysis/wgsl_scan.py` folds literal zeros (`l_mut = u32(0)` up to the next brace, `0 << k`, `0 | y`).
   It then flags every `/ u32(K)` and `% u32(K)` whose dividend is `x >> 16`, `u32(u64 >> 32)` or `u32(u64 >> 32) >> 16`.
   - **Results:** `raw/wgsl_scan.txt`.
   - **Validated** on L3's dumps (`raw/wgsl_validate_scan.txt`). It flags the pre-fix FD seed: 7 sites at b10, 26 at
     b40 and 59 at b62. It flags all of the HI32 and HI32>>16 repro kernels. It finds nothing in the per-number kernel.
4. **MSL and an LLVM proxy.**
   - naga 29.0.4 MSL for the main kernels is in `raw/msl/`, for example `TopKernel_b58_0.metal:1618-1621`:
     `l_842_ = _e1853 << 16u; l_843_ = l_841_ >> 16u; l_844_ = l_842_ | l_843_; naga_div(l_844_, 3364u)`, with
     `_e1853` the zeroed `l_mut`.
   - The same MSL compiled as C++ with clang 18 at -O2 (`analysis/ir/msl_shim.h`, `ir_scan.py`, `scripts/ir.sh`) shows
     LLVM folding `(x >> 16) / K` into `x / (K << 16)`.
   - Those folded divisions appear only in the top kernel: 16-20 per base at b58/b60/b62 (`raw/ir_prod_scan_full.txt`).
     At b40, K << 16 exceeds 2^31 and the division becomes a compare.
   - None remain after the fix (`raw/ir_fix_scan.txt`). The only divisions left there are ones LLVM narrowed to i16,
     which the M4-exact bucket and join kernels have too.
   - This is only a proxy: Apple's pipeline is not LLVM 18, and the swift repro shows that plain and naga-guarded forms
     of the same division differ on the M4.
5. **Values.** `analysis/topwords.py` gives the top limb per base, and `analysis/h2_model.py` gives the error rates.

## 3. Site table (472c9a0)

The verdicts:
- **(a)** cannot hit the bug;
- **(b)** can hit it;
- **(c)** unsure.

"WGSL" gives the number of flagged sites in the dumps.

| file:line | kernel / function | expression | divisor | dividend | WGSL | verdict |
|---|---|---|---|---|---|---|
| `cubecl_join.rs:656-657`, `664-665` | `top_kernel` → `cert_power`, first step of each pass (x and y) | `((rx << 16) \| (vx >> 16)) / chunk_div`, with `rx` a literal 0 (unrolled `for pass`, `for jj`) | `chunk_div` = b^k < 2^16 (b40 64000; b58 3364; b60 3600; b62 3844; b64 4096) | **bare `x[top] >> 16`**; in pass 0, `x[top]` is the u64 high half of the schoolbook sum | b40 28, b58 60, b60 60, b62 64, b64 64 (power-of-two K) | **(b)** at b49-55 (and b25-30 test windows). Safe by value at b40-44 and b57-64 (top limb 0); b64 also has power-of-two K. **Fixed on the branch.** |
| `cubecl_join.rs:658-661`, `666-669` | same, second half-step | `((r1 << 16) \| (vx & 0xFFFF)) / chunk_div` | same | OR of a run-time remainder and a mask | 0 | (a) |
| `cubecl_backend.rs:433-437` | `candidate_check` low-digit prefilter (stride `niceonly_kernel` only; the join's check passes `pre_limbs = 0`) | `c1 = (rem << 16) \| (vi >> 16); c1 / K; c1 % K`, with `rem` a literal 0 at each `rr` pass's first step | `pre_chunk_div` = b^3 (b40 64000) | bare `v[top] >> 16`; for L = 2, `v[1] = u32(n_lo >> 32)`, so `u32(u64 >> 32) >> 16` | b40 6 (b58-62 0: prefilter off) | **(c)**, leaning (a). It runs only at b ≤ 40 (`GPU_PREFILTER_MAX_BASE`). At b33-40 `v[1] < K`, so it is exact under H2. In the August M4 run (06ddd5e, macOS 26.3) the mul-sub form failed `cubecl_prefilter_survivors_match_the_host_mirror` (b30/34/40) and this paired form passed, and b30 would fail under H2. So the pairing evidently dodges it, for unknown reasons. |
| `cubecl_backend.rs:457-458`, `473-474`, `495-496` | prefilter truncated multiply and digit peel | `t % K`, `t / K`, `c % base`, `c /= base` | b^3, b | product sums and chunks | 0 | (a) |
| `cubecl_backend.rs:243`, `594`, `713` | wide chunk scan (u64) | `cur / u64(chunk_div)` | b^k < 2^31 | `(rem64 << 32) \| word`, never on wgpu (`wide_chunk_for` is false there) | 0 | (a) |
| `cubecl_backend.rs:253-257` (detailed), `604-608` and `723-727` (nice-only full check), `cubecl_web.rs:202-206`, `303-307` | split16 digit scans | `((rem << 16) \| (vi >> 16)) / chunk_div` | b^k < 2^16 | `rem` is loop-carried in a run-time `while i >= 0` loop, so it is never a literal 0 in the WGSL | 0 | (a). The per-number detailed kernel was exact on the M4 (10-30). The residual risk is only if Apple's compiler peeled that loop's first iteration. |
| `cubecl_backend.rs:275`, `291`, `627`, `649`, `746`, `768`; `cubecl_web.rs:223`, `245`, `324`, `346`; `cubecl_join.rs:675-678` | digit peel | `chunk / base`, `rx % base` | base | a run-time remainder | 0 | (a) |
| `cubecl_backend.rs:949-952`, `1126-1129`, `1303-1305` | stride offset reduction (3 enumeration variants) | `acc = ((acc << 8) \| ((word >> s) & 255)) % stride_m` | M = (b-1)·b³ (≥ 78,608 for b ≥ 17; b40 2,496,000) | first step `(off_hi >> 24) & 255`, a shift by 24 | 0 | (a). If LLVM merged steps 1-2 into `off_hi >> 16`, that value is below 2^16 < M, so the same pass removes the `%` (no folded remainder shows in the IR proxy). Not M4-tested with `off_hi ≠ 0`; the existing parity tests use 5e6 fields. |
| `cubecl_backend.rs:978`, `1155`, `1328` | stride enumeration | `g / stride_r` | R | a run-time ordinal | 0 | (a) |
| `cubecl_backend.rs:117`, `cubecl_web.rs:132` | histogram copy | `(UNIT_POS_X >> 5) % 4` | 4 | shift by 5 | - | (a): power of two |
| `cubecl_backend.rs:906`, `1082-1083`; `cubecl_join.rs:1195-1196` | plane bookkeeping | `/ PLANE_DIM`, `% PLANE_DIM` | run-time | - | - | (a) |
| `cubecl_join.rs:194-201`, `216-217`, `228-229`, `255-256`, `267-268` | `bucket_kernel` digits | `x % base`, `x /= base`, `col % base`, `(2*d0) % base` | base | loaded words, column sums, products | 0 | (a) |
| `cubecl_join.rs:360`, `409-414` | `join_kernel` | `bx / m1`; `((pk & 255) + dkey*((pk >> 16) & 255)) % base` | b-1, base | loaded or masked sums | 0 | (a) |
| `cubecl_join.rs:993`, `1001`, `1089` | `top_kernel` / `top_fill_kernel` classes | `(… * pdiv_m1 + v) % m1`, `(roots + m1 - pc) % m1` | b-1 | sums | 0 | (a) |
| `cubecl_join.rs:1122-1153` | `mid_pass` (join prefilter) | `x % base`, `col / base` | base | loaded words, column sums | 0 | (a) |
| `cubecl_join.rs` `check_kernel` | full check | as `candidate_check` without prefilter; `n_hi = bq >> 32` is multiplied, never divided | - | - | 0 | (a) |

The hand-CUDA kernels (`cuda/nice_kernels.cu`) never run on Apple. Out of scope, but noted:
- `cubecl-metal` (CubeCL's own MSL, opt-in) has the 10-06 failure in this same `cert_power` division: the u64 high
  half of `a*a`, then `>> 16`, divided by K.
- The branch's power computation no longer uses u64 at all, so it should remove that failure too. This is not verified.

## 4. The fix: `pr/metal-halfshift-top-kernel` (fork), on 472c9a0

Two commits:
- **`ed972c7`, the fix plus a CHANGELOG line.**
  - **Powers in 16-bit limbs.** `top_kernel` builds a², e², a³ and e³ in 16-bit limbs, one to a u32, by schoolbook in
    u32. A limb product plus two values below 2^16 is at most 2^32 - 1.
  - **Top pair first.** `cert_power` starts each pass by dividing the top two limbs as one u32 (in pass 0 the sum `t`
    the schoolbook stored there, later the previous quotient), then one limb a step. This is the same long division,
    with one division fewer per pass, and no dividend is a bare shift or a u64 high half. It is the #225 metalfix
    construction applied to the join.
  - **`d = y - x`** packs the limb pairs back into u32 words for the existing borrow and binary search.
  - **CUDA too.** The top kernel always used the split16 constants, so CUDA runs the same code.
- **`56b68bf`, test windows at b50 and b54.** They are in the shared `WINDOWS` list, so they run on the CPU join, CUDA
  and every wgpu device.
  - **b50:** `[62082117268529817, +3e5)`, parameters (7,4,1), 934 join survivors and 97 prefilter survivors. Its start
    is `PLAN_FIELDS`' b50 start.
  - **b54:** `[2321864499473908801, +3e5)`, parameters (8,4,1), 445 join survivors and 51 prefilter survivors.
  - **How they were chosen.** A first pick at round-number starts had 0 survivors, which made it vacuous. The windows
    were then picked by a box-local CPU search (`scripts/l25_counts3.rs`; log `raw/tests/counts.log`).
  - **H2 predicts the M4 gets them wrong.** Every n in them has nonzero top words: n² top word about 48,600 at b50, and
    about 6.8e7 for n² and 7e6 for n³ at b54.

**WGSL after the fix.** The lavapipe test run dumped 97 kernels, including every `TopKernel` from b10 to b64, and none
has a flagged site (`raw/wgsl_fix_scan.txt`; dump at `raw/tests/wgsl_lvp_fix.log.gz`). The same run on main flags every
`TopKernel`: 50 sites at b50, 54 at b54, 58 at b57, 60 at b58 and b60, and 64 at b64 with power-of-two K
(`raw/wgsl_basew_scan.txt`).

`analysis/fixed_model.py` models the new long division in Python. It checks the digits exactly for 300 n per base,
bases 40-64, and confirms that no u32 intermediate overflows.

**Tests on the 3060 box:**

| tree | CUDA (CubeCL runtime) | lavapipe (wgpu/WGSL) |
|---|---|---|
| branch (`56b68bf`) | 3/3: `cubecl_cuda_join_matches_the_cpu_reference` (every window including b50/b54, tight and refused layouts), `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field` (b58 1e15, 16 partitions), `cubecl_cuda_matches_cpu_niceonly` (`raw/tests/cuda_fix.log`) | 3/3: `cubecl_join_matches_the_cpu_reference`, `join_sample_runs_partitions_of_a_production_field`, `cubecl_niceonly_keeps_join_and_stride_apart_by_ticket` (`raw/tests/lvp_fix.log`) |
| main + the windows only | 3/3 (`raw/tests/cuda_basew.log`) | 3/3 (`raw/tests/lvp_basew.log`) |

**Other checks.**
- **Host suite** (`--test-threads 8`): 208 passed on the branch. One run had a parallel-only failure in
  `gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field`. That test touches no join code. It
  passed 3/3 alone and 2/2 in later full runs, and main's full run passed (`raw/tests/host_fix.log` holds the failing
  run).
- **Lint.** `cargo fmt --all --check` is clean. `cargo clippy -p nice_common --all-targets -D warnings` is clean with and
  without `gpu` (`raw/tests/lint_fix.log`).

**Throughput.** `cubecl_cuda_join_throughput_fixed_fields`, b58 and b62, 3 production fields of 1e14 each, three
interleaved rounds against main on the 3060 (`raw/tput_summary.txt`):

| base | main (n/s, rounds) | branch (n/s, rounds) | ratio of medians |
|---|---|---|---|
| 58 | 6.106e13, 6.051e13, 6.123e13 | 6.067e13, 6.126e13, 6.090e13 | 0.997 |
| 62 | 8.342e13, 8.544e13, 8.483e13 | 8.350e13, 8.453e13, 8.315e13 | 0.984 |

- **Speed.** Both bases are within main's own round-to-round spread (1.2 % at b58, 2.4 % at b62). The top kernel is a
  small part of a batch.
- **Counts.** Join survivors and full checks are identical in every round: 13,321,769,835 / 797,815,648 at b58 and
  4,229,527,892 / 259,080,525 at b62.

## 5. What a Metal parity test needs

- **Join (`top_kernel`).** The existing join windows (b20, b25, b30, b34, b40, b57-64) all sit where the top word is 0
  or benign under H2 (the b25 windows start near the range start, the b30 top layer is empty). That is consistent with
  the M4's WGSL runs on 10-05/06 passing.
  - **Needed:** a window at b49-55 with join survivors, checked by `cubecl_join_matches_the_cpu_reference` on the M4.
    The branch's second commit adds two.
  - **Expected result:** run that test at 472c9a0 with only `56b68bf` applied, then on the branch. H2 predicts the first
    fails and the second passes; both pass on CUDA and lavapipe.
  - **A tighter stage test:** run `top_kernel` alone and compare every top's mask, floor seed and count with
    `Base::cert` at b49-55, as `cubecl_fd_seed_matches_cpu` does for the seed. Not written.
- **Prefilter.** Re-run `cubecl_prefilter_survivors_match_the_host_mirror` (b30/b34/b40) on the M4 under the current
  macOS. If it ever fails, the fix is the same 16-bit-limb, top-pair-first form. For L = 1 (b ≤ 32), dividing
  `u32(n_lo)` whole is also safe.
- **Stride offset reduction.** Add a nice-only parity window whose ranges sit more than 2^32 past the field start, for
  example a 1e10 field at b40 or b58 on the stride route. Today's 5e6 windows keep `off_hi = 0`, so an offset
  miscompile could not show.
- **CI.** The macOS runner's paravirtual GPU compiles all of these correctly, so CI cannot stand in for the M4.

## 6. Not done

- **No Apple hardware.** The fix, the new windows and the prefilter probe all need an M4 run.
- **No full lint.** The full `just lint` was not run: clippy covered `nice_common` with and without `gpu`, but not every
  package and not `cubecl-spirv`.
- **No stage test.** The `top_kernel` stage test above was not written.
- **No base 64 stride dump.** No stride kernel was dumped at b64 (no range survived the MSD filter in the window).
- **Throughput at b57, b60 and b64** was not measured.
- **No PR opened** (as instructed).
- **The box was left running.** Box `58492432` was not destroyed (only `list`/`ssh` are permitted). It self-destroys at
  about 07:43 UTC. Its scratch trees `/root/nice`, `/root/fix` and `/root/basew` are box-local.

## Files

| path | what |
|---|---|
| `analysis/div_sites_raw.txt` | every division line in cube code |
| `analysis/wgsl_scan.py` | WGSL splitter and scanner |
| `analysis/topwords.py`, `topwords.out` | top limbs per base |
| `analysis/h2_model.py`, `h2_model.out` | H2 error rates per base |
| `analysis/ir/` | MSL-as-C++ shim and IR scanner |
| `raw/dumps/b{40,58,60,62,64}/` | CubeCL debug logs and run outputs |
| `raw/wgsl/`, `raw/wgsl_scan.txt` | per-kernel WGSL at main, scan |
| `raw/wgsl_fix/`, `raw/wgsl_fix_scan.txt` | per-kernel WGSL with the fix, scan |
| `raw/wgsl_validate*/` | the scanner run on L3's known-bad dumps |
| `raw/msl/` | naga MSL of the main kernels |
| `raw/ir_prod_scan_full.txt`, `raw/ir_fix_scan.txt` | LLVM proxy scans |
| `raw/tests/` | CUDA/lavapipe/throughput logs, fixed WGSL dump |
| `scripts/` | box scripts (build, dumps, tests, IR) and the box-local driver tests |
| `repo/` | local clone with the branch |
| `src/` | 472c9a0 source snapshot (the site table's line numbers) |

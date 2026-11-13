# Verify `pr/join-prefilter-popcount-spirv` (c53d99f6) against main 41b4b405 (2026-11-13)

Box: Vast 60522271 (RTX 3080 at a 280 W cap, 16 threads, lavapipe = llvmpipe LLVM 20.1.2 with 8-lane subgroups),
rustc 1.100.0 (both trees pin it). Nothing was committed or pushed, and no PR was touched. Labels: **[M]** measured,
**[D]** derived, **[A]** assumed.

Binaries (each tree has its own target directory, `raw-verify/scripts/build.sh`; cargo 1.100's new build-dir layout
needed the script to pick the `unittests src/lib.rs` binary):

| label | tree | features | md5 |
|---|---|---|---|
| B | branch c53d99f6 | `gpu` (CUDA + wgpu with naga/WGSL) | 60e07039 |
| M | main 41b4b405 | `gpu` | aacdc4a6 |
| BS | branch | `gpu,cubecl-spirv` (wgpu through CubeCL's SPIR-V compiler) | 0b6133bd |
| MS | main | `gpu,cubecl-spirv` | a15a47b8 |

Logs are in `raw-verify/` (`logs/`, `out/`, `ident/` with the run outputs and comparison tables) and scripts in
`raw-verify/scripts/`. The full compilation logs stayed on the box; they are too large to copy, and the tables hold
the results.

## 1. Kernel identity

**How [M]:** `scripts/ident.sh` runs per binary:
- CubeCL's full compilation log (`cubecl.toml`, logger level `full`) of two production CUDA runs: the dense compare
  on one partition of b62 1e17 (`7520566762397899821056`) and of b64 1e17 (`58557331862957161709568`). That is
  `launch_batch` in hits mode, so it compiles every kernel a production field compiles: top (b62), FD top, bucket,
  join and check, plus the smoke kernel.
- CI's `cubecl_backend::tests::wgsl_dump_for_lint` on lavapipe with `CUBECL_DEBUG_LOG`. It records WGSL (what naga
  gets) for the `gpu` builds, and the SPIR-V disassembly for the `gpu,cubecl-spirv` builds: 14 shaders of 10 kinds,
  including JoinKernel, CheckKernel, TopKernel, TopFdKernel, BucketKernel and the stride kernels.

**CUDA and WGSL comparison** (`scripts/kdiff.py`, as for #251, tightened):
- Each kernel's compilation block is cut to its `source:` part. The kernel-id metadata is dropped: it gains a
  `pf_count: false` line on the branch, which is a key and not code.
- CubeCL's numbered variables are renamed by first use, and declarations are sorted.
- The shared-memory declarations are compared as a set of (array, size) without offsets. CubeCL lays them out in an
  order that varies between two processes of the same binary (shown for #251, CKF RESULTS §7).

**SPIR-V comparison** (`scripts/spvsig.py`):
- CubeCL's SPIR-V orders capabilities, debug names and phi operands differently from process to process. So each
  kernel is compared as a multiset of instructions, with every `%id` replaced, debug instructions dropped and
  workgroup-member offsets blanked.
- Validated on two processes of the same binary (MS vs MS, BS vs BS): every kernel IDENTICAL [M].

**Results [M]** (`ident/cuda_wgsl_compare.txt`, `ident/spirv_compare.txt`):

| runtime | compared | result |
|---|---|---|
| CUDA, b62 1e17 production run, M vs B | bucket, check, join, smoke, top_fd, top | **all IDENTICAL** |
| CUDA, b64 1e17 production run, M vs B | bucket, check, join, smoke, top_fd (b64 compiles no top kernel) | **all IDENTICAL** |
| CUDA in the SPIR-V builds, MS vs BS, b62 and b64 | same | all IDENTICAL (the CUDA runtime does not take the count form) |
| WGSL (naga), lint dump on lavapipe, M vs B | all 10 kinds, 14 shaders | **all IDENTICAL** |
| SPIR-V, lint dump on lavapipe, MS vs BS (two pairs of processes) | 10 kinds | **only JoinKernel DIFFERS**; the other 9 are IDENTICAL |

The SPIR-V JoinKernel changes [M]:
- 2,020 → 1,983 instructions.
- **OpBitCount 2 → 6** (+4).
- Other opcode count changes: OpBitwiseAnd +4, OpNot +4, OpIAdd +2, OpShiftRightLogical +2, OpConstant +1;
  OpLogicalOr −12, OpIEqual −10, OpShiftLeftLogical −10, OpUConvert −8, OpConstantTrue −3, OpConstantFalse −3,
  OpBitwiseOr −2, OpCopyObject −2, OpSelect −2, OpSLessThan −2.

That fits the count form (`(a & !(mask|seen)).count_ones()` on two words) replacing the compare-and-shift form.
The lint dump compiles the join kernel at the bases its test picks (b57 among them, per CI's `--require
JoinKernel@57`); SPIR-V at b62/b64 was not compared separately [A: same code path, comptime by runtime name only].

## 2. Device tests on c53d99f6 [M]

| suite | result | ran / returned early | log |
|---|---|---|---|
| CUDA, every `cubecl_join::tests::cubecl_cuda*` test (B) | **7 passed, 0 failed** (453 s) | ran: `join_matches_the_cpu_reference`, `top_certificates_match_the_lockstep_scan_and_the_cpu`, `top_fd_matches_the_top_kernel`. Returned early (env-gated): `join_matches_the_cpu_join_on_a_dense_field` (run separately below), `join_matches_the_reference_on_a_whole_field`, `join_throughput_fixed_fields`, `top_fd_timing` | `logs/cuda_suite_B.log` |
| CUDA dense compare vs CPU join, b62 1e17, first slice, 8 partitions | **ok**: 170,247,827 join / 10,384,896 prefilter survivors, equal to the CPU join | ran | `logs/dense_b62_B.log` |
| CUDA dense compare, b64 1e17, 8 partitions | **ok**: 697,596,881 / 43,247,716 | ran | `logs/dense_b64_B.log` |
| lavapipe, `gpu,cubecl-spirv` (BS: **count form**, device string `wgpu<spirv>`), every wgpu test of `cubecl_join` | **8 passed, 0 failed** (225 s) | ran: `cubecl_join_matches_the_cpu_reference`, `cubecl_niceonly_keeps_join_and_stride_apart_by_ticket`, `join_sample_runs_partitions_of_a_production_field`, `top_certificates_match_the_lockstep_scan_and_the_cpu`, `top_fd_matches_the_top_kernel`. Returned early: `fx_digits_are_exact_everywhere`, `join_matches_the_reference_on_a_whole_field`, `join_throughput_fixed_fields` | `logs/lvp_BS.log` |
| lavapipe, `gpu` (B: naga, **old form**, `wgpu<wgsl>`), same | **8 passed, 0 failed** (141 s) | same 5 ran, same 3 returned early | `logs/lvp_B.log` |

The dense counts equal those #251's head gave on the same fields and partitions on 2026-11-13 [M, CKF RESULTS §4].
That is expected, since the join's counts do not depend on the check [D]. The branch is on main, which does not yet
have #251's check-count tests, so this suite has 8 wgpu tests, not 10.

## 3. CUDA speed (optional item, one interleaved pair of rounds) [M]

Harness `cubecl_cuda_join_throughput_fixed_fields` at b62 1e17 (`7520566762397899821056`, one field after a 1e14
warm-up), order M B B M (`scripts/speed.sh`), nothing else running.
- **The card did not cool to 40 °C:** at this box's ambient it idled at 51–52 °C. `cool.sh` waited its 5-minute cap
  each time, so every run started at 51–52 °C.
- Power was 278.8–279.0 W (median at the 280 W cap) and the mean SM clock 1,736–1,739 MHz in all four runs.

| run | device s | join kernel (driver JIT) | check kernel |
|---|---|---|---|
| M r1 | 64.991 | 47 regs, no spill | 37 |
| B r1 | 66.756 | **40 regs + 24 B spill (the spill variant)** | 37 |
| B r2 | 65.030 | 46, no spill | 37 |
| M r2 | 64.877 | 46, no spill | 37 |

- Counts were identical in all four runs: 1,097,114,812,011 join and 66,862,268,894 prefilter survivors, 0 found.
- B r1 drew the join kernel's per-process spill variant. That variant cost about 2.4 % in the #251 measurements and
  hits either side at random [M there], so the run is excluded, as there.
- Spill-free, the branch is 65.030 s against main's 64.991 / 64.877 s: **+0.06 % / +0.24 %, CUDA does not move** [M].
  That is expected, since the CUDA kernels are identical (§1) [D].
- Only one spill-free branch run, so this is a check, not a measurement of a small effect.

## Commands (on the box, `W=/root/n21v`)

- Builds: `bash scripts/build.sh br B gpu; … main M gpu; … br BS gpu,cubecl-spirv; … main MS gpu,cubecl-spirv`.
- Identity: `bash scripts/ident.sh B M; bash scripts/ident.sh BS MS`. The second processes for the noise check ran
  `CUBECL_DEBUG_LOG=… bin/MS --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint` (and BS).
- Compare: `python3 scripts/kdiff.py ident/M/<log> ident/B/<log>` and `python3 scripts/spvsig.py ident/MS/wgsl.log
  ident/BS/wgsl.log`.
- CUDA suite: `bash scripts/cuda_suite.sh B` (`bin/B --ignored cubecl_join::tests::cubecl_cuda --test-threads 1`,
  then the dense compare with `NICE_TEST_JOIN_DENSE=8 NICE_TEST_JOIN_DENSE_FIELD=<b>:<start>:100000000000000000`).
- lavapipe: `bash scripts/lvp.sh BS; bash scripts/lvp.sh B` (`bin/<X> --ignored cubecl_join::tests:: --skip cuda`).
- Speed: `bash scripts/speed.sh` (`run.sh` = `cubecl_cuda_join_throughput_fixed_fields`, one 1e14 warm-up field per
  process, then one b62 1e17 field; `ptxjit.py` for the join kernel's register variant).

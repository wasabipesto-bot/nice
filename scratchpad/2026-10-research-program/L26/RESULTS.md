# L26: stride prefilter Metal half-shift fix (2026-10-31)

**Result.**
- **Branch.** `pr/metal-halfshift-prefilter` on the fork, head **`3dcbc9a`**, is one commit on main 472c9a0.
  - It changes `common/src/cubecl_backend.rs` (46+/23-) and adds one CHANGELOG line.
  - The PR is not opened. Its body is `PR-BODY.md`.
- **Exact everywhere tested.** The branch is exact on CUDA (CubeCL runtime) and on lavapipe (wgpu/WGSL).
  - Survivor counts equal main's in every test.
  - The probe-style sweep covers 27 windows at the start, middle and end of every prefilter base with candidates.
- **WGSL.** Flagged sites in the stride nice-only kernel go from 6 to 0 at b30, b34 and b40, both production and probe
  builds. Kernels without a prefilter are unchanged.
- **Lint and host suite.** fmt and clippy (`-D warnings`) are clean. The host suite passes 208 of 208. One parallel run
  hit the known flaky mock-device test that L25 also saw.

## One deviation from the brief, and why

The brief said: start each pass by dividing the top two 16-bit halves as one u32. **Taken literally, at two limbs
(bases 33-40), that divides the u64 form of the same bug.**

- **Why.** In the first pass the top pair is `(v[3] << 16) | v[2]`, built from `w = u32(n_lo >> 32)`. A compiler folds
  `((w >> 16) << 16) | (w & 0xFFFF)` back to `w`, so the dividend becomes `uint(n_lo >> 32) / K`.
- **That is the 2026-10-06 form.** In the M4 repro, `uint(ulong(a)*ulong(b) >> 32) / 3u` was wrong 4095 of 4096
  times, and its outputs equal the low word divided by K: the shift is simply dropped.
- **Why #228 and #225 escape this.** Their pair is a u32 sum produced by the schoolbook multiply, never a u64 high half.
  The prefilter divides n itself, so its pair can be one.

**What the branch does instead.** It still starts each pass with the top pair, but divides it algebraically:
- write hi·2^16 + lo = hi·Q·K + (hi·R + lo), with 2^16 = Q·K + R (comptime);
- the quotient is then hi·Q + (hi·R + lo)/K, and the remainder is (hi·R + lo) - qt·K;
- every dividend is either the sum hi·R + lo, at most (2^16 - 1)·K < 2^32, or `rem << 16 | limb` with a run-time
  remainder;
- later passes take the previous quotient as the pair.

**The stricter scanner.** `analysis/wgsl_scan2.py` follows constant-index array stores and loads, and folds a word
rebuilt from its halves.
- On a synthetic WGSL snippet of the literal pair construction it flags the division as **HI32**
  (`analysis/synth_selftest.out`).
- The branch's sum form passes the same check.
- L25's `wgsl_scan.py` does not see through array loads or rebuilt words, so it would have passed the literal form.

## Model check (on ivory, Python)

`analysis/model.py` (output in `model.out`):
- It models the new division in u32 arithmetic, with every intermediate overflow-checked.
- It compares the result with `[(n // K**r) % K for r in range(p)]`.
- **Coverage.** Every K that `chunk_constants_u16` gives at bases 10-40 (31 values, including the powers of two 4096
  and 32768), limbs 1-4, and p = 1-4.
- **Inputs.** Each K and limb count gets random n plus the edges 0, 1, 2^(32L)-1, K-1, K, K³-1 and K³.
- **Result.** 2,980,464 cases are exact. There is no u32 overflow, and every limb and quotient half is at most 0xFFFF.

## The box

- **Machine.** `nice-research-l26-prefilter`, Vast 58548226: an RTX 3060 (driver 615.71.09), 16 vCPU, 125 GiB, in New
  Brunswick.
- **Toolchain.** Rust 1.99.1, from `rust-toolchain.toml`.
- **Lavapipe.** `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`.
  - With it, `vulkaninfo --summary` lists one device, llvmpipe (LLVM 20.1.2), in `raw/box/vulkaninfo_lvp.txt`.
  - The sweep test prints the CubeCL device as `llvmpipe (LLVM 20.1.2, 256 bits) (Vulkan, wgpu<wgsl>)`.
- **Times (UTC).**
  - First ssh at 15:20.
  - The builds ran 15:22-15:51. The first `cargo` had to download every crate at about 1.3 MB/s, which took 26 min.
  - The tests ran 15:51-16:11.
  - The box was not destroyed, since only `list` and `ssh` are allowed. It self-destroys at about 17:40.
- **Its trees.**
  - `/root/nice` is a clone of the fork, checked out at `3dcbc9a`.
  - `/root/bin/{main,fix}-test{,2}` are the test binaries, and `/root/logs` holds the logs (copied to `raw/box/`).
- **Setup gotcha.** My first ssh that started a `nohup ... &` hung until `timeout` killed it (exit 143). The job did
  start. Later launches used `setsid nohup ... < /dev/null & disown`.

## Commands and outputs

**Builds.** `scripts/build.sh 472c9a0 3dcbc9a` (log `raw/box/build.log`):
- One checkout and one target dir.
- For each tree: check out, append `scripts/l26_local.rs` with the label `L26TREE-main` or `L26TREE-fix`, then run
  `cargo test --release -p nice_common --features gpu --no-run`. Copy the binary to `/root/bin/<tree>-test`, then
  `git checkout --` the file (`git status` stays clean).
- Times: main 13m25s cold, fix 2m47s. No warnings.
- The binaries are verified by label string: `main-test` has main=1 and fix=0, `fix-test` has main=0 and fix=1.

**The box-local module** (`scripts/l26_local.rs`, never committed) holds four tests:
- `l26_stride`: one production `process_niceonly` field at `L26_BASE` and `L26_SIZE`, used for the WGSL dumps.
- `l26_cuda_prefilter_probe` and `l26_cuda_cross_filter`: copies of the two wgpu-only probe tests, on
  `CubeclContext::new_cuda(0)`.
- `l26_{cuda,wgpu}_prefilter_sweep`: probe survivors against the u128 mirror for 1e6 candidates at the start, middle
  and end of every base 10-40 with a prefilter.
  - This needed a second build (`scripts/build2.sh`).
  - The first sweep attempt panicked at b27, which has no stride residues (logs in `raw/box/sweep1/`). The fix skips
    such bases.

**Tests.** `scripts/tests.sh <tree> [cuda|dump|lvp]`. Each runs `<bin> --ignored --nocapture --test-threads 1
--exact <tests>` from `common/`, with `NICE_API_BASE=http://127.0.0.1:9`.

| test | fix CUDA | fix lavapipe | main CUDA | main lavapipe |
|---|---|---|---|---|
| prefilter probe (b30/34/40, 6 lane widths) | pass* | pass | pass* | pass |
| cross filter (b40, b50) | pass* (3 variants each) | pass | pass* | pass |
| `cubecl_{cuda_,}matches_cpu_niceonly` | pass | pass | pass | pass |
| `cubecl_niceonly_finds_69_in_base_10` | not run | pass | not run | pass |
| start/mid/end sweep, 27 windows | pass | pass | pass | pass |

\* These are the local CUDA copies.

**Logs.** `raw/box/{fix,main}/{cuda,lvp}.log` and `raw/box/{fix,main}/sweep_{cuda,wgpu}.log`. The CUDA runtime needed
no `LD_LIBRARY_PATH` change.

**Counts, identical on both trees and both runtimes.**
- **Probe test.** b30: 396 of 159,058 survive. b34: 2,099 of 350,205. b40: 4,472 of 288,591. These are the same counts
  the M4 printed on main.
- **Cross filter (CUDA).** b40: 283 survivors. b50: 30,449. Each holds for compact+plain, compact+plane and plain.
- **Cross filter (lavapipe).** It ran only (compact, no plane) and (plain, no plane); there were no `plane_scoped=true`
  kernels in the WGSL log. That is the test's software-rasterizer branch, more evidence the device was llvmpipe.
- **Sweep.** It reached bases 28, 29, 30, 32 (K = 32768, R = 0), 33, 34, 37, 38 and 40. Bases 27, 35 and 39 have no
  residues. In total 9,675 of 1,475,822 candidates survive, and each window equals the mirror and main.

**What the parity tests do not cover.** `cubecl_matches_cpu_niceonly` and `finds_69` barely touch the prefilter.
- The lavapipe WGSL log shows the kernels it compiled: `pre_limbs=0` at b10, b12 and b25.
- No b40 non-probe kernel was compiled at all: the 5e6 window at b40's range start leaves no range after the MSD
  filter, so nothing launches. The same happened to my first b40 dump at 1e7, so I reran it at 1e9.
- So the probe tests and the sweep are the real exactness check.
- **Correction to `L25/M4-CONFIRM.md`.** It says "b25 and b40 run the prefilter" in that test. In fact b25 has no
  prefilter (`pre_limbs=0`), and b40 launches nothing there.

**WGSL dumps.**
- **Runs.** `tests.sh <tree> dump` covers b30 and b34 at 1e7. `scripts/dump40.sh` covers b40 at 1e9. Both used
  `CUBECL_DEBUG_LOG`, on lavapipe.
- **Scans.**
  - L25's scanner wrote `raw/wgsl_scan_{main,fix}.txt` (split kernels in `raw/wgsl_{main,fix}/`).
  - The stricter one wrote `raw/wgsl_scan2_{main,fix}.txt`.

| kernel (flags) | main: sites (scanner 1 / 2) | fix | const div/rem total, main → fix |
|---|---|---|---|
| b30 production (L=1) | 6 / 6 | 0 / 0 | 76 → 67 |
| b34 production (L=2) | 6 / 6 | 0 / 0 | 88 → 73 |
| b40 production (L=2, 1e9 field) | 6 / 6 | 0 / 0 | 88 → 73 |
| b40 probe, compact and plain (test run) | 6 / 6 each | 0 / 0 | 88 → 73 |
| b30 and b34 probe (test run) | 6 / 6 each | 0 / 0 | 76 → 67, 88 → 73 |

- **Main's sites.** They are the `/` and `%` of the first step of each pass. In the first pass at L = 2, scanner 2
  types the dividend `HI32>>16`, which is `u32(n_lo >> 32) >> 16`.
- **The branch's divisions by K.** By dividend kind, b34:
  - 27 have an ADD dividend: the 24 of the truncated multiply, plus 3 `t = hi·R + lo`.
  - 10 have an OR with a run-time `rem`: 6 prefilter steps and 4 in the full check.
  - None has an OR of a literal zero (`OR0`; main had 6).
  - That is 2L - 1 = 3 divisions per pass, against main's 2L divisions plus 2L remainders.
- **Kernels without a prefilter.** At b10, b12, b25 and b50 (×2) the kernels are byte-identical between trees once the
  `var l_mut_*` declarations are sorted (`raw/wgsl_noprefilter_identity.txt`). Only their order differs.
- **What the WGSL looks like (b34, branch; condensed, one `let` per operation in the dump).** `l_143 = l_142 * u32(26232); l_145 = l_143 + l_144;
  l_146 = l_145 / u32(39304); l_148 = l_145 - l_146 * K; l_151 = l_142 * u32(1) + l_146`. Here Q = 1 and
  R = 65536 - 39304.

**Lint and host suite.** `scripts/lint.sh 3dcbc9a` checks out the clean commit, with no local module.
- `cargo fmt --all --check` gives rc 0.
- `cargo clippy -p nice_common --all-targets --features gpu -- -D warnings` gives rc 0.
  - The first log's `tail` did not show the `Checking nice_common` line.
  - So `scripts/lint2.sh` touched `lib.rs` and reran it, with the full output (`raw/box/lint2.log`):
    `Checking nice_common`, then rc 0.
- **Host suite.** `cargo test --release -p nice_common --features gpu -- --test-threads 8` gave **207 passed, 1
  failed**: `gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field`, at its descriptor
  comparison (`gpu_niceonly.rs:1730`).
  - That test uses `MockDevice`/`MockSink` and never runs a kernel.
  - It is the same parallel-only flake L25 recorded.
- **Rerun** (`scripts/host2.sh`, `raw/box/host2.log`) on the same binary:
  - alone, 3/3 pass;
  - full suite twice, 208/208 each;
  - main's full suite, 208/208.

**Speed.** Not measured, and not needed: the prefilter exists only at bases ≤ 40, where no production work runs. Above
40 the block is compiled out, and the kernels are unchanged, as shown above.

## Not done

- No Apple hardware. The branch has not been run on the M4.
  - The four tests from M4-CONFIRM Test 2 are what to run there.
  - The local CUDA and sweep copies would also run on wgpu/Metal as written (`l26_wgpu_prefilter_sweep`).
- No full `just lint`. Only `nice_common` was checked, with `--features gpu`; not `cubecl-spirv` or other packages.
- The PR is not opened, as instructed. The box was left to self-destruct.

## Files

| path | what |
|---|---|
| `PR-BODY.md` | PR description |
| `analysis/model.py`, `model.out` | integer model of the new division |
| `analysis/wgsl_scan2.py`, `synth_selftest.{log,out}` | stricter WGSL scanner and its self-test |
| `scripts/` | box scripts and the box-local test module |
| `raw/box/` | every box log (`build*`, `{fix,main}/*`, `lint*`, `host*`, `sweep1/`, `vulkaninfo_lvp.txt`, `tests.status`) |
| `raw/wgsl_{main,fix}/`, `raw/wgsl_scan*.txt`, `raw/wgsl_noprefilter_identity.txt` | split WGSL and scans |

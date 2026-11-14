# T26B follow-up: the lavapipe SPIR-V failure of PR #263 (2026-11-14)

Labels: **[M]** measured on the box today, **[R]** read in source or in a dumped module, **[D]** derived, **[A]** assumed.
Box: Vast 60696216 (host Ubuntu 24.04 image, 48 threads, RTX 3080). CI's driver ran in an Ubuntu 26.04 ("resolute")
debootstrap at `/srv/r26`, entered with `chroot` (the container cannot bind-mount, so there is no /proc in it; lavapipe
did not need one): `mesa-vulkan-drivers 26.0.8-1ubuntu0.3`, `vulkaninfo`: "llvmpipe (LLVM 21.1.8, 256 bits)", "Mesa
26.0.8-1ubuntu0.3 (LLVM 21.1.8)", the same as CI. Test binaries were built on the host (rustc 1.100.0) and run in the
chroot. Raw data: `raw/ci/` (scripts, `dump/` = CubeCL compilation logs with the SPIR-V/WGSL/CUDA modules,
`box/` = logs and outputs).

## Cause: (a), a defect in the new account's clear that any Vulkan device on the SPIR-V compiler can hit; survivors are not lost

**What happens [R][M].** `clear_queue_account` (both queues) had unit 0 clear the four shared words with four
`store(0)` at constant indices 0, 1, 2 and 3. In the module CubeCL's direct SPIR-V compiler (`cubecl-spirv` 0.10,
which runs cubecl-opt's full pass pipeline) produces for every variant of `niceonly_kernel` on this branch, **only the
store to word 0 is left** (`raw/ci/stores.py` over `dump/spv_hs.log`, `spv_kh.log`, `spv_kh_faults.log`):

| variant (bec91fdd) | atomic stores into the queue's shared words |
|---|---|
| cube-scoped, every cube size, both rank forms, probe and production | `q_acct[0]` (the clear) and `q_acct[dynamic]` (the in-loop clear of the next iteration's word) |
| plane-scoped, both forms, probe and production (dumped with a test-only knob forcing it on lavapipe) | `q_acct[0]` only |

So words 2 and 3 (the account) and, in the cube-scoped queue, word 1 for its first use start with whatever the
workgroup's memory held:
- **Words 2-3** are only ever added to after the loop and read by unit 0 in the report: their starting garbage is
  reported as "checked N fewer survivors" (word 2) or "low words differ by N" (word 3). The CI values (3401,
  182536111, 128849019 = 0x07AE147B, "differ by 109 / 347") are leftovers of whatever ran before in that memory.
- **Word 1** (cube-scoped): its first use is iteration 1, and unit 0 clears it after barrier 2 of iteration 0, at a
  dynamic index the compiler keeps, so it is correct.

**Survivors are not lost [M].** An investigation build (IS = bec91fdd + a test-only switch that prints the account
error and returns the hits anyway, `raw/ci/add_inv.py`) ran CI's suite in one process with 4 threads: the account
fired in several of the new test's runs (e.g. "checked 96636765 fewer", words `[283, 96636765, 0]`; "low words differ
by 1", words `[283, 0, 1]`), and the same runs' survivor sets were **exact against the host mirror in all 32 runs**
(`is_ci4_1.log`: "32 runs, 0 wrong"; the only failed test there is the fault test, which that switch defeats by
design). The queue itself checks every survivor; only the account misreads.

**Why only some runs, only on Mesa 26, only in the suite [M][D].**
- Alone, the test passed 5 of 5 on Mesa 26.0.8 (`hs_single_*`) [M]: there the kernel's workgroup memory last held its
  own earlier launches, whose account words end at 0 (each cube's queued and checked cancel) [D].
- In one failing suite the fault test failed too (`hs_ci4_2`): with word 2 already nonzero, the duplicate fault is
  reported as "checked N fewer" instead of the "low words differ" message the test expects [D].
- In CI's suite (one process, several test threads, the join and detailed kernels between) it failed in 2 of 3 runs
  here with `--test-threads=4` (3 wrong runs each, among them **a 256-unit run**: "b40 plane=false ballot=true
  cube=256 lanes/range=4: checked 1 fewer"), i.e. as in CI. Cube size does not matter; what matters is what the
  workgroup memory held.
- Older Mesa (25.2.8, LLVM 20.1.2; what my and the reviewer's box ran) runs the same module; it evidently handed
  this kernel memory that was zero there or not reused between pipelines [A: not traced in Mesa]. Mesa 26 reuses it.
- The WGSL compiler keeps all four stores (`dump/wgsl_hw.log`: four `atomicStore(..., 0)`), and naga zero-initialises
  workgroup memory besides; CUDA's compiler (cubecl-cpp) does not run that pass pipeline, and on the RTX 3080 the
  account was zero over 120 production fields and every test [M, T26B]; the fix's CUDA module clears in a loop
  (`dump/cuda_fix.log`). Dumped on this box's RTX 3080: bec91fdd's CUDA `niceonly_kernel` has all four
  `atomicExch(.., 0)` in both queues (`dump/cuda_head.log`, binary HG), so CUDA was never affected.
- **Not the shared-memory allocator.** lavapipe (both 25.2.8 and 26.0.8) advertises
  `VK_KHR_workgroup_memory_explicit_layout`, so cubecl-spirv lays shared memory out at cubecl-opt's offsets, but the
  dumped offsets do not overlap in any variant: cube-scoped production `q_acct` [0,16), `q_lo`/`q_hi` [16,4112) and
  [4112,8208), digit scratch `sv_s` [8208,15376); plane-scoped production `q_acct` [0,16), `sv_s` [16,7184), the queue
  [7184,11280) and [11280,15376). The allocator treats a shared memory as live from its first use to the end (no
  `free` is used), so `q_acct` is live across the whole kernel.

**The smallest kernel [M].** A test-only kernel (`raw/ci/add_mini.py`, binaries MS/MW = bec91fdd + that kernel): one
`SharedMemory<Atomic<u32>>` of 4 words, unit 0 stores at constant indices 0-3, barrier, unit 0 copies the words out.
With values 7, 8, 9, 10 the SPIR-V module has four `OpAtomicStore`s and the device returns `[7, 8, 9, 10]`. With
7, 7, 7, 7 the module has **one** `OpAtomicStore` (index 0) and the device returned `[7, 7, 0, 0]`; the WGSL compiler
emits all four stores in both cases and returns `[7, 7, 7, 7]` (`dump/mini_MS.log`, `mini_MW.log`,
`logs/mini_M*.log`). So cubecl-spirv's optimizer merges atomic stores **of the same value** to different constant
indices into the first one, presumably by numbering the store as an expression of its value and not of its target
[A: the pass was not pinned down; cubecl-opt 0.10's `MergeSameExpressions`/GVN are the candidates]. It is a CubeCL
miscompile worth an upstream issue with this kernel.

## Exposure

- **Production, RADV (RX 9070 XT, `cubecl-spirv`, plane-scoped queue, 256-unit cubes) [D]:** the same module, so the
  same missing clear. Every field of the stride walk would read the account from whatever the workgroup memory held,
  and would fail ("checked N fewer survivors") whenever that is not zero, for example after a join or top kernel ran
  on the same compute unit. No candidate would be lost (the queue is right and nothing is reported for a failed
  field), but fields would fail spuriously: this PR at bec91fdd must not ship to a SPIR-V build. CUDA and WGSL builds
  are not affected.
- **main [M][R]:** main's stride kernel has no atomic shared words (its cube-scoped queue publishes plane totals with
  plain stores at dynamic indices). The join kernels on main were dumped on Mesa 26 (`dump/spv_join.log`): every
  constant-index store into shared memory that the source makes is present (`s_hd[0..3]`, one by `OpCopyMemory`;
  `s_cnt[0]`; `s_cum`/`s_db`); none of them makes two atomic stores of one value at constant indices, the pattern the
  optimizer merges. The detailed kernels' shared histogram is cleared at a runtime index (read in source, not
  dumped). So no kernel on main is known to be exposed; a code search for `.store(` with a constant index on main finds
  only single stores (`s_cnt[0]`, twice, in different kernels).

## Fix: commit `165192ba` on the branch (after bec91fdd, pushed as a fast-forward)

`clear_queue_account` now clears with a runtime index: `i = UNIT_POS_X; while i < 4 { q_acct[i].store(0); i +=
CUBE_DIM_X }` (units 0-3 clear one word each; a cube of fewer than 4 units loops). It does not rely on any optimizer
pass keeping constant-index stores, and its ordering is unchanged (the queue's first cube barrier orders it before
every use). Dumped on Mesa 26 (`dump/spv_fs.log`, `spv_kf.log`): the clear is one `OpAtomicStore` inside a loop over
`UNIT_POS_X`, step `CUBE_DIM_X`, in every variant (cube-scoped: that store and the in-loop one, both at runtime
indices; plane-scoped: that store). Offsets in the fix's production variants, again without overlap: cube-scoped
`sv_s` [0,7168), queue [7168,11264) and [11264,15360), `q_acct` [15360,15376); plane-scoped queue [0,4096) and
[4096,8192), `sv_s` [8192,15360), `q_acct` [15360,15376). No changelog change: the PR's line already describes the
behaviour, and the bug never shipped.

## Runs on Mesa 26.0.8 (the fix: FS = `cubecl-spirv`, FW = `cubecl`)

Before the fix (HS = bec91fdd, `cubecl-spirv`; reproduction):

| run | result | log |
|---|---|---|
| the new test alone, 5 times | 5 × 32 runs exact, account zero | `hs_single_1..5` |
| CI's suite as CI runs it (`--ignored --nocapture cubecl_`, one process), `--test-threads=4`, 3 times | **2 of 3 fail**: 3 wrong runs each (account), incl. one 256-unit run; the fault test failed with them in one | `hs_ci4_1..3` |
| CI's suite with the default thread count (48 here), once, beside another suite | **fails**: 1 wrong run | `HS_suite_ci_x` |
| the same as `hs_ci4` with the account only printed (IS) | survivors exact in all 32 runs while the account fired | `is_ci4_1` |

The fix (FS / FW = the tree of `165192ba`; the box's `fix` tree has the same `cubecl_backend.rs`, md5 9533d225):

| run | result | log |
|---|---|---|
| the new test alone, **20 times in a row**, `cubecl-spirv` | 20 × 32 runs exact, every run's account zero | `FS_single_1..20` |
| the same, `cubecl` (WGSL) | 20 × 32 exact | `FW_single_1..20` |
| CI's first lavapipe step (`--features cubecl`, every ignored test of `nice_common`, one process, default threads) | 36 passed, 0 failed | `FW_suite_ci_1` |
| CI's second step (`--features cubecl-spirv`, `cubecl_`), default threads | 28 passed, 0 failed (the same round's control run of bec91fdd failed) | `FS_suite_ci_1`, `HS_suite_ci_x` |
| the same with `--test-threads=4` | 28 passed | `FS_suite_t4_2` |
| three more of CI's second step: `--test-threads=4`, default, `--test-threads=4` | 28 passed each (so 5 of 5 CI-style `cubecl-spirv` suites pass with the fix; bec91fdd failed 3 of 4 such runs here) | `FS_suite_t4_3`, `FS_suite_ci_4`, `FS_suite_t4_5` |
| `just lint` (`cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`; the same with `--features nice_client/gpu,nice_client/cubecl-spirv`), rustc 1.100.0 | clean (the existing `web-sys` manifest note of `nice-wasm-client` only) | `out/lint.log` |
| CUDA (RTX 3080 on this box, FG = the fix with `gpu`): every `cubecl_cuda_*` test of `cubecl_backend`, each in its own process | all pass; partly filled warps 64 runs exact (both forms); fault test fails the field as designed | `out/cuda.out`, `logs/FG_*` |

Not run: the plane-scoped queue on lavapipe (it cannot run correctly there, see RESULTS §1.3; forced on with a
test-only knob only to dump its module, where its runs fail as before, KH and KF alike); an AMD/RADV device (none);
speed (the change is one clear per cube).

## What changed for CUDA

The kernel's source changed (the clear), so the generated CUDA source of `niceonly_kernel` changed: a loop with one
`atomicExch(.., 0)` instead of four. Re-verified on this box's RTX 3080 (FG = the fix with `gpu`): every CUDA test of
`cubecl_backend`, incl. the partly-filled-warp test with both forms (64 runs, 0 wrong) and the fault test, pass
(`raw/ci/box/out/cuda.out`). Not re-measured: speed (the clear runs once per cube per launch; four lanes instead of
one, no measurable cost expected [A]).

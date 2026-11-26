# Batched reads on the wide path: results (2026-11-26, 08:03–09:19 UTC)

Brief: `BRIEF-READS.md`. Earlier finding: `RESULTS.md` §3. Machine: eventeo's RTX 3060 (nvidia-smi 1, wgpu
`DiscreteGpu(1)`), same rules as before (`env.sh` in every script, nothing reaches the production API, busy loops
killed by recorded PID: `runs/reads-bench/busy.pids`).

## Verdict

**The batched read removes the cliff.** On base 65 through Vulkan/SPIR-V with six busy threads on the host, the
field takes 6.35 fs per admissible n instead of 14.25 (×2.24 faster). That is +2.6 % over the batched build's
quiet run, so the kill criterion (> 30 % still lost) is far from met: the reads were the mechanism. On a quiet host
through Vulkan the change gains 3.1 % (6.381 → 6.191 and 6.172 in two runs). Through CUDA: −0.5 % quiet, −2.5 %
under load. Base 64 forced wide: −0.7 %. Every count is unchanged, every wide test passes through all three runtimes,
and every fault message is identical to the branch point's.

## The change

Branch **`dev/mo-wide-reads`** on the fork, cut from `dev/mo-mode` at `4fff25e7`. It has two commits:

- `457ad99a` "midout: the wide path reads a group's small buffers in one read". `finish_group` collects `cnt` and,
  per ticket, `scount`, `ran`, `tstat` (when present), `stat`, `est`, then the slice's `acc` and `l5n`. It reads
  them all with one `read_async`, shaped like the narrow `finish_group` (the same `hs` / `next()` pattern and the same
  "N buffers read, fewer returned" guard), then runs the same checks in the same order with the same error texts.
  The per-slice loop takes each slice's `acc` and `l5n` from what was read. If `l5n` is missing, it still fails with
  "without its top-hierarchy count".
- `0b6e22e1` "midout: the wide path's missing top-hierarchy count as let-else": clippy's `manual_let_else` on the
  first commit; the behaviour is the same.
- Diff: `common/src/midout/gpu_wide.rs` only, **+45 −12**. There are no kernel changes. `check_slice`, `rank_of`,
  `run_slice` and `nice()` keep their own reads (`run_slice` calls `finish_group` and so gets the batched read).
- Pushed to `fork` only, with no amend or force-push and no pull request. `dev/mo-mode` was not touched.
- **Lint:** `just lint` (fmt check plus both clippy runs, the second with `nice_client/gpu,nice_client/cubecl-spirv`)
  **passes on `0b6e22e1`**, run on ivory (`nice -n 19`, 2 jobs, its own target dir). On `457ad99a` it failed on the
  one `manual_let_else`, which the second commit fixes. The only remaining output is the existing manifest warning
  "unused dependency `web-sys`" of `nice-wasm-client`, which is not an error.

## Verification: tests (RTX 3060; `runs/reads-tests/`, one file per runtime, build and test)

Tests: `cubecl_midout_wide` (the ordinary tier: 3 tests), `midout::gpu_wide::tests::wide_slices_equal_cpu`, and
`midout::gpu_wide::tests::wide_faults_are_loud`. They ran for the branch point (`base`) and the change (`reads`).

| runtime | build | tier (3) | wide_slices_equal_cpu | wide_faults_are_loud | output vs base |
|---|---|---|---|---|---|
| CUDA | reads `457ad99a` / base | ok / ok | ok / ok | ok / ok | identical except a teardown panic in base's tier run (below) |
| Vulkan, WGSL (the CUDA build's wgpu) | reads / base | ok / ok | ok / ok | ok / ok | identical |
| Vulkan, SPIR-V build | reads / base | ok / ok | ok / ok | ok / ok | identical |
| all three | final `0b6e22e1` (CUDA and SPIR-V test builds) | ok ×3 | ok ×3 | ok ×3 | identical to base on all three (CUDA: only base's teardown panic differs); the WGSL tier process exited rc 139 *after* "3 passed" (the same at-exit segfault the SPIR-V benches showed this morning) |

- **Fault messages:** each fault run prints 6 LOUD lines: `F_SKIP_MAIN`, `F_SKIP_TOPS`, `F_DROP_PROBE` and
  `F_DROP_PARENT` through the accounts; `F_BAD_PARENT` and `F_PF_DROP` through the sampled check. All six are
  **byte-identical** between base and reads on every runtime, after stripping timings. Example:
  `F_SKIP_MAIN (2): accounts LOUD: middle-out wide: 0 of 16640 job instances ran`.
- The one difference: base's CUDA tier run printed a `CUDA_ERROR_DEINITIALIZED` panic from a cubecl-cuda thread at
  process teardown, after the tests had passed. It is a teardown race in the runtime and is not in the reads run.
- **Narrow tests once (reads build, CUDA):** `gpu_slices_equal_cpu` ok (35 s), `accounts_faults_are_loud` ok (11 s).
- The devices are named in the outputs: `NVIDIA GeForce RTX 3060 (Vulkan, wgpu<spirv>)`, `(Vulkan, wgpu<wgsl>)`;
  W 32.

## Verification: before and after (base 65 field 77777 after the warm-up field 13731; check off; same session)

Binaries: base = `4fff25e7` (wide bench md5 `fa186085` CUDA, `edacca49` SPIR-V: the same binaries as this morning's
head, since nothing they compile changed); reads = `457ad99a` (`0acba109`, `b79e427b`). The counts of every b65 run
equal `G2/window_1125/out/w65_nc.log`.

| runtime | host | base fs | reads fs | change | base: outside / sync+reads | reads: outside / sync+reads | card util med / ≥ 90 %, power (base → reads) |
|---|---|---|---|---|---|---|---|
| Vulkan/SPIR-V | quiet | 6.3810 | **6.1906**, 6.1716 (2nd run) | **−3.1 %** | 4.04 / 96.80 s | 4.28 / 93.56 s | 91 / 77 %, 161 W → 98 / 99 %, 163 W |
| Vulkan/SPIR-V | 6 busy | 14.2499 | **6.3496** | **×2.24 faster**; reads +2.6 % vs its quiet | 9.81 / 215.39 s | 14.94 / 85.41 s | 31 / 24 %, 90 W → 96 / 91 %, 160 W |
| CUDA | quiet | 6.4490 | 6.4181 | −0.5 % | 17.97 / 83.95 s | 17.99 / 83.44 s | 100 / 99 % → 100 / 100 %, 162 W |
| CUDA | 6 busy | 6.6645 | 6.5000 | −2.5 % | 25.57 / 79.75 s | 24.52 / 78.20 s | 97 / 94 %, 159 W → 100 / 100 %, 162 W |
| CUDA, **b64 wide** (4095, 77777) | quiet | 3.5908 | 3.5661 | −0.7 % (no regression) | 13.24 / 52.47 s | 13.22 / 52.04 s | 99–100 %, 159 W |

- **Kill criterion:** under six busy threads through Vulkan the batched build loses +2.6 % (or +2.9 % against the
  second quiet run), not > 30 %. It is not triggered.
- Through Vulkan the card is now kept busy on a quiet host as well (≥ 90 % busy in 99 % of samples, against 77 %).
  The remaining load sensitivity moved to the queuing side: "outside" is 4.3 → 14.9 s under load. Those launches are
  recorded while the card is still working, so they cost little.
- The base cells repeat this morning's (6.34 / 14.62 then, 6.38 / 14.25 now).

## Step 2 (queue group k + 1 before reading group k): note, not built

**Worth, from the numbers (all upper bounds, since some of the remaining host time already overlaps):**
- Vulkan, quiet: the batched field takes 6.18 fs against 6.106 for `MIDOUT_STOP=5` (every kernel but the check, no
  reads: `RESULTS.md` §3). The check kernel costs ~0.6 % (CUDA), so at most ~0.6 % is left to pipeline.
- Vulkan, 6 busy: 6.35 against 6.11, so at most ~3 %.
- CUDA: the card is power-capped and ≥ 99 % busy, so at most ~0.5 %.
- Narrow b64 under load: 4.9 % through Vulkan (`RESULTS.md` §3). That is the only cell where it is clearly worth
  something.

**What it would take** (both paths have the same synchronous loop in `run_field[_wide]`: queue a group, `sync`, read,
check, queue the next):
- **The ordering primitive exists.** `client.read_async` encodes the copies when it is called. On CUDA it records a
  fence (`cubecl-cuda` `compute/command.rs`); on wgpu, `read_resources` encodes the copies and flushes. Its future
  resolves when that group's work is done, not when later work is. So group k's read is issued right after group k
  is queued, group k + 1 is queued, then the read of k is awaited and checked. `finish_group`'s `sync()` has to go,
  because it would wait for k + 1 too; the batched read now does its job.
- **Per-group handles are already separate:** `cnt` (one `mk` per group), each ticket's `scount`, `ran`, `stat`,
  `est`, and each slice's `tstat`, `acc`, `l5n`. The device scratch shared across slices (`g_rec`, `g_lst`, `out`,
  `slabcnt`, `surv`, `clst`, histograms) is reused in stream order, so k + 1 overwriting it after k is safe (the same
  as consecutive slices within a group today). Cubecl's pool keeps freed handles alive for queued work. Memory: the
  per-slice WSlice buffers (~84 MB per slice at b65 caps: tops lists) of two groups can be alive at once instead of
  one. That should fit 12 GB at group 16, but it has to be checked on a 3 GB card (the GTX 1060 runs b64 today) and
  on the 16 GB AMD card at b65.
- **Accounts:** none change. Each group's checks only read that group's buffers. The `nice_out` / `nice_count` tallies
  are cumulative and read once by `nice()` after the field, which must stay after the last group's read.
- **A failure in group k with k + 1 already queued:** the field fails either way. But the error path must `sync()`
  (drain k + 1) before returning. Otherwise k + 1 can still write `nice_out`/`nice_count` and the shared scratch
  while the caller reuses the join for the next field (the client does; the `nice_before` snapshot would then be
  wrong). The timing-stop path (`stop != 6`) and `run_slice` (tests and the sampled check) keep the plain synchronous
  form.
- **Size:** about 40–60 lines per path. It touches the field loop's control flow and the error path of both drivers.
  The gain is ≤ 0.6 % quiet, ≤ 3 % (wide) / ≤ 5 % (narrow) under host load. **That is not clearly small and safe for
  its value**, so it is not built. Worth doing for the narrow path if demoux's telemetry shows host contention after
  this change ships.

## Not done

- Step 2 (above: a note only).
- Benchmarks of `0b6e22e1` itself: the timings are of `457ad99a`; `0b6e22e1` only rewrites a `match` as `let-else`
  (its tests ran, last table row).
- The at-exit segfaults (rc 139 after results, Vulkan only) and base's CUDA teardown panic: seen, not investigated.
- No pull request, nothing pushed to `dev/mo-mode` or `origin`.

## Energy

eventeo's plug over 08:02–09:19 UTC: **0.254 kWh** (integral; counter 1.26 → 1.51 = 0.25 kWh), mean 196 W, peak
315 W. With this morning's session (0.545 kWh) the day's measurements total about 0.80 kWh, about $0.14.

## eventeo state

- Powered off at 09:18:18 UTC by `off_if_idle.sh`: no bench, test or build processes were running, and nobody but
  `claude` was logged in. ssh from ivory was gone 5 s later (connection timed out on a later re-check). The plug read
  0 W at 09:18:36, as it does right after a shutdown (standby is ~2 W).
- Added there: worktree `~/projects/nice/.worktrees/wide-reads`, target dirs `~/research/t/wide-reads{,-rel}`
  (3.4 GB, warmed by copying the mo-mode ones), binaries `~/research/bin/{reads,base,final}-{cuda,spv}` and
  `rb-{base,reads}-{cuda,spv}`, runs `~/research/runs/reads-*`. The `mo-mode` worktree is now detached at `4fff25e7`.
  One changelog line in `~/SYSTEM_STATE.md`.
- On ivory: worktree `~/projects/nice/.worktrees/mo-wide-reads` (branch `dev/mo-wide-reads`) the lint target dir
  under `~/scratch/wide-reads-lint` was deleted after the run (only its logs are kept, copied to `runs/`).
- Raw logs: `runs/reads-tests/`, `runs/reads-bench/`, `runs/build-logs-reads/` (build logs, fetch, `lint.log` with the
  clippy error on `457ad99a`, `lint2.log` passing). Scripts: `scripts/build_t.sh`, `builds_reads.sh`,
  `tests_reads.sh`, `runs_reads.sh`, `tests_final.sh`.

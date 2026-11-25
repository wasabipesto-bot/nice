# Window 3 on the RX 9070 XT (demoux): the cleaned branch, base 65, the word width (brief, 2026-11-25 03:50 UTC)

You are an engineer running a time-boxed measurement window on a machine that belongs to the project's
maintainer. Work alone (do not start subagents). **The maintainer granted a lease on that machine at about
03:41 UTC for 4 hours. Your hard stop for measurements is 07:05 UTC; cleanup finished and verified by
07:20 UTC; your report by 07:30 UTC.** Order matters: exactness first, then the measurements in the order
below; whatever is not done by 07:05 is reported as not done.

## The machine and its rules (all binding)

- `ssh justin@demoux` (Tailscale; Debian, Ryzen 5 5600X, 12 threads, 125 GB memory, RX 9070 XT on RADV/Vulkan,
  `/tmp` a large tmpfs, rustup at `~/.cargo/bin` with the repository's pinned toolchain installed). This lease
  covers this machine only, for these four tasks only.
- **Before anything else:** check that the maintainer's production client is not running (look for a
  `nice_client` process and at `/sys/class/drm/card*/device/gpu_busy_percent`). **If it is running, or the card
  is busy with something else, stop and report to me at once: never stop, start or touch the production client
  or anything under `/opt/nice`.**
- Work only under `~/claude-exp-2026-11-25-mo` (cargo home and targets inside it or the default rustup; nothing
  else of theirs is written). Every run through `setsid nohup` with its process-group id recorded in a file;
  a watchdog (in `/tmp`, looping `while [ -d <workspace> ]`) that kills the recorded groups and removes the
  workspace at 07:25 UTC whatever happens.
- Kill by recorded PID or group, parent before children. **Never `pkill -f` or `pgrep -f` with a pattern that
  also appears in your own ssh command line** (it matches the Tailscale session and drops it): when you must
  search process lists, build the name from pieces in a shell variable with a bracketed first character, and
  keep the literal string out of the whole command.
- The card's clock follows its load (about 2.85–3.13 GHz and 304 W under these kernels; 1.5–1.9 GHz and under
  100 W for light or bursty work): sample `gpu_busy_percent`, the clock and the power beside every timed run
  (the sampler script exists: see below) and report them; a timing with fewer than 20 busy samples or off the
  operating point is not a result. Warm up with queued work before timing.
- Never use the machine as a timer or for anything after the cleanup. Never contact the production API from it
  (nothing here needs a client that talks to it; the one client run below talks to 127.0.0.1 only).
- At the end: every process of yours gone, the workspace and the watchdog removed, and a check that proves it
  (written so that it cannot match itself). Do **not** send any notification to the maintainer; I report.

## What exists (read these first, quickly; all under `~/projects/nice/scratchpad/2026-10-research-program/` on ivory, this machine)

- `G2/WINDOW-PLAN-2.md`, `G2/build4s/window/` (`env.sh`, `go_mo.sh`, `run_t.sh`, `run_b.sh`, `run_bw.sh`,
  `run_main.sh`, `smp.sh`, `analyze_mo.py`): **the driver of the last window (2026-11-19), which did almost
  exactly this**, and its logs in `G2/build4s/window_1119/`. It was written for the development trunk
  `66259bb0`. Today's code is the cleaned branch **`dev/mo-clean` at `66305ada`** (worktree
  `~/projects/nice/.worktrees/midout-clean`): the card tests are behind the cargo feature `midout-box-tests`,
  the benches behind `midout-bench`, and the library no longer reads a stop variable from the environment
  (`G2/CLEAN-NOTES.md`, the tier table; `G2/build6c/box/card.sh` is the card tier's exact invocation on the
  cleaned head on CUDA). Adapt the driver; do not rewrite it.
- `G2/WIDE2-NOTES.md` (what changed in the wide path on 2026-11-20 and the prediction for this card),
  `CW/RESULTS.md` and `CW/box/` (the word-width microbenchmark: `mo_width_dump`, `mo_width_bench`, on the scratch
  branch `exp/mo-word-width`, head `b3967fb5`, worktree `~/projects/nice/.worktrees/mo-word-width`; its SPIR-V
  path was exact on lavapipe and has never run on a real Vulkan card).
- The design, if a term is unclear: `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §2 and §8.

Code reaches demoux as git bundles made on ivory (no pushes are needed; do not push anything anywhere). Build
on demoux with the features `cubecl-spirv` plus `midout-box-tests` and `midout-bench` for the test binary and
the examples (the last window's build took 2–4 minutes per target with `-j 10`); one target directory per tree;
identify every binary by checksum in the logs.

## The four tasks, in this order

1. **The cleaned branch at base 64 (never run on this card).** (i) Exactness at 64 lanes: the card tier
   (slice parity n for n against the CPU reference, with and without the shared parent lists; the narrow
   fault test; wide parity at bases 40 and 65; the wide fault test) and one whole field with the sampled CPU
   check. A failure here is the result: stop the timing that depends on it and report the logs. (ii) Timing:
   whole fields of the default coordinate, warm, at least two rounds of five fields around production's two
   bracket fields measured by production's own join harness in the same binary and session, exactly as on
   2026-11-19 (then: 0.995 / 1.005 / 0.971 fs per admissible n against 4.762 fs, ×4.79, at 2.82–2.88 GHz and
   303 W). Report fs per admissible n, the ratio, clock and power, and the counts (they must equal the
   2026-11-19 counts for the same fields).
2. **The word width (five to ten minutes of card time; it decides whether an optimisation is built).**
   `mo_width_dump` for the slices the microbenchmark used, then `mo_width_bench` through SPIR-V at widths 64,
   128 and 256 (its variants are listed in `CW/RESULTS.md`), interleaved, counts checked against the dump for
   every instance, enough repetitions to hold the card at its operating point. **The decision rule written in
   advance: unless width 128's word loop is at least ×1.35 faster than width 64's on this card, the idea is
   dropped.** Report ps per pair and the ratio with clock and power for each variant.
3. **Base 65 with the wide kernel as fitted to this card on 2026-11-20** (shared memory under the 12-wave
   threshold; measured 3.02 fs warm here on 2026-11-19; predicted 2.4–3.0): two warm fields after a warm-up,
   with the sampled CPU check on (it is on by default at base 65 now, on 4 threads) and once with it off;
   exactness from task 1's wide parity. Report fs per admissible n and whether the host ever waited for the
   CPU slice.
4. **A stage profile at the operating point, if the bench allows one.** The cumulative timing stops measure the
   light stages (tops, parents) with the card idling, which reads too high. If `midout_bench` (feature
   `midout-bench`) offers a way to keep the card loaded while isolating a stage, use it; otherwise run the
   cumulative stops as before, report them with their clocks, and say plainly which numbers are off the
   operating point. Do not write new kernel code for this today.
5. **Spare, only if 1–3 are complete before 06:40:** the client route against the local coordinator as the
   branch now has it (`scripts/midout_coordinator.py` was changed yesterday and has not met the real client
   since): build `nice_client` with the hidden `--midout-coordinator` flag, a work list of 12 fields
   (`midout_fields`), the coordinator on 127.0.0.1 with `--reissue-after 600`, the client with `--repeat`; then
   `scripts/midout_audit.py` on the state directory (it must exit 0). Kill the client by its recorded PID
   with SIGTERM when the list is done.

## Deliverables (by 07:30 UTC)

1. Raw logs and sampler files copied to `G2/window_1125/` on ivory; the adapted driver scripts beside them.
2. `G2/WINDOW3-RESULTS.md`: per task what ran, the numbers with clock and power, exactness, what was not done
   and why, the verdict on the word width against the rule, and the cleanup proof.
3. A final report to me of at most 25 lines.

If the tooling denies something, do not work around it: note it and report it. If anything about the machine
is not as described (the production client running, the disk nearly full, the toolchain missing), stop and
report rather than improvise.

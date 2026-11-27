# Base 65's next levers on the wide path: tops, then parents (brief, 2026-11-27 06:00 UTC)

You are a GPU engineer (Rust, CubeCL kernels). Work alone (do not start subagents). **Hard stop for card work
11:30 UTC; report by 12:00 UTC** (check `date -u`).

## Why

The "nice" project's redesigned search join (the middle-out join; fork branch `dev/mo-mode`, head `0b6e22e1`,
worktree `~/projects/nice/.worktrees/mo-mode`; design: `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md`)
runs base 64 on a narrow device path (`common/src/midout/gpu.rs`) and bases 65–70 on a wide one (`gpu_wide.rs`).
**Base 65 is about 73 % of the probability still within reach and of the remaining machine time**
(`YIELD/yield.txt`), so the wide path at base 65 is where a gain is worth most. Yesterday's profile on an RTX 3060
(`B65/RESULTS.md` §4, §5; read it first, and `B65/READS-RESULTS.md`): per slice at base 65 through CUDA, tops 2.57 ms
(10.8 %), parents 2.82 (11.9 %), main kernel 13.87 (58 %), expansion 4.40 (18.5 %); total 23.8 ms = 6.37 fs per
admissible n. Two observations to act on:

1. **The tops stage takes the same 2.6 ms per slice on an RTX 3080 as on the RTX 3060** (`G2/BUILD-NOTES-WIDE.md`
   §4) although the 3080 is 1.8 times faster overall, and it runs below the card's power cap. So it is bound by
   something that does not scale with the card: too few threads for the work (the top kernels grid-stride over
   the valid parents with a fixed launch size: `wtops5_kernel`, `wtops1_kernel`, `wscan_kernel`, `wtops2_kernel`,
   `wtdigz_kernel` and their launches in `queue_prep`), a serial dependency, or launch latency. On the fastest
   card in the project (an RX 9070 XT, where a base-65 slice took 11.3 ms) a fixed 2.6 ms would be 23 % of the
   slice. **Find what bounds the tops stage and remove it.**
2. **The narrow path shares its bottom side's depth-8 parent lists across digit 8 (`anc8_kernel` and the field
   driver around it in `gpu.rs`); the wide path does not** (its header's correspondence table says so). Parents
   cost 0.90 ms per slice at base 64 narrow and 1.58 ms at base 64 through the wide path. **Port the sharing.**

Paths below are relative to `~/projects/nice/scratchpad/2026-10-research-program/` on ivory (this machine) unless
they start with `~`.

## The machine: eventeo (the rules are binding; read `README.md` "Machines the program may use", the memory entry
`~/.claude/projects/-home-claude/memory/reference_eventeo_host.md`, and on the machine `~/SYSTEM_STATE.md`)

- FX-6300 (6 slow cores, no AVX2: build there), RTX 3060 12 GB = nvidia-smi index 1 (timing), GTX 1060 3 GB =
  index 0 (free for exactness runs in parallel if useful, but its tests load the CPU: never during a timed run).
  `ssh claude@eventeo`, no sudo, only `/home/claude`. **Off by default:** wake it from ivory with
  `~/.local/bin/wake-eventeo`; at the end run `bash -l ~/research/scripts/off_if_idle.sh` there and confirm from
  ivory that ssh is gone.
- Every script sources `~/research/scripts/env.sh` (closed-port API address, CUDA device order); for Vulkan also
  `env_vulkan.sh` (wgpu adapter of the RTX 3060: `CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)'`). **Nothing may
  contact the production API.** Scripts and logs of the earlier sessions, to reuse: `B65/scripts/` (`build_b65.sh`,
  `run_b65.sh`, `runs_*.sh`, `analyze.py`, `energy.py`) and on eventeo `~/research/b65/`, `~/research/scripts/`.
- Long jobs through `setsid nohup … &`, then poll. Never `pkill -f`/`pgrep -f`; kill only what you started, by
  recorded PID. Cold builds 4–6 minutes each.

## The work, in this order (each step: its own small commits, exactness first, then timing)

Branch **`dev/mo-wide-b65`**, cut from the fork's `dev/mo-mode` (`0b6e22e1`). Pushes to `fork` only; never to
`origin` or to `dev/mo-mode`; never force-push or amend a pushed commit; commit trailer exactly
`Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; no mention of assistants, agents or a research
program in commits or comments. No pull request.

**Step 1, tops (aim: the stage under 1.5 ms per slice at base 65 on the RTX 3060, and scaling with the card).**
First measure, do not guess: with the cumulative timing stops (`MIDOUT_STOP=1` is the tops stage; the device-top
stops 11–15 of the narrow bench show how the narrow path splits its tops; add temporary instrumentation in a
scratch commit if the wide bench has no finer stop) find how the 2.57 ms divides among the top kernels and what
the card does meanwhile (utilisation, power). Then the cheapest change that removes the bound: a launch shape
with more threads, fewer serial steps, or several slices' tops in one launch. Counts and the tops themselves
must be identical (the tests compare device tops with host tops). **Kill: if no variant brings the stage under
2.0 ms per slice, write down what bounds it and go to step 2.**

**Step 2, parents (aim: about −1.2 ms per slice at base 65).** Port the narrow path's sharing of the depth-8 lists
across digit 8 to the wide path's field driver, following the narrow code's structure and its test
(`field_parent_sharing_is_exact_and_loud` in `gpu.rs`: shared = unshared slice by slice, every fault loud): the
wide path needs the same test. Watch card memory at base 65 (the lists of a field are held at once; the narrow
path at base 64 holds 64 lists of 121M roots in all) and say what a 3 GB card would do.
**Kill: if the wide path's parents differ in kind from the narrow path's so that the port is not a port (more
than a day's work), stop and write down why.**

**Step 3, only with time left:** the wide expansion costs 2.58 ms per slice at base 64 against the narrow one's
2.00 for the same records; find the difference in the two expansion kernels and say what closing it takes. A note
is enough.

## Verification for every step (say which runtime each ran on)

- Exactness on the card: `midout::gpu_wide::tests::wide_slices_equal_cpu`, `wide_faults_are_loud` and the
  `cubecl_midout_wide*` tests, through CUDA and through Vulkan (the direct SPIR-V build); fault messages unchanged;
  the narrow tests once at the end (nothing may move there).
- Counts of base-65 fields 13731 and 77777 equal to yesterday's (`B65/runs/`).
- Timing, same session, alternating baseline (`0b6e22e1`) and change, at least two rounds: base 65 through CUDA
  and through Vulkan/SPIR-V (whole field and the stage's stop), base 64 through the wide path once. Card
  utilisation and power beside every run. A gain under 1 % of the field is reported as nothing.
- `cargo fmt` and clippy for the file's feature sets (`just lint` is installed on eventeo; if it does not fit in
  the time, say what ran).

## Deliverables (by 12:00 UTC)

1. `dev/mo-wide-b65` on the fork (every commit compiling and exact; scratch instrumentation not in it).
2. `B65/LEVERS-RESULTS.md`: for the tops stage, the measured split and what bounded it; per step the change, the
   before/after table (ms per slice of the stage, fs per admissible n of the field, both runtimes), the tests;
   memory at base 65 with shared lists; step 3's note; what is not done; the session's energy
   (`B65/scripts/energy.py`); confirmation that eventeo is off. Logs under `B65/runs/`.
3. A final report to me of at most 20 lines. If the tooling denies something or the machine does not wake, do
   not work around it: stop and report.

# G2 on the RX 9070 XT: find the operating-point truth and fix the preparation (brief, 2026-11-18 13:40 UTC)

You are an engineer on the "nice" number search. Work alone (do not start subagents).

## Authorisation and its limits

The project's owner wrote to me today (13:00 UTC): *"You now have a lease on demoux for 4 hours max, use it for
whatever you need and ping me when finished."* demoux is the owner's own desktop with the RX 9070 XT that does
86 % of the search. I am passing that lease to you for this task only:

    ssh justin@demoux        (from ivory; Debian sid, Mesa 26.1.6 RADV, Ryzen 5 5600X 12 threads, 104 GB free)

- **Your hard stop is 16:20 UTC.** A watchdog I installed kills every recorded process group and wipes the
  workspace at 16:50 UTC. The lease ends 17:00.
- Work **only** under `/home/justin/claude-exp-2026-11-18-g2` (`$W`). Never touch `/opt/nice` (the production
  tree), the production client (the owner stopped it; **never start it**), the desktop applications that are
  running, or anything else in that home directory.
- Start any run longer than a few seconds with `setsid nohup …` and write its process-group id to
  `$W/<name>.pgid` (see how `$W/go.pgid` was made), so the watchdog can stop it. Stop things by PID, parent
  before children. **Never use `pgrep -f` or `pkill -f`** over that ssh: the pattern matches the ssh session
  itself and drops it.
- Rust is at `$HOME/.cargo/bin` (not on the non-interactive PATH). The repo pins 1.100.0, installed.
- If the harness refuses your ssh to demoux, stop and tell me. Do not look for another way in.
- Do not delete `$W` at the end; I clean up and report to the owner.

## What exists in `$W` (I built and ran it at 13:05–13:33 UTC)

`src/` (clone of upstream), `wt/` (worktree of local branch `g2-cubecl-local` at `4170a781`, the tuned port),
`wt0/` (`9ff100e6`, the pre-tuning port), `target/`, `target0/`, `bin/g2` (tuned), `bin/g2_pre`, `bin/main`
(nice_common's test binary with `--features gpu,cubecl-spirv`: main's library byte for byte), `data/` (the two
staged base-64 super-units), `scripts/` (the window driver), `out/` (the finished window run; a copy is on
ivory in `G2/port/raw/window_1118/`).

Read first, on ivory under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `WINDOW-PLAN.md` (the
protocol and what the numbers mean), `PORT-NOTES.md` (the port: options, build, pitfalls), `TUNE-RESULTS.md`
(today's offline tuning and its model), and `port/raw/window_1118/go.out` plus the output of
`python3 $W/scripts/analyze_g2.py $W/out 3150 300` on demoux.

## What the window run found

- **Exact on the card at 64 lanes** (the first hardware run of that path): variants A, B and D on the first
  super-unit, A on the second: `ALL CHECKS PASSED`, counts equal in every timing run.
- Main, ten base-64 fields: 597.8 s, **4.707 fs per admissible n**, at 3,107–3,142 MHz and 304 W.
- G2 by the pre-registered formula: **best variant D 1.114 fs + 0.085 = 1.20 fs, ×3.92**; A ×3.79; the
  pre-tuning build P ×2.88. The stop line is ×4.0. The offline model had predicted ×6.4 (×4.4–8.7).
- **But every G2 timing run is off the operating point**: 6–10 samples at ≥ 80 % busy, clock medians
  1,958–2,878 MHz against 3,150, power 148–303 W. The runs are 2–4 s bursts and the card's clock follows load.
- **And the numbers barely move with the clock**: preparation 1.83–1.92 ms in every run (the model said
  0.15–0.45 ms; an RTX 3080 measured 0.70 ms before today's changes), full kernel 3.32 ms (A) / 3.13 ms (D)
  with records and 2.91 / 2.76 ms without, whether the run sampled 1,958 or 2,864 MHz. The model's kernel bound
  is 2.15 ms, 2.9 ms at its central efficiency: the kernel is roughly where the model put it; **the miss is the
  preparation** (5 launches, 0.37 ms each) and possibly a fixed cost per synchronised launch on wgpu / RADV.

Each 0.1 ms is 0.022 fs. With the preparation at 0.4 ms instead of 1.84, D would be about ×5.3.

## What to find out and do, in this order

1. **The fixed cost of a launch on this card.** Time a trivial kernel through the same path (CubeCL, wgpu,
   RADV; same kind of bindings), synchronised after every launch and in queued form (N launches, one
   synchronisation). That number says how much of the 1.84 ms and of the 3.1 ms is latency rather than work.
2. **The preparation.** Per-launch times of its five launches. Does the host read anything back between them?
   Restructure so that the preparation costs what its work costs: fewer launches, no host round trip between
   them, queued directly ahead of the main kernel. Prove it on the card exactly as the window did (records,
   order, class segments and top digits equal to the CPU's; survivor sets equal; both super-units).
3. **A production-like protocol.** A real client would queue many super-units and synchronise rarely, with
   buffers reused. `--burst` exists but creates buffers between launches. Make an honest pipelined
   measurement: K super-units' preparation and kernel queued, one synchronisation, buffers reused, counts
   still checked. Report fs per admissible n for it beside the per-launch protocol, and say which a production
   client would actually see and why.
4. **The operating point.** Make the timed stretch long enough that at least 20 samples sit at ≥ 97 % of
   3,150 MHz and ≥ 270 W, and report the components there. If the kernel's time really does not depend on the
   clock, say what it is bound by.
5. **Re-measure by the window's protocol** with the fixed build (variants A and D, at least four rounds,
   median and minimum), plus the pipelined protocol, and **re-run main's fields 2 and 6 in the same stretch**
   (today 90.83 s and 100.41 s) so the ratio is bracketed in one session. Ratio by the plan's formula
   (main base mean 4.707 fs unless the two fields moved; tops and survivor checks 0.085 fs).
6. Only if time remains: the next largest item the card shows (records cost 0.4 ms of the full kernel).

## Code and git

- Develop **on demoux** in `$W/wt` (2-minute builds, `CARGO_TARGET_DIR=$W/target`,
  `cargo build --release -p nice_common --example g2_cubecl --features cubecl-spirv`). Do not build on ivory:
  its disk has under 5 GB free.
- Commit there with ordinary commits on `g2-cubecl-local` (set `user.name "Claude"` and
  `user.email "noreply@anthropic.com"` in that clone only; trailer
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`). Never amend, rebase or force. **Never push
  anywhere.** Before you stop: `git bundle create` of `4170a781..g2-cubecl-local`, copy it to ivory as
  `G2/port/g2-cubecl-demoux.bundle`, and fast-forward ivory's worktree `~/projects/nice/.worktrees/g2-cubecl`
  to it (it has one uncommitted line in Cargo.lock; leave that).
- Every kept change is exact on the card first. If lavapipe on demoux is easy to select
  (`VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json`), also run the 8-lane check there; if not,
  note that the partial-plane paths of the new code were not re-proven.

## Rules for numbers

- Every time is labelled with the clock and power it was taken at. A ratio mixes only runs from today's
  session on this card.
- Report the pre-registered formula's ratio even if it is below ×4.0. A pipelined ratio is reported beside it,
  never instead of it.
- Do not tune toward a result: if the preparation cannot be made cheap on this card, that is the finding.

## Deliverables (by 16:20 UTC)

1. Raw logs copied to ivory: `G2/port/raw/window_1118b/`.
2. `G2/WINDOW-RESULTS.md`: what the launch costs, what the preparation cost was and is, the table of
   protocols and variants (ms components, fs, clock, power), main's bracket, the ratios, what is exact, what
   is not proven.
3. `PORT-NOTES.md` "Where it stands" updated.
4. A final report to me of at most 35 lines: the two ratios (pre-registered protocol; pipelined), with their
   operating points; what the preparation's 1.84 ms was; what changed in the code; anything that surprised you.

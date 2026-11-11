# N13 brief: the wgpu path on the RX 9070 XT (demoux), 2026-11-11, window ends 16:00 UTC

## Why

demoux, the user's own desktop (RX 9070 XT, RADV, Mesa 26.1.6; Ryzen 5 5600X; wgpu on Vulkan with
CubeCL's SPIR-V compiler), submits about 81 % of the nice-only fields. Every A/B so far ran on
NVIDIA through CUDA, and the last merged batch (#241, #246, #249) delivered ×1.17 on this card
against ×1.37 on CUDA (from its own telemetry). Nobody has profiled or tuned the join here. The
user stopped the production client and granted a window on this machine; each hour of it costs
an hour of the search's main engine, so measure what matters and finish early if you can.

## The machine and its rules (strict: this is the user's desktop, in use)

- `ssh justin@demoux` from ivory. Work ONLY under `W=/tmp/claude-exp-2026-11-11-amd` (tmpfs, 63 GB).
  It already holds: `run.sh` (use `$W/run.sh <command…>` for every build and run: it sets
  `CARGO_HOME=$W/cargo-home`, `CARGO_TARGET_DIR=$W/target`, the PATH, and registers the PID for
  the watchdog), `pids`, `cargo-home/` (a copy of the registry), `src/nice` (a clone of the fork
  with remote `upstream` fetched), `out/`, `bin/`.
- A watchdog wipes `$W` at 16:30 UTC. **Your hard stop is 16:00 UTC**: by then nothing of yours
  runs on demoux and every result is copied to ivory (`N13/raw/`). Copy as you go.
- Never touch `/opt/nice`, `~/.cargo`, `~/.rustup`, the user's processes, sessions, containers or
  packages. No sudo. Do not start the production client. Kill only processes you started, by
  PID, parent before child; never `pkill -f` / `pgrep -f` (over Tailscale SSH a pattern that
  appears in your own command line kills the session). Builds under `nice -n 19` with `-j 8`.
- Toolchains present: stable and 1.99.1 (do not install or update anything). If a crate is
  missing from the copied registry, fetch it into `$W/cargo-home` only.
- Nothing is pushed anywhere from demoux. If you need a patch from ivory, scp it. Push to the
  fork only from ivory and only as new commits or new branch names (never force-push).

## What to measure, in this order (stop where time runs out; A is the must-have)

Build the test binaries the way this card runs in production: wgpu with the SPIR-V compiler
(telemetry says `wgpu<spirv>`; find the feature names in `common/Cargo.toml` and `client/Cargo.toml`
and say exactly what you built). The wgpu harness lives in `cubecl_join`'s tests (`client()` is the
wgpu client); port the list-of-fields throughput harness and the profile switches you used on the
box from fork `exp/b64-profile` (44eee52). Fields: b60 1e16 (the frontier is at ≈ 0.81 of the base;
take 0.55 and 0.85), b62 1e17 (0.35 and 0.55), b64 1e17 and 1e16 at 0.55. First an A/A pair to
learn the noise on this machine (desktop apps are running).

**A. What the open PRs do on this card** (≥ 3 interleaved rounds each, counts identical, exact
against the CPU join on one field per base): main `c0c357a` → #250 `ee30303` → #251 `a97e3d7`
(fork `pr/check-d`) at b62 1e17 and b60 1e16; #250 → #254 `69c514d` (fork `pr/top-fd-base64`) at
b64 1e17 and 1e16. Also seconds per field for main at each field, next to the box's numbers.

**B. Where the time goes on this card** (the profile modes, main's kernels): shares at b62 1e17
and b60 1e16 (top FD, bucket, join base, AND, walk, prefilter, stage, check, setup, other) and
per-operation costs, next to the RTX 3080's (L51, N1, B64). Name what is different here.

**C. Retune on this card** (b62 1e17 and b60 1e16; anything that moves ≥ 3 % gets 3 interleaved
rounds): entries per thread, `TRANSPOSE_MIN`, the AND group, `TOP_CAP`, partitions per launch and
the plan's budget (what `JoinLimits` does this adapter get; what happens with the denser plan
that CUDA uses, `with_vram_budget`, on this 16 GB card), the subgroup size RADV reports and
whether the one-ballot append (`ballot_append`) is on, the per-round plane barrier in the walk
(`walk_sync`, CUDA-only today), the SPIR-V compiler against naga/WGSL, and any wide-u64 switch
that exists. Report the plan (slices, partitions per launch, launches per field) in each case.

**D.** If time remains: the same A/B for b64 with the FD kernel's parameters, or whatever B
points at.

No PR branches in this window: measurements and a ranked list only.

## Deliver

`N13/RESULTS.md` (in `~/projects/nice/scratchpad/2026-10-research-program/N13/`): the A table
(realized gain of each open PR here, with the noise floor), the B shares next to NVIDIA's, the C
table, and a ranked list of levers for this card with measured gains and the size of each change.
Raw logs and scripts under `N13/raw/`. Mark every number measured, derived or assumed.

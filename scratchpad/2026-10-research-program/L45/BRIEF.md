# L45 brief: measurement session on #246 — re-price the lean join and the top scan + fill (2026-11-06 evening)

Read `L44/ROADMAP.md` first (the post-stack budget and items 1 step 0 and 5). Two questions, both
measurement, no prototypes:

A. **Top scan + fill + clipped launches: how much of a b62 1e17 / b60 1e16 field?** The roadmap
   derives ~8.7 % / 7 % from a profile residual and L31's per-kept-top cost; measure it directly.
   Cherry-pick the `NICE_EXP_GPU_PROFILE` phase timers (L36's adapted version: see `L36/RESULTS.md`
   and its raw scripts/commits for the commit ids on the fork; it put the FD kernel and the clipped
   launch in "top") onto #246's head and split "top" into: FD kernel, clipped-block launch,
   `top_scan_kernel`, `top_fill_kernel`. Report seconds and shares at both fields (3 profiled runs
   each; profiled vs unprofiled totals as L1.7 did). Kill for roadmap item 1: scan + fill under 5 %
   of the field.

B. **Re-price the lean join** (roadmap item 5): on #246's head, L37's ablation modes (AND only;
   walk without `walk_pf`; full; per-top AND via `TRANSPOSE_MIN` huge) with the lean prefilter,
   3 interleaved rounds at b62 1e17 and b60 1e16, so the join's base / AND / walk / prefilter /
   stage split is known after #246 (L37's `exp/join-l37-ablate` 64f986c has the switches; port
   them). Then: (i) the stage check every 4 vs every 8 chunks (L37 saw no difference on main; the
   roadmap suspects barrier waits for the ~23 s of unattributed join time — also try a variant
   that checks the stage only at the end of each top batch, exactness permitting: the stage must
   not overflow, so cap by SURV_SH_CAP logic); (ii) time the spill vs no-spill register variants of
   #246's kernel separately (the author saw layout-dependent spills: force each by the shared-array
   order or by `maxrregcount`-style means if CubeCL allows; otherwise record which variant each
   process compiled by dumping the SASS and time ≥ 3 processes of each). Kill: stop at ~3.5 h of
   box time; build nothing.

Box: instance in `vast.py list` named `nice-research-l45-measure` (RTX 3080, 5 h TTL); `python3
vast.py ssh <id>`; wait for `/root/READY`; the clone is of the fork; base = fork
`pr/join-lean-prefilter` f3fb390 (= main 6f060a9 + #241 7832f89 + #246). Work on an experiment
branch `exp/join-l45-measure` on the fork. Exactness is not the point here, but every timed run's
survivor/checked counts must still equal the exact counts (b62 1e17 1,020,844,021,499 /
62,584,252,554; b60 1e16 460,847,952,346 / 30,871,838,404) except for the ablation modes that
drop stages by design (report what they produce instead).

Write `L45/RESULTS.md` (tables, the two kill verdicts, and what the numbers say about roadmap items
1, 4 and 5), raw logs and scripts in `L45/raw/`. Rules as for every box agent: Vast only via
`vast.py`, never create/destroy (say when the box can go); on ivory write only under `L45/`; HTTPS
push fallback with `gh auth token` to the fork only; no live fleet, no PRs, no subagents. Hard stop
15:30 UTC.

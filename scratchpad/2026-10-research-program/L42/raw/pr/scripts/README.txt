L42 PR (pr/cpu-join-fd-tops) raw files.

scripts/l42_ab.rs      harness (public API only; copied into common/examples/ for the build, then removed)
scripts/run_ab.sh      A/B of the harness, main vs PR, 3 rounds, order alternating, load gate <= 2
scripts/run_nicemark.sh NiceMark CPU nice-only (--threads 4 --benchmark-secs 150), 4 rounds
scripts/analyze.py     medians / per-round ratios / counts from ab-runs.txt and nicemark-r*.json

Binaries: <worktree>/target-ab/{main,pr}/{l42_ab,nice_client} (removed at the end with the targets).
main = 6f060a9 (upstream main); pr = branch pr/cpu-join-fd-tops.

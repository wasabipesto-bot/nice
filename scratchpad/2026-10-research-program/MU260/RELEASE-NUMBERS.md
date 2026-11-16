# MU260 task 2: what a release from upstream main `0711b163` would carry, against v3.4.7 (2026-11-16)

No release was made, tagged or proposed. Box: Vast 60886021, RTX 3080 (10 GB), **power limit 300 W** as rented
(nvidia-smi: limit 300 W, card default 340 W, max 375 W; I did not change it), 24 threads. Builds on the box from exact
commits, own worktree and target dir each, `cargo build --release -p nice_client --features gpu,cubecl-cuda`
(`t2/build2.sh`, `t2/builds.txt`): **v3.4.7 = `8bd154bc`** (rustc 1.99.1, its pinned toolchain) md5 d6f3af10;
**main = `0711b163`** (rustc 1.100.0) md5 dbdc834a. Both clean trees.

**Production isolation.** `t2/proof_hosts_block.txt`: `api.`, `data.`, `www.nicenumbers.net` and `nicenumbers.net`
mapped to 127.0.0.1 and ::1 in the box's `/etc/hosts` at 06:04 UTC, before any client was built or run (curl exit 7
for each, github.com 200); re-checked at 06:51 just before the chain. `run_queue.sh` (T28's) refuses to start if a
production host answers or the block is missing; every client got `--api-base http://127.0.0.1:8200` (the stub) and
NiceMark `--api-base http://127.0.0.1:9` (closed: curl exit 7). Nothing claimed from or submitted to production.

(sections below filled from the runs)

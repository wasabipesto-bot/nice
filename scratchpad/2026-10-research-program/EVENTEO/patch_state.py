#!/usr/bin/env python3
"""Apply the 2026-11-26 research-session edits to ~/SYSTEM_STATE.md on eventeo (idempotent)."""
import os, sys
p = os.path.expanduser('~/SYSTEM_STATE.md'); s = open(p).read()
if 'research/' in s and 'primary lease' in s:
    print('already applied'); sys.exit(0)
a = "| Disk | Samsung 840 PRO 256 GB SSD:"
assert s.count(a) == 1
s = s.replace(a, "| PSU | EVGA 750 W G2 (PN 220-G2-0750; owner, 2026-11-26). It only matters if more cards are added, e.g. on a riser: the wall peak with both cards is about 320 W. |\n" + a)
a = "├── projects/nice/        # clone of wasabipesto/nice (origin https, main)"
assert s.count(a) == 1
s = s.replace(a, a + """
│                         # remote `fork` = wasabipesto-bot/nice (https); worktrees under projects/nice/.worktrees/
├── research/             # the nice research program's root on this box (2026-11-26)
│   ├── scripts/          # env.sh (sourced by every script: closed-port NICE_API_BASE, CUDA_DEVICE_ORDER=PCI_BUS_ID),
│   │                     # build_mo.sh BRANCH TAG, run_mo.sh TAG GPU RUN PHASES, off_if_idle.sh, vkprobe.py
│   ├── bin/TAG/          # built binaries by tag      ├── t/     cargo target dirs (safe to delete)
│   ├── logs/TAG/         # build logs                 └── runs/  run outputs by name""")
a = "## OS and system services"
assert s.count(a) == 1
s = s.replace(a, """## Who uses this box (owner, 2026-11-26)

The owner gave the nice research program's director **primary lease**: "you have primary lease on that box as well
and can boot or shutdown whenever you need it, and you can persist whatever you need inside your claude home
directory." Both GPUs are for development and tests. No 24/7 client for now; if that changes it will likely be a
user service under `claude` that the director may stop and resume. The owner may log in between runs.
- Research jobs live under `~/research` and never contact the production API (`scripts/env.sh`).
- **End every job with `bash -l ~/research/scripts/off_if_idle.sh`**: it powers the box off unless someone other
  than `claude` is logged in, a client/build/test is running, a container is up, or `~/research/keep-up` exists.
- Build times, cold (FX-6300, 6 jobs): `nice_common` test binary with the card tier 3 min 45 s, the three midout
  examples 5 min 20 s, `nice_client --features gpu` 6 min 20 s.

""" + a)
a = "*Append an entry whenever you change system state. Format: `YYYY-MM-DD: description`*\n"
assert s.count(a) == 1
i = len(s.rstrip('\n'))
s = s.rstrip('\n') + "\n- 2026-11-26: Research director's first session under the primary lease: WoL from ivory (ssh up in 42 s), created `~/research` (scripts, binaries, runs), added the git remote `fork` and the worktree `projects/nice/.worktrees/mo-mode`, built and ran the middle-out branch on both cards, added the PSU to the hardware table, wrote `off_if_idle.sh`, powered off at the end. Vulkan on the NVIDIA cards still fails before the driver touches `/dev/nvidia*` (traced with cuda-gdb; `strace` and `vulkan-tools` would help).\n"
open(p, 'w').write(s); print('applied')

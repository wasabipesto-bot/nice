import os
p=os.path.expanduser('~/SYSTEM_STATE.md'); s=open(p).read()
old="a container is up, or `~/research/keep-up` exists."
assert s.count(old)==1
s=s.replace(old,"a container is up, or a hold file exists: `~/research/keep-up` or `~/research/keep-up.<job>` (one per job since 2026-11-28; each job removes its own).")
s=s.rstrip('\n')+"\n- 2026-11-28: Director's jobs (research program): `research/scripts/off_if_idle.sh` now honours any `research/keep-up*` hold file, so that jobs can queue behind one another; worktree `projects/nice/.worktrees/v5` (detached at a4fb3543, branch exp/mo-wide-aco of the fork) with target dirs `research/t/{v5,v5-rel}` (safe to delete); binaries `research/bin/v5-*`; runs `research/runs/{b65-group,b65-group2,v5-ab,v5-tests}`; job folders `research/{v5,g2}`.\n"
open(p,'w').write(s)

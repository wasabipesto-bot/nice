#!/bin/sh
# waits for stage 1 to finish, then runs stage 2 (director, 2026-11-12)
until grep -q 'STAGE1_DONE\|BUILD FAILED\|stopped' $W/out/go.out; do sleep 2; done
grep -q STAGE1_DONE $W/out/go.out || { echo 'stage 1 did not finish cleanly'; exit 1; }
exec sh $W/scripts/go_dir2.sh

#!/bin/sh
until grep -q 'STAGE2_DONE\|BUILD FAILED\|did not finish' $W/out/go2.out; do sleep 2; done
grep -q STAGE2_DONE $W/out/go2.out || { echo 'stage 2 did not finish cleanly'; exit 1; }
exec sh $W/scripts/go_dir3.sh

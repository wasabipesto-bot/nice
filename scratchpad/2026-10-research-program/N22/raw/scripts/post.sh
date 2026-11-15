#!/bin/bash
# post.sh (after the timed A/B): (1) builds: X4 = exp/n22-rdna4 c750605e (its host test), WL / WLn / WLd = fork
# exp/n22-walk-lane-spirv 86b7ab0c (the PR-shaped W: one commit on exp/integration-1114, gated to wgpu<spirv>) with
# gpu,cubecl-spirv / gpu / + spirv-dump; (2) host tests of X4; the CUDA suite of X0 (integration 8bcee21, unmodified)
# to see whether the allocation failure is the suite's own; (3) WL: lavapipe 26.0.8 with both compilers, the ACO count
# of its join kernel at b62 and b64, the dense compare on CUDA at b62 and b64; (4) the window scripts dry-run on CUDA.
W=/root/n22; B=$W/bin; L=$W/logs/t; S=$W/scripts
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test RUST_BACKTRACE=1
F62=7520566762397899821056; F64=58557331862957161709568
until grep -q AB_DONE $W/out/ab.out; do sleep 20; done
echo POST_START $(date -u +%T)
cd /root/nice && git fetch -q origin exp/n22-rdna4 exp/n22-walk-lane-spirv
git -C $W/wt/E checkout -q --detach c750605e && git -C $W/wt/E log --oneline -1
[ -d $W/wt/WL ] || git worktree add -q --detach $W/wt/WL origin/exp/n22-walk-lane-spirv; git -C $W/wt/WL log --oneline -1
JOBS=12 bash $S/build.sh E X4 gpu,cubecl-spirv & JOBS=12 bash $S/build.sh WL WL gpu,cubecl-spirv & wait
TSUF=-naga JOBS=12 bash $S/build.sh WL WLn gpu & TSUF=-dump JOBS=12 bash $S/build.sh WL WLd gpu,cubecl-spirv,cubecl/spirv-dump & wait
cd $W/run/g
$B/X4 --test-threads 12 > $L/host_X4.log 2>&1; echo "host X4: $(grep 'test result' $L/host_X4.log | tr '\n' ' ')"
$B/X4 --exact cubecl_join::tests::n22_small_division_and_bit_field_are_exact > $L/host_X4_n22.log 2>&1; echo "host n22 test: $(grep 'test result' $L/host_X4_n22.log)"
( cp $B/WL $B/WLn /srv/r26/root/bin/
  lvp() { chroot /srv/r26 /usr/bin/env -i PATH=/usr/bin:/bin HOME=/root NICE_BUILD_SHA=test LP_NUM_THREADS=4 \
      VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout 5400 /root/bin/$1 --ignored cubecl_join::tests:: \
      --skip cuda --nocapture --test-threads 1 > $L/lvp_$1.log 2>&1
    echo "lavapipe 26.0.8 $1: $(grep 'test result' $L/lvp_$1.log)"; }
  lvp WL & lvp WLn & wait ) > $L/stream_WL.out 2>&1 &
DB=WLd TMO=60 $S/spvdump.sh wl62 1 62 > $W/out/dump_wl62.out 2>&1; python3 -I $S/loops.py $W/spv/wl62/*.aco.txt > $W/spv/wl62/loops.txt
DB=WLd TMO=60 $S/spvdump.sh wl64 1 64 > $W/out/dump_wl64.out 2>&1; python3 -I $S/loops.py $W/spv/wl64/*.aco.txt > $W/spv/wl64/loops.txt
for d in wl62 wl64; do echo "$d $(python3 -I $S/walkcount.py $W/spv/$d/Join*.aco.txt | grep 'round' | head -1)"; done
$B/X0 --ignored cubecl_join::tests::cubecl_cuda --nocapture --test-threads 1 > $L/cuda_X0.log 2>&1; echo "cuda X0 (integration): $(grep 'test result' $L/cuda_X0.log)"
bash $S/dense.sh wl_b62 WL 0 62 $F62 1e17 32
bash $S/dense.sh wl_b64 WL 0 64 $F64 1e17 32
wait; cat $L/stream_WL.out
# window dry run on CUDA, fresh workspace, small fields
DW=/root/win; rm -rf $DW; mkdir -p $DW/scripts $DW/wt; cp $S/window/* $DW/scripts/
git -C /root/nice worktree add -q --detach $DW/wt/X c750605e
W=$DW DEV=cuda SZ62=1e15 SZ64=1e15 JOBS=12 END_AT=$(( $(date +%s) + 1500 )) sh $DW/scripts/go22.sh > $W/out/dry_go22.out 2>&1
python3 -I $DW/scripts/analyze_window.py $DW/out > $W/out/dry_analyze.txt 2>&1
tail -5 $W/out/dry_go22.out; head -30 $W/out/dry_analyze.txt
echo POST_DONE $(date -u +%T)

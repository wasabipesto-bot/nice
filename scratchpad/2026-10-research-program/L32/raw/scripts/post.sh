#!/bin/bash
# After every GPU measurement: spirv build, fmt + clippy, WGSL lint (tail off/on), SPIR-V block counts (tail off/on).
L=/root/pad
until grep -q "ALL DONE" $L/master.out 2>/dev/null; do sleep 15; done
echo "POST start $(date -u +%T)"
/root/build.sh padsrc pad_spirv cubecl-spirv
/root/lint.sh
/root/wgsl.sh off
/root/wgsl.sh tail NICE_EXP_JOIN_TAIL=1
/root/spv.sh off
/root/spv.sh tail NICE_EXP_JOIN_TAIL=1
echo "POST DONE $(date -u +%T)" > $L/post.done

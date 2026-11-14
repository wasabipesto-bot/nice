#!/bin/bash
cd /root/w; rm -rf mini; cp -r head mini; python3 /root/add_mini.py mini/common/src/cubecl_backend.rs || exit 1
nohup bash -c 'until grep -q "HEAD_CUDA_DUMP_DONE\|FAILED" /root/w/build5.out; do sleep 5; done; bash /root/build.sh mini MS cubecl-spirv; bash /root/build.sh mini MW cubecl' > /root/w/build6.out 2>&1 < /dev/null &
echo ok

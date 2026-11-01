#!/bin/bash
# naga (cubecl) and spirv (cubecl-spirv) test binaries, niced, -j 4, while the CUDA exactness runs.
nice -n 10 bash -c 'export CARGO_BUILD_JOBS=4; /root/build.sh exp cubecl; /root/build.sh exp cubecl-spirv' > /root/logs/build_lvp.log 2>&1
touch /root/logs/buildlvp.done

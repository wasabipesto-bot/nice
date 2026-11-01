#!/bin/bash
# All builds, sequential in /root/tgt: test binaries first (exactness can start), then clients, the wgpu test
# binary for the WGSL lint, the two single-PR test binaries and the profiled combined tree.
L=/root/cmb
/root/build.sh main main gpu || exit 1
/root/build.sh both both gpu || exit 1
echo TESTBINS_DONE $(date -u +%T) > $L/testbins.done
/root/buildclient.sh both client_both
/root/buildclient.sh main client_main
echo CLIENTS_DONE $(date -u +%T) > $L/clients.done
/root/build.sh both both_wgpu cubecl
echo WGPU_DONE $(date -u +%T) > $L/wgpu.done
/root/build.sh p235 p235 gpu
/root/build.sh p236 p236 gpu
/root/build.sh prof prof gpu
echo BUILDS_DONE $(date -u +%T) > $L/builds.done

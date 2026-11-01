#!/bin/bash
# Builds, sequential in /root/tgt, after the base (e9cdac4) build: pad (A/B binary), prof (profile + accounting), client, wgpu.
L=/root/pad
until grep -q BUILD_DONE $L/build_base.out 2>/dev/null; do sleep 10; done
/root/build.sh padsrc pad gpu || exit 1
echo PAD_DONE $(date -u +%T) > $L/pad.done
/root/build.sh padprof prof gpu || exit 1
echo PROF_DONE $(date -u +%T) > $L/prof.done
/root/buildclient.sh padsrc client_pad
echo CLIENT_DONE $(date -u +%T) > $L/client.done
/root/build.sh padsrc pad_wgpu cubecl
echo BUILDS_DONE $(date -u +%T) > $L/builds.done

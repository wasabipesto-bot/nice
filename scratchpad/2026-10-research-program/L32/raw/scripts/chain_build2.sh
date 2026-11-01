#!/bin/bash
# The rest of the builds after the prof fix (32 histogram bins): prof, client, wgpu.
L=/root/pad
/root/build.sh padprof prof gpu || exit 1
echo PROF_DONE $(date -u +%T) > $L/prof.done
/root/buildclient.sh padsrc client_pad
echo CLIENT_DONE $(date -u +%T) > $L/client.done
/root/build.sh padsrc pad_wgpu cubecl
echo BUILDS_DONE $(date -u +%T) > $L/builds.done

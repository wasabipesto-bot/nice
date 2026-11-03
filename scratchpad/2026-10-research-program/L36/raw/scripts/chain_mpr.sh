#!/bin/bash
# chain_mpr.sh: after the other builds, main + 2ab1694 (profile) as MPR, for main's phase split.
L=/root/l36/logs
until [ -e $L/builds.done ]; do sleep 10; done
/root/l36/build.sh MP MPR gpu; touch $L/MPR.built

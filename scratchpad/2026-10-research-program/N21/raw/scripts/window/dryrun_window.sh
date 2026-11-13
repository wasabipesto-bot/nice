#!/bin/sh
# dryrun_window.sh (the box): the window end to end in a fresh workspace, as demoux will run it: a clone of the fork
# from GitHub, a stand-in run.sh, setup_window.sh, then go_window.sh with DEV=${DEV:-cuda}, small fields and short lists
# (only the sizes, the lists and DEV differ from the window). DEV=wgpu runs it on lavapipe.
set -e
W=${W:-/root/win}; rm -rf $W; mkdir -p $W/out
git clone -q https://github.com/wasabipesto-bot/nice.git $W/src/nice
cp -r /root/n21/scripts/window $W/scripts
printf '#!/bin/sh\n# stand-in for demoux'"'"'s run.sh (env + PID registry)\n. /root/.cargo/env\nexec "$@"\n' > $W/run.sh; chmod +x $W/run.sh
cd $W && W=$W $W/run.sh sh $W/scripts/setup_window.sh
set +e
W=$W DEV=${DEV:-cuda} JOBS=${JOBS:-8} END_AT=$(( $(date +%s) + ${MINUTES:-30} * 60 )) SZ62=${SZ:-1e16} SZ64=${SZ:-1e16} SZ60=${SZ:-1e15} \
  M62="0 9" M64="0 9" M60="0 9" R62="1 2" R64="1" R60="1" \
  $W/run.sh sh $W/scripts/go_window.sh > $W/out/go.out 2>&1
python3 -I $W/scripts/analyze_window.py $W/out >> $W/out/go.out 2>&1
echo "DRYRUN_DONE $(date -u +%T)" >> $W/out/go.out

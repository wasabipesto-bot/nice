#!/bin/sh
# dryrun_window.sh (the box): the window end to end in a fresh workspace, as demoux will run it: a clone of the fork
# from GitHub, a stand-in run.sh, setup_window.sh, then go_window.sh with DEV=cuda, shortened lists and small fields
# (every step, build and chain; only the lists, sizes and DEV differ from the window).
set -e
W=/root/win; rm -rf $W; mkdir -p $W/out
git clone -q https://github.com/wasabipesto-bot/nice.git $W/src/nice
git -C $W/src/nice remote add upstream https://github.com/wasabipesto/nice.git
cp -r /root/n16/scripts $W/scripts
printf '#!/bin/sh\n# stand-in for demoux'"'"'s run.sh (env + PID registry)\n. /root/.cargo/env\nexec "$@"\n' > $W/run.sh; chmod +x $W/run.sh
cd $W && W=$W $W/run.sh sh $W/scripts/setup_window.sh
set +e
W=$W DEV=cuda JOBS=${JOBS:-8} SZ62=1e14 SZ64=1e14 SZ60=1e14 \
  F62=7520567872397899821056 F64=58557334082957161709568 F60=1447430722114824200908 \
  L62="info d_pf c2" L64="c d_pf" S60="c r_z prof_c" MODES="c tcsc s2" DROUNDS=1 \
  $W/run.sh sh $W/scripts/go_window.sh > $W/out/go.out 2>&1
echo "DRYRUN_DONE $(date -u +%T)" >> $W/out/go.out

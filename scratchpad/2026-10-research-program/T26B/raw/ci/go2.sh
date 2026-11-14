#!/bin/bash
# go2.sh: knob builds (plane-scoped queue forced on lavapipe, for dumping its SPIR-V): KH = head, KF = the fix.
cd /root/w
for t in kh:head kf:fix; do n=${t%%:*}; src=${t##*:}; rm -rf $n; cp -r $src $n; python3 /root/add_knobs.py $n/common/src/cubecl_backend.rs || exit 1; done
nohup bash -c "while pgrep -f 'build.sh fix FG' >/dev/null; do sleep 5; done; bash /root/build.sh kh KH cubecl-spirv; bash /root/build.sh kf KF cubecl-spirv" > /root/w/build4.out 2>&1 < /dev/null &
echo ok

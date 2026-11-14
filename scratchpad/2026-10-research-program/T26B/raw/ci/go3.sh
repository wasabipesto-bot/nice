#!/bin/bash
for p in $(pgrep -f "while pgrep -f"); do [ $p != $$ ] && kill $p; done
nohup bash -c 'until grep -q "built FG\|FAILED FG\|BUILD FAILED" /root/w/build3.out; do sleep 5; done; bash /root/build.sh kh KH cubecl-spirv; bash /root/build.sh kf KF cubecl-spirv' > /root/w/build4.out 2>&1 < /dev/null &
echo ok

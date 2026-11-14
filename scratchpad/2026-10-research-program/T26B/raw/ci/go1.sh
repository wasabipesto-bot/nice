#!/bin/bash
cd /root
nohup bash -c "bash /root/build.sh fix FS cubecl-spirv; bash /root/build.sh fix FW cubecl; bash /root/build.sh fix FG gpu" > /root/w/build3.out 2>&1 < /dev/null &
TMO=2400 XENV=NICE_TEST_ACCOUNT_WARN=1 nohup bash /root/t.sh is_ci4_1 IS --ignored --nocapture cubecl_ --test-threads=4 > /root/w/is_ci4.out 2>&1 < /dev/null &
echo started

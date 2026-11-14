#!/bin/bash
cd /root/w; [ -d main ] || (git clone -q head main && cd main && git checkout -q 54d0aac4)
nohup bash -c 'until grep -q "built MW\|FAILED" /root/w/build6.out; do sleep 5; done; bash /root/build.sh main MAS cubecl-spirv' > /root/w/build7.out 2>&1 < /dev/null &
printf "[compilation.logger]\nlevel = \"full\"\nfile = \"/root/spv_kh_faults.log\"\n" > /srv/r26/cubecl.toml
XENV="NICE_TEST_QUEUE_PLANE_ANYWAY=1" bash /root/t.sh kh_faults_dump KH --ignored --exact cubecl_backend::tests::cubecl_queue_faults_fail_the_field --nocapture --test-threads=1
rm /srv/r26/cubecl.toml
git -C /root/w/main log --oneline -1

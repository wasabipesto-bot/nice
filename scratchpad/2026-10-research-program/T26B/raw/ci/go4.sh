#!/bin/bash
nohup bash -c 'until grep -q "built KF\|FAILED" /root/w/build4.out; do sleep 5; done; bash /root/build.sh head HG gpu; cd /root/w/cudadump && printf "[compilation.logger]\nlevel = \"full\"\nfile = \"/root/w/cudadump/cuda_head.log\"\n" > cubecl.toml && NICE_BUILD_SHA=test timeout 600 /srv/r26/root/bin/HG --ignored --exact cubecl_backend::tests::cubecl_cuda_queue_faults_fail_the_field --nocapture > run_head.out 2>&1; rm -f cubecl.toml; echo HEAD_CUDA_DUMP_DONE' > /root/w/build5.out 2>&1 < /dev/null &
echo ok

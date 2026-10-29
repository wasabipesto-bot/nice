#!/bin/bash
source ~/.cargo/env
while kill -0 27448 2>/dev/null; do sleep 3; done
eval "$(sed -n "/^build() {/,/^}/p" /root/setup.sh)"
build pr b 10 >> /root/ab/chain2.log 2>&1
echo "pr: md5=$(md5sum < /root/bins/pr/nice_common_test | cut -c1-8) prune-log=$(grep -c "bottom prefixes" /root/bins/pr/nice_common_test) exp-knob=$(grep -c NICE_EXP_SURV_FLUSH /root/bins/pr/nice_common_test)" >> /root/ab/chain2.log

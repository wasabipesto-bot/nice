#!/bin/bash
source ~/.cargo/env
eval "$(sed -n "/^build() {/,/^}/p" /root/setup.sh)"
xb() { cd /root/$1 && CARGO_TARGET_DIR=/root/tgt_$2 find common client -name "*.rs" -exec touch {} + && CARGO_TARGET_DIR=/root/tgt_$2 cargo clean -q --release -p nice_common -p nice_client && build $1 $2 10; }
xb xmain a & xb xpr b & wait
for t in main pr xmain xpr; do
  echo "$t: SURV_FLUSH-knob=$(grep -c NICE_EXP_SURV_FLUSH /root/bins/$t/nice_common_test) prune-log=$(grep -c "keeps .* bottom prefixes\|bottom prefixes" /root/bins/$t/nice_common_test) dense-field-knob=$(grep -c NICE_TEST_JOIN_DENSE_FIELD /root/bins/$t/nice_common_test) md5=$(md5sum < /root/bins/$t/nice_common_test | cut -c1-8)"
done
echo XBUILD_DONE $(date -u +%T)

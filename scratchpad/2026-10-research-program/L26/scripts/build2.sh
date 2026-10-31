#!/bin/bash
# build2.sh <main sha> <fix sha>: rebuild both trees' test binaries with the
# extended local module (adds the start/mid/end prefilter sweep).
sed -i "/SWEEP_DONE/d" /root/logs/tests.status
source /root/.cargo/env
MAIN=$1; FIX=$2
cd /root/nice
{ for tree in fix main; do
    if [ $tree = main ]; then rev=$MAIN; else rev=$FIX; fi
    git checkout -q -f $rev && git log --oneline -1
    sed "s/L26TREE/L26TREE-$tree/" /root/l26_local.rs >> common/src/cubecl_backend.rs
    s=$(date +%s)
    cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning|Finished"
    T=$(ls -t target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
    cp $T /root/bin/$tree-test2
    echo "$tree: -> /root/bin/$tree-test2 ($(( $(date +%s) - s )) s); labels: main=$(grep -c L26TREE-main /root/bin/$tree-test2) fix=$(grep -c L26TREE-fix /root/bin/$tree-test2)"
    git checkout -q -- common/src/cubecl_backend.rs
    git status --short
  done
  cd /root/nice/common
  export NICE_API_BASE=http://127.0.0.1:9
  for tree in fix main; do
    for dev in cuda wgpu; do
      s=$(date +%s); echo "== $tree $dev $(date -u +%T)"
      if [ $dev = wgpu ]; then E="VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json"; else E="X=1"; fi
      env $E /root/bin/$tree-test2 cubecl_backend::l26_local::l26_${dev}_prefilter_sweep --ignored --exact --nocapture --test-threads 1 > /root/logs/$tree/sweep_$dev.log 2>&1
      echo "rc=$? secs=$(( $(date +%s) - s ))"; tail -3 /root/logs/$tree/sweep_$dev.log
    done
  done
  date -u; } > /root/logs/build2.log 2>&1
echo "SWEEP_DONE $(date -u +%T)" >> /root/logs/tests.status

#!/bin/bash
# NiceMark nice-only, interleaved main pr ept2 (pr/join-ept-2) x 3 (run under nohup).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

for r in 1 2 3; do
  for t in main pr ept2; do
    case $t in
      main) dir=main; envs="";;
      pr)   dir=pr;   envs="";;
      ept2) dir=ept2; envs="";;
    esac
    cd /root/$dir
    echo "== $(date -u +%T) round=$r tree=$t commit=$(git rev-parse --short HEAD) $envs"
    env $envs RUST_LOG=info /root/bins/$dir/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json \
      < /dev/null > /root/ab/nm_r${r}_$t.json 2> /root/ab/nm_r${r}_$t.err
    echo "exit $? $(date -u +%T)"
  done
done
echo NM_DONE $(date -u +%T)

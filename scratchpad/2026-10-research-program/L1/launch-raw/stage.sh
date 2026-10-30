#!/bin/bash
# stage.sh TREE NAME: copy TREE's freshly built test binary and client to /root/bin/NAME
set -e
T=/root/$1/target/release
mkdir -p /root/bin/$2
TB=$(grep -o 'Executable unittests src/lib.rs (target/release/deps/nice_common-[0-9a-f]*)' /root/logs/build_$1_test.log | tail -1 | sed 's/.*(target\/release\/deps\///; s/)//')
cp $T/deps/$TB /root/bin/$2/nice_common_test
cp $T/nice_client /root/bin/$2/nice_client
md5sum /root/bin/$2/* > /root/bin/$2/md5.txt
cat /root/bin/$2/md5.txt

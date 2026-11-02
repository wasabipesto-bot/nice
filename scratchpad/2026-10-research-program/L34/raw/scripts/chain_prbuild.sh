#!/bin/bash
# PR builds at nice 19 (beside the gate screen, which runs at normal priority): PR tree with TRANSPOSE_MIN=256 (P256),
# #236's head fb05597 (B236), their clients.
L=/root/l34/logs; S=/root/l34
for t in P256:PR256 B236:B236; do d=${t%%:*}; a=${t##*:}; rm -rf /root/l34/src/$d; mkdir -p /root/l34/src/$d; tar xzf /root/l34/$a.tgz -C /root/l34/src/$d; done
J=4 nice -n 19 $S/build.sh P256 P256 gpu || exit 1
J=4 nice -n 19 $S/build.sh B236 B236 gpu || exit 1
echo PB1_DONE $(date -u +%T) > $L/pb1.done
J=4 nice -n 19 $S/buildclient.sh P256 client_P256 || exit 1
J=4 nice -n 19 $S/buildclient.sh B236 client_B236 || exit 1
echo PB2_DONE $(date -u +%T) > $L/pb2.done

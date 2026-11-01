#!/bin/bash
# main's test binary first (compiles every dependency), then seed three more target dirs from it and build
# the rest in four parallel streams (each release link is a single-threaded LTO).
L=/root/sc; B=/root/buildtree.sh
J=12 $B main test || exit 1
for t in p235 p236 both; do rm -rf /root/tgt_$t; cp -a /root/tgt_main /root/tgt_$t; done
du -sh /root/tgt_main > $L/tgt_size.txt; df -h /root >> $L/tgt_size.txt
( J=4 $B both test && echo TESTBINS_BOTH $(date -u +%T) > $L/testbin_both.done && J=4 $B both client ) > $L/stream_both.out 2>&1 &
( J=4 $B p235 test && J=4 $B p235 client ) > $L/stream_p235.out 2>&1 &
( J=4 $B p236 test && J=4 $B p236 client ) > $L/stream_p236.out 2>&1 &
( J=4 $B main client ) > $L/stream_main.out 2>&1 &
wait
cat $L/stream_*.out
for b in main p235 p236 both client_main client_p235 client_p236 client_both; do test -x $L/$b || { echo "MISSING $b"; exit 1; }; done
# provenance: each test binary carries its PR's test strings and not the other's
for b in main p235 p236 both; do
  echo "$b md5=$(md5sum $L/$b | cut -c1-8) cert235=$(grep -c 'the kept case or the carry is barely tested' $L/$b) pf236=$(grep -c 'join or prefilter survivors differ' $L/$b) terms236=$(grep -c 'its terms exceed 18 bits' $L/$b)"
done > $L/provenance.txt
for b in client_main client_p235 client_p236 client_both; do
  echo "$b md5=$(md5sum $L/$b | cut -c1-8) terms236=$(grep -c 'its terms exceed 18 bits' $L/$b)"
done >> $L/provenance.txt
cat $L/provenance.txt
echo BUILDS_DONE $(date -u +%T) > $L/builds.done

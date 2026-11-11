#!/bin/bash
# after_B.sh: after chain_B: base-mean rounds 2 and 3 of b64 1e17 (M and S), then a second round of the 1e16 tiles.
cd /root/b64; L=logs
until grep -q B_DONE logs/chain_B.out 2>/dev/null; do sleep 15; done
[ -e logs/stop ] && exit 0
cat > /root/b64/scripts/chain_X.sh <<'EOX'
#!/bin/bash
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
echo X_START $(date -u +%T)
for r in 2 3; do
  if [ $((r % 2)) = 1 ]; then T="M S"; else T="S M"; fi
  for t in $T; do
    [ -e $L/stop ] && exit 0
    export NICE_TEST_JOIN_LIST=$L64; n=a_${t}_b64_1e17_r$r
    $R $n $t 64 10 1e17; bash /root/b64/scripts/jit.sh $n
    echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
  done
done
echo X_DONE $(date -u +%T)
EOX
bash /root/b64/scripts/chain_X.sh > logs/chain_X.out 2>&1

#!/bin/bash
# negative runs, one per guard; each: fresh coordinator state, then the client; records rc, claims, submissions. $1 = run tag
set -u
B=/root/mo/bin; R=/root/mo/runs/$1; mkdir -p $R; source /root/mo/guard.sh $R
S=$R/summary.txt; : > $S
$B/midout_fields --base 64 --t 1000,2000,3000 > $R/w3.json || exit 1
coord() { # tag port extra-args...
  local tag=$1 port=$2; shift 2
  mkdir -p $R/$tag; python3 /root/mc/scripts/midout_coordinator.py --worklist ${W:-$R/w3.json} --state $R/$tag/state --port $port "$@" 2> $R/$tag/coord.log & echo $! > $R/$tag/coord.pid; sleep 1
}
endcase() { # tag rc
  local tag=$1 rc=$2 port=$3
  local st=$(curl -s http://127.0.0.1:$port/status)
  local acc=$(grep -c '"accepted": true' $R/$tag/state/submissions.jsonl 2>/dev/null); acc=${acc:-0}
  local subs=$(cat $R/$tag/state/submissions.jsonl 2>/dev/null | wc -l)
  kill $(cat $R/$tag/coord.pid) 2>/dev/null; sleep 0.5
  echo "CASE $tag: client rc=$rc; coordinator $st; submissions $subs, accepted $acc; reason: $(grep -h -m1 -iE 'refus|not submitted|panicked|Error' $R/$tag/client*.log | head -c 400)" | tee -a $S
}
case_route() { # tag port env-fault binary
  local tag=$1 port=$2 fault=$3 bin=$4
  coord $tag $port
  NICE_MIDOUT_FAULT=$fault $B/$bin niceonly --midout-coordinator http://127.0.0.1:$port --repeat --username mo-neg-local > $R/$tag/client.log 2>&1; local rc=$?
  endcase $tag $rc $port
}
# 1. the production API is refused (no coordinator; hosts are mapped to loopback anyway)
mkdir -p $R/prod; rcs=""
for u in https://api.nicenumbers.net http://API.nicenumbers.net.:8471 https://nicenumbers.net/; do
  $B/nice_mo niceonly --midout-coordinator $u >> $R/prod/client.log 2>&1; rcs="$rcs $u:rc=$?"
done
echo "CASE prod: $rcs; reason: $(grep -m1 -i refus $R/prod/client.log)" | tee -a $S
# 2. the ordinary routes refuse a marked field (coordinator test switch --legacy-path hands marked fields to the ordinary paths)
coord legacy 8472 --legacy-path --reissue-after 0
for m in "niceonly --gpu" "niceonly --threads 4" "detailed --threads 4" "detailed --gpu"; do
  $B/nice_mo $m --api-base http://127.0.0.1:8472 --no-progress --username mo-neg-local >> $R/legacy/client.log 2>&1; rcs="$m:rc=$?"
  echo "  legacy $rcs" | tee -a $S
done
endcase legacy 0 8472
# 2b. a plain coordinator gives an ordinary client nothing (404)
coord plain404 8473
$B/nice_mo niceonly --gpu --api-base http://127.0.0.1:8473 --no-progress > $R/plain404/client.log 2>&1; endcase plain404 $? 8473
# 3-5. accounts fail, sampled check fails, a runtime-thread panic
case_route accounts 8474 accounts nice_mo_fault
case_route sample 8475 sample nice_mo_fault
case_route panic 8476 panic nice_mo_fault
# 6. a memory hog holds all but 2100 MiB of the card before the client starts (the release binary, no switch)
mkdir -p $R/hog; $B/hog 2100 > $R/hog/hog.log 2>&1 & HP=$!; sleep 4; nvidia-smi --query-gpu=memory.used,memory.total --format=csv >> $R/hog/hog.log
case_route hog 8477 "" nice_mo
kill $HP; sleep 2
# 7. claims that fail the client's checks: misaligned, wrong range_size (the release binary)
python3 - $R/w3.json $R/wbad.json <<'PY'
import json,sys
w=json.load(open(sys.argv[1])); a=dict(w[0]); a["range_start"]+=1; a["range_end"]+=1; b=dict(w[1]); b["range_size"]-=1
json.dump([a],open(sys.argv[2],"w")); json.dump([b],open(sys.argv[2]+".2","w"))
PY
W=$R/wbad.json case_route misaligned 8478 "" nice_mo
W=$R/wbad.json.2 case_route badsize 8479 "" nice_mo
echo NEG-DONE >> $S

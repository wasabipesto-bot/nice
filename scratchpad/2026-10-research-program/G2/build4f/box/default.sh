#!/bin/bash
# the default client's routes, unchanged: the branch's binary and the trunk's on the same stub fields; $1 = run tag
set -u
B=/root/mo/bin; R=/root/mo/runs/$1; mkdir -p $R; source /root/mo/guard.sh $R
md5sum $B/nice_mo $B/nice_trunk > $R/bins.txt
P=8490
for bin in nice_trunk nice_mo; do
  for c in "a q64small.json niceonly --gpu" "b qs1.json niceonly --gpu" "c qempty.json niceonly --threads 4" "d qempty.json detailed --threads 4" "e qempty.json detailed --gpu"; do
    set -- $c; tag=$1; q=$2; shift 2
    OUT=$R/${bin}_$tag.jsonl; : > $OUT
    python3 /root/mo/stub_api2.py $P /root/mo/$q $OUT 2> $R/${bin}_${tag}_stub.log & SP=$!; sleep 1
    $B/$bin "$@" --api-base http://127.0.0.1:$P --telemetry --no-progress --username mo-default-local > $R/${bin}_$tag.log 2>&1; echo "$bin $tag ($*): rc=$?" >> $R/run.log
    kill $SP; P=$((P+1)); sleep 0.5
  done
done
python3 - $R <<'PY' >> $R/run.log
import json,sys,glob
R=sys.argv[1]
def key(d):
    t=d.get("telemetry") or {}; p=t.get("pipeline") or {}; j=p.get("join") or {}
    return dict(claim=d["claim_id"], nice=d["nice_numbers"], dist=d["unique_distribution"], route=p.get("route"),
                surv=j.get("survivors"), checked=j.get("checked"), valid=p.get("valid_numbers"))
for tag in "abcde":
    a=[key(json.loads(l)) for l in open(f"{R}/nice_trunk_{tag}.jsonl")]
    b=[key(json.loads(l)) for l in open(f"{R}/nice_mo_{tag}.jsonl")]
    print("COMPARE", tag, "EQUAL" if a==b and a else "DIFFER", a if a!=b else (a[0] if a else None), "" if a==b else b)
PY
cat $R/run.log

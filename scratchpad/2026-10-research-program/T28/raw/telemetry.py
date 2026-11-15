#!/usr/bin/env python3
"""T2.8 task 4: telemetry facts from the census (fields_b62.json, subs_0615.json, predict_instant.json)."""
import json, collections, statistics as st
from datetime import datetime, timezone
F = {f['id']: f for f in json.load(open('fields_b62.json'))}
S = [s for s in json.load(open('subs_0615.json')) if s['field_id'] in F]
P = {int(k): v for k, v in json.load(open('predict_instant.json')).items()}
ts = lambda x: datetime.fromisoformat(x).astimezone(timezone.utc)
def q(v, p): v = sorted(v); return v[min(len(v) - 1, int(p * len(v)))]
def dist(v): return dict(n=len(v), min=round(min(v), 2), p10=round(q(v, .1), 2), med=round(q(v, .5), 2), p90=round(q(v, .9), 2), max=round(max(v), 2), mean=round(st.mean(v), 2))
real = [s for s in S if (s['join'] or {}).get('survivors')]
inst = [s for s in S if not (s['join'] or {}).get('survivors')]
t0 = min(ts(s['submit_time']) for s in S); t1 = max(ts(s['submit_time']) for s in S)
print("submissions", len(S), "first", t0, "last", t1)
for key in sorted({(s['username'], (s['build'] or '')[:8], s['gpu']) for s in S}):
    R = [s for s in real if (s['username'], (s['build'] or '')[:8], s['gpu']) == key]
    I = [s for s in inst if (s['username'], (s['build'] or '')[:8], s['gpu']) == key]
    print("\n==", key, "real", len(R), "instant", len(I))
    if not R: continue
    j = lambda k: [float(s['join'][k]) for s in R]
    print(" run_secs", dist(j('run_secs'))); print(" setup_secs", dist(j('setup_secs')))
    print(" elapsed_secs", dist([float(s['elapsed_secs']) for s in R]))
    print(" slices", collections.Counter(s['join']['slices'] for s in R), "slots", collections.Counter(s['join']['slots'] for s in R),
          "min_slots", collections.Counter(s['join']['min_slots'] for s in R), "retried>0", sum(1 for s in R if s['join']['retried_partitions']))
    # fields per hour (real) by UTC hour
    h = collections.Counter(ts(s['submit_time']).strftime('%H') for s in R)
    print(" real per UTC hour", dict(sorted(h.items())))
    rt = sorted(ts(s['submit_time']) for s in R)
    if len(rt) > 1:
        # steady-state rate over the last 3 hours of data
        cut = t1.timestamp() - 3 * 3600
        n3 = sum(1 for x in rt if x.timestamp() >= cut)
        print(" real fields/h last 3 h", round(n3 / 3, 1))
# frontier vs time: max field id among submissions and claims by hour
print("\nfrontier (max claimed id by last_claim_time, max submitted id) per hour:")
claims = sorted((ts(f['last_claim_time']), f['id']) for f in F.values() if f['last_claim_time'])
subs_t = sorted((ts(s['submit_time']), s['field_id']) for s in S)
hrs = sorted({x[0].replace(minute=0, second=0, microsecond=0) for x in claims})
for h in hrs + [hrs[-1].replace(hour=(hrs[-1].hour + 1) % 24)]:
    mc = max((i for t, i in claims if t < h), default=None); ms = max((i for t, i in subs_t if t < h), default=None)
    print(" ", h.strftime('%m-%dT%H:%M'), mc, ms, (mc - 207064110 + 1) if mc else None)
fr = max(f['id'] for f in F.values() if f['last_claim_time'])
claimed = [f for f in F.values() if f['last_claim_time']]
print("frontier", fr, "claimed", len(claimed), "check_level 1", sum(1 for f in F.values() if f['check_level'] == 1),
      "claimed but unsubmitted", sorted(f['id'] for f in claimed if f['id'] not in {s['field_id'] for s in S})[:20])
bnd = 207072495
beyond = [i for i in range(bnd, fr + 1)]
sub_ids = {s['field_id'] for s in S}; inst_ids = {s['field_id'] for s in inst}
b_sub = [i for i in beyond if i in sub_ids]
print("beyond boundary: fields", len(beyond), "submitted", len(b_sub), "instant", sum(1 for i in b_sub if i in inst_ids),
      "frac", round(sum(1 for i in b_sub if i in inst_ids) / len(b_sub), 3))
agree = collections.Counter(((i in inst_ids), bool(P[i])) for i in b_sub)
print("client instant vs field-level predictor (client_instant, predicted_empty):", agree)
rem = [i for i in F if i > fr]
rem_real = sum(1 for i in rem if not P[i])
print("remaining fields", len(rem), "predicted real (field-level cert passes)", rem_real, "predicted instant", len(rem) - rem_real)
unsub = [i for i in F if i <= fr and i not in sub_ids]
print("claimed/below frontier without submission", len(unsub))

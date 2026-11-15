#!/usr/bin/env python3
"""T2.8 task 4: new (first-time) real and instant base-62 fields per UTC hour, duplicates, processed frontier, estimate."""
import json, collections
from datetime import datetime, timezone, timedelta
F = {f['id']: f for f in json.load(open('fields_b62_0900.json'))}
S = sorted([s for s in json.load(open('subs_merged.json')) if s['field_id'] in F], key=lambda s: s['submit_time'])
P = {int(k): v for k, v in json.load(open('predict_instant.json')).items()}
ts = lambda x: datetime.fromisoformat(x).astimezone(timezone.utc)
seen = set(); new = collections.Counter(); dup = collections.Counter(); fr = {}
for s in S:
    h = ts(s['submit_time']).strftime('%H'); real = bool((s['join'] or {}).get('survivors'))
    if s['field_id'] in seen: dup[(h, s['username'])] += 1
    else: seen.add(s['field_id']); new[(h, 'real' if real else 'instant')] += 1
    fr[h] = max(fr.get(h, 0), s['field_id'])
print("hour | new real | new instant | duplicate subs (demoux, fleet) | max submitted field id")
for h in sorted(fr): print(h, new[(h, 'real')], new[(h, 'instant')], dup[(h, 'demoux')], dup[(h, 'wp-vast-fleet')], fr[h])
full = [h for h in sorted(fr) if '03' <= h <= '08']
rate = sum(new[(h, 'real')] for h in full) / len(full)
front = max(fr.values()); rem = [i for i in F if i > front]; rem_real = sum(1 for i in rem if not P[i])
hours = rem_real / rate; t_end = ts(S[-1]['submit_time']) + timedelta(hours=hours)
print(f"new real fields/h (03-08 UTC) {rate:.1f}; processed frontier {front}; remaining {len(rem)}, predicted real {rem_real}; {hours:.0f} h -> {t_end:%Y-%m-%d %H:%M} UTC")
for k in (1.5, 3.0):
    print(f"  if the fleet's rate rose x{k} (main deployed, same boxes): demoux+fleet = {rate - 11 + 11*k:.1f}/h (fleet share assumed 11/h of new) -> {rem_real/(rate-11+11*k)/24:.1f} days")

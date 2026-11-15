#!/usr/bin/env python3
"""T2.8 sample (written before any box run): demoux a7a59c1 real b62 fields (first 5 past the boundary by field id,
latest 5 by submit time, min and max join run_secs, the rest evenly spread in submit-time order) and fleet v3.4.7
real fields (min/max run_secs, first/last by time, rest spread). Timing fields: 6 of the fleet sample, spread."""
import json, random
F = {f['id']: f for f in json.load(open('fields_b62.json'))}
S = [s for s in json.load(open('subs_0615.json')) if s['field_id'] in F and (s['join'] or {}).get('survivors')]
def pick(user, build, n_first, n_last, total):
    R = sorted([s for s in S if s['username'] == user and (s['build'] or '').startswith(build)], key=lambda s: s['submit_time'])
    chosen = []
    def add(s):
        if s['field_id'] not in {c['field_id'] for c in chosen}: chosen.append(s)
    for s in sorted(R, key=lambda s: s['field_id'])[:n_first]: add(s)
    for s in R[-n_last:]: add(s)
    add(min(R, key=lambda s: float(s['join']['run_secs']))); add(max(R, key=lambda s: float(s['join']['run_secs'])))
    k = 0
    while len(chosen) < total:
        step = len(R) / (total - len(chosen) + 1)
        for i in range(1, total - len(chosen) + 1):
            add(R[min(len(R) - 1, int(i * step) + k)])
            if len(chosen) >= total: break
        k += 1
    return chosen
dem = pick('demoux', 'a7a59c11', 5, 5, 32)
flt = pick('wp-vast-fleet', '8bd154bc', 1, 1, 16)
q = lambda L: [dict(field_id=s['field_id'], base=62, range_start=int(F[s['field_id']]['range_start']), range_size=int(F[s['field_id']]['range_size'])) for s in L]
timing = sorted(flt, key=lambda s: s['field_id'])[::3][:6]
json.dump(dict(demoux=[s['id'] for s in dem], fleet=[s['id'] for s in flt], timing=[s['field_id'] for s in timing]), open('sample.json', 'w'))
# queue for main: timing fields last (they run again in the timing experiment); demoux and fleet interleaved
tf = {s['field_id'] for s in timing}
rest = [s for s in dem + flt if s['field_id'] not in tf]
seen = set(); main_q = []
for s in rest:
    if s['field_id'] not in seen: seen.add(s['field_id']); main_q.append(s)
json.dump(q(main_q), open('queue_main_sample.json', 'w'))
json.dump(q(timing), open('queue_timing.json', 'w'))
print(len(dem), len(flt), len(main_q), [s['field_id'] for s in timing], len({s['field_id'] for s in dem} & {s['field_id'] for s in flt}))

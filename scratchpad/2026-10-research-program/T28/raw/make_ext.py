#!/usr/bin/env python3
"""T2.8 extension queue (written before it runs): every fleet real field not yet in the sample, interleaved with
30 more demoux real fields drawn at random (seed 20261115) from those not in the sample. Run after timing round 2."""
import json, random
random.seed(20261115)
F = {f['id']: f for f in json.load(open('fields_b62.json'))}
S = [s for s in json.load(open('subs_0615.json')) if s['field_id'] in F and (s['join'] or {}).get('survivors')]
smp = json.load(open('sample.json')); subs = {s['id']: s for s in S}
done = {subs[i]['field_id'] for i in smp['demoux'] + smp['fleet']}
fl = sorted({s['field_id'] for s in S if s['username'] == 'wp-vast-fleet'} - done)
dm = sorted({s['field_id'] for s in S if s['username'] == 'demoux'} - done - set(fl))
dm = random.sample(dm, 30)
out = []
while fl or dm:
    out += fl[:1]; fl = fl[1:]; out += dm[:1]; dm = dm[1:]
json.dump([dict(field_id=f, base=62, range_start=int(F[f]['range_start']), range_size=int(F[f]['range_size'])) for f in out], open('queue_ext.json', 'w'))
print(len(out))

#!/usr/bin/env python3
"""T2.8 task 1 summary: instant fields by argument (instant_check.jsonl) and real fields' stronger-argument verdicts."""
import json, collections
B = 62
F = {f['id']: f for f in json.load(open('fields_b62_0900.json'))}
R = [json.loads(l) for l in open('instant_check.jsonl')]
def lead(x, j):
    X = x ** j; n = 0; y = X
    while y: y //= B; n += 1
    return X // B ** (n - 1)
cat = collections.Counter()
for r in R:
    f = F[r['field_id']]; a, e = int(f['range_start']), int(f['range_end']) - 1
    l = (lead(a, 2), lead(a, 3), lead(e, 2), lead(e, 3))
    if not r['proved']: cat['NOT PROVED'] += 1
    elif l == (1, 1, 1, 1): cat['leading digits 1,1 (x < 2^(1/3))'] += 1
    elif l == (2, 2, 2, 2): cat['leading digits 2,2 (sqrt2 <= x < 3^(1/3))'] += 1
    elif r['why'] == 'collision': cat['other field-level collision of fixed top digits'] += 1
    elif r['why'] == 'hall': cat['field-level Hall (two-position domains)'] += 1
    else: cat['subdivision (' + r['why'] + f', depth {r["depth"]}, {r["nodes"]} nodes)'] += 1
print("instant fields checked:", len(R)); [print(f"  {v:6d}  {k}") for k, v in cat.most_common()]
try:
    Q = [json.loads(l) for l in open('real_check.jsonl')]
    print("real fields checked:", len(Q), collections.Counter('proved empty (' + q['why'] + ')' if q['proved'] else 'not proved: ' + q['why'] for q in Q))
    print("  proved:", [(q['field_id'], q['why'], q['depth'], q['nodes']) for q in Q if q['proved']])
except FileNotFoundError: pass

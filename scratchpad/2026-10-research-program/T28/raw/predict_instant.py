#!/usr/bin/env python3
"""T2.8 task 4: field-level (no subdivision) emptiness verdict of instant_check.cert for every base-62 field,
to predict the instant fraction of the fields not yet claimed. Output: predict_instant.json {field_id: reason|null}."""
import json, sys
sys.path.insert(0, '.')
from instant_check import cert, nd, B
F = json.load(open('fields_b62.json'))
out = {}
for f in F:
    a, e = int(f['range_start']), int(f['range_end']) - 1
    r, why = cert(a, e)
    out[f['id']] = why
json.dump(out, open('predict_instant.json', 'w'))

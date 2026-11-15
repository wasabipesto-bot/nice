#!/usr/bin/env python3
"""Markdown table of every comparison in compare_detail.jsonl."""
import json
R = [json.loads(l) for l in open('compare_detail.jsonl')]
R.sort(key=lambda r: (r['field_id'], r['rule'], r['orig']))
print("| field | compared submission | device | build | survivors | checked | main survivors (T) | main checked (P) | rule | result | margin |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
for r in R:
    if r['rule'] == 'exact':
        res = 'equal' if r['ok'] else 'MISMATCH'; margin = 'Δ 0 / 0' if r['ok'] else f"Δ {r['surv']-r['T']} / {r['chk']-r['P']}"
    else:
        res = 'within bound' if r['ok'] else 'OUTSIDE BOUND'; margin = f"x={r['x']:,}, d={r['d']}, tol={r['tol']} (|d|/tol {abs(r['d'])/r['tol']:.2f})"
    dev = (r.get('gpu') or 'RTX 3080 (box)').replace(' (RADV GFX1201) (Vulkan, wgpu<spirv>)', '').replace('NVIDIA GeForce ', '')
    b = r.get('build') or ('8bd154bc' if 'v3.4.7' in r['orig'] else '54d0aac4')
    tag = r['orig'] + (' [sample]' if r.get('in_sample') else '')
    print(f"| {r['field_id']} | {tag} | {dev} | {b} | {r['surv']:,} | {r['chk']:,} | {r['T']:,} | {r['P']:,} | {r['rule']} | {res} | {margin} |")

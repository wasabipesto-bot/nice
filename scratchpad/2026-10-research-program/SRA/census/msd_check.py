#!/usr/bin/env python3
"""SRA census: for each of the 451 base-54 fields, the share of the field that survives a leading-digit test
(exact integer arithmetic, binary splitting to 4,096 pieces): a piece is discarded when the leading digits
that n^2 and n^3 keep over the whole piece already repeat a digit (within or across the two). A field with
(almost) nothing left needs (almost) no GPU launch, which explains a very short processing time."""
import json, statistics as st, collections
B = 54
def digs(x):
    d = []
    while x: x, r = divmod(x, B); d.append(r)
    return d[::-1]
def common_prefix(a, b):
    da, db = digs(a), digs(b)
    if len(da) != len(db): return []
    out = []
    for x, y in zip(da, db):
        if x != y: break
        out.append(x)
    return out
def dead(lo, hi):  # [lo, hi)
    p2 = common_prefix(lo * lo, (hi - 1) ** 2); p3 = common_prefix(lo ** 3, (hi - 1) ** 3)
    u = p2 + p3
    return len(set(u)) < len(u)
def alive_share(lo, hi, depth):
    if dead(lo, hi): return 0.0
    if depth == 0: return 1.0
    mid = (lo + hi) // 2
    return 0.5 * (alive_share(lo, mid, depth - 1) + alive_share(mid, hi, depth - 1))
rows = {}
for l in open("rows.jsonl"):
    x = json.loads(l); rows[x["field_id"]] = x
tim = {x["id"]: float(x["proc"]) for x in json.load(open("exposed_timing.json"))}
med = {}
for g in ("NVIDIA GeForce RTX 4090", "NVIDIA GeForce RTX 3060"):
    med[g] = st.median([tim[x["id"]] for x in rows.values() if x["gpu"] == g])
res = []
for f, x in sorted(rows.items()):
    lo = int(x["fields"]["range_start"]); hi = lo + int(x["fields"]["range_size"])
    res.append((f, alive_share(lo, hi, 12), tim[x["id"]] / med[x["gpu"]], tim[x["id"]], x["gpu"][-8:]))
json.dump(res, open("msd_check.json", "w"))
short = [r for r in res if r[2] < 0.15]; rest = [r for r in res if r[2] >= 0.15]
print("short runs (under 15 % of the card's median):", len(short))
print("  their surviving share: max %.5f, median %.5f" % (max(r[1] for r in short), st.median(r[1] for r in short)))
print("other runs:", len(rest), " surviving share: min %.5f, p5 %.5f, median %.4f" % (min(r[1] for r in rest), sorted(r[1] for r in rest)[len(rest)//20], st.median(r[1] for r in rest)))
print("short runs with a surviving share above 0.02:", [(r[0], round(r[1], 4), round(r[3], 3), r[4]) for r in short if r[1] > 0.02])
print("other runs with a surviving share under 0.02:", [(r[0], round(r[1], 4), round(r[3], 3), r[4]) for r in rest if r[1] < 0.02][:12])
# rank correlation by bins of surviving share
bins = collections.defaultdict(list)
for r in res: bins[min(int(r[1] * 10), 9)].append(r[2])
for k in sorted(bins): print("  share %.1f-%.1f: n=%3d  time/median: median %.2f  min %.2f" % (k / 10, (k + 1) / 10, len(bins[k]), st.median(bins[k]), min(bins[k])))

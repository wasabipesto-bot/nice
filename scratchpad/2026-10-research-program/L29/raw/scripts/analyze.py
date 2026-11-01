#!/usr/bin/env python3
"""A/B tables for L29: python3 analyze.py RAWDIR (holding the box's logs/)."""
import json, os, re, statistics as st, sys
D = sys.argv[1] if len(sys.argv) > 1 else "box"
trees = ("main", "pr")
pat = re.compile(r"JOIN THROUGHPUT .*?base=(\d+) fields=(\d+).*?per_field=([\d.]+).*?setup=([\d.]+)s device=([\d.]+)s.*?batches=(\d+) slots=(\d+) plan_mib=(\d+).*?survivors=(\d+) checked=(\d+) found=(\d+)")
def runs(prefix):
    out = {t: {} for t in trees}
    for r in (1, 2, 3):
        for t in trees:
            p = f"{D}/{prefix}_{t}_r{r}.log"
            if not os.path.exists(p):
                continue
            for m in pat.finditer(open(p).read()):
                b = int(m[1])
                out[t].setdefault(b, []).append(dict(per=float(m[3]), setup=float(m[4]), dev=float(m[5]),
                    batches=int(m[6]), slots=int(m[7]), mib=int(m[8]), surv=int(m[9]), chk=int(m[10]), found=int(m[11])))
    return out
sp = lambda xs: (max(xs) - min(xs)) / st.median(xs) * 100
for prefix, label in (("e17", "1e17, 1 field"), ("e16", "1e16, 2 fields"), ("e14", "1e14, 2 fields (counts check)")):
    data = runs(prefix)
    if not data["main"]:
        continue
    print(f"\n### {label}\n")
    print("| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | speed-up | per launch main / PR |")
    print("|---|---|---|---|---|---|---|---|")
    for b in sorted(data["main"]):
        m = [x["per"] for x in data["main"][b]]; p = [x["per"] for x in data["pr"].get(b, [])]
        if not p:
            continue
        mm, pm = st.median(m), st.median(p)
        print(f"| {b} | **{mm:.3f}** ({', '.join(f'{x:.3f}' for x in m)}) | {sp(m):.1f} % | **{pm:.3f}** ({', '.join(f'{x:.3f}' for x in p)}) | {sp(p):.1f} % | **×{pm/mm:.3f}** | ×{mm/pm:.3f} | {data['main'][b][0]['slots']} / {data['pr'][b][0]['slots']} |")
    print()
    for b in sorted(data["main"]):
        for t in trees:
            c = "; ".join(f"{x['surv']} / {x['chk']} / {x['found']}" for x in data[t].get(b, []))
            print(f"- b{b} {t}: {c}")
nm = {t: [] for t in trees}
for r in (1, 2, 3):
    for t in trees:
        p = f"{D}/nm_r{r}_{t}.json"
        if os.path.exists(p) and os.path.getsize(p) > 0:
            try:
                nm[t].append(json.load(open(p)))
            except Exception as e:
                print("bad json", p, e)
if nm["main"] and nm["pr"]:
    print("\n### NiceMark nice-only\n")
    keys = [s["key"] for s in nm["main"][0]["scenarios"]]
    print("| scenario | main rate (rounds) | spread | PR rate (rounds) | spread | **PR / main** |")
    print("|---|---|---|---|---|---|")
    for k in keys:
        r = {t: [next(s for s in d["scenarios"] if s["key"] == k)["rate"] for d in nm[t]] for t in trees}
        m, p = st.median(r["main"]), st.median(r["pr"])
        print(f"| {k} | **{m:.3e}** ({', '.join(f'{x:.3e}' for x in r['main'])}) | {sp(r['main']):.1f} % | **{p:.3e}** ({', '.join(f'{x:.3e}' for x in r['pr'])}) | {sp(r['pr']):.1f} % | **×{p/m:.3f}** |")
    for t in trees:
        print(f"\nscore {t}: {[d.get('score') for d in nm[t]]}")

# nvidia-smi samples (5 s) under load (power > 100 W): median SM clock, power, max temperature.
import glob
print("\n### nvidia-smi under load (samples > 100 W)\n")
print("| run | samples | median SM MHz | median W | max °C | throttle flags |")
print("|---|---|---|---|---|---|")
for p in sorted(glob.glob(f"{D}/*.smi")):
    rows = []
    for line in open(p):
        f = [x.strip() for x in line.split(",")]
        if len(f) < 6 or not f[1].endswith("MHz"):
            continue
        try:
            mhz, w, t = float(f[1].split()[0]), float(f[2].split()[0]), float(f[3])
        except ValueError:
            continue
        if w > 100:
            rows.append((mhz, w, t, f[4]))
    if rows:
        print(f"| {os.path.basename(p)[:-4]} | {len(rows)} | {st.median(r[0] for r in rows):.0f} | {st.median(r[1] for r in rows):.1f} | {max(r[2] for r in rows):.0f} | {', '.join(sorted({r[3] for r in rows}))} |")

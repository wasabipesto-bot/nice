#!/usr/bin/env python3
"""A/B tables: python3 ab.py LOGDIR (the box's logs/ab)."""
import glob, os, re, statistics as st, sys
D = sys.argv[1]
V = ("base", "diff", "bar", "ndig", "dn", "both", "all")
pat = re.compile(r"JOIN THROUGHPUT .*?base=(\d+) fields=(\d+).*?per_field=([\d.]+).*?setup=([\d.]+)s device=([\d.]+)s.*?batches=(\d+) slots=(\d+) plan_mib=(\d+).*?survivors=(\d+) checked=(\d+) found=(\d+)")
sp = lambda xs: (max(xs) - min(xs)) / st.median(xs) * 100
for pre, lab in (("e16b62", "b62 1e16, 2 fields: all six variants"), ("x16b62", "b62 1e16, 2 fields: base, dn, all (second set)"), ("e16b60", "b60 1e16, 2 fields: all six variants"), ("x16b60", "b60 1e16, 2 fields: base, dn"), ("e17b62", "b62 1e17, 1 field")):
    data = {}
    for v in V:
        for r in (1, 2, 3):
            p = f"{D}/{pre}_{v}_r{r}.log"
            if not os.path.exists(p):
                continue
            ms = list(pat.finditer(open(p).read()))
            if ms:
                m = ms[-1]
                data.setdefault(v, []).append(dict(per=float(m[3]), dev=float(m[5]), surv=int(m[9]), chk=int(m[10]), found=int(m[11]), slots=int(m[7])))
    if "base" not in data:
        continue
    b = st.median(x["per"] for x in data["base"])
    print(f"\n### {lab}\n")
    print("| variant | s/field (rounds, in run order) | spread | median | / base | speed-up (medians) | speed-up per round |")
    print("|---|---|---|---|---|---|---|")
    for v in V:
        if v not in data:
            continue
        xs = [x["per"] for x in data[v]]
        m = st.median(xs)
        pr = [data["base"][i]["per"] / x["per"] for i, x in enumerate(data[v]) if i < len(data["base"])]
        print(f"| {v} | {', '.join(f'{x:.3f}' for x in xs)} | {sp(xs):.1f} % | **{m:.3f}** | ×{m / b:.3f} | **×{b / m:.3f}** | {', '.join(f'×{x:.3f}' for x in pr)} |")
    print()
    for v in V:
        if v in data:
            print(f"- {v}: " + "; ".join(f"{x['surv']} / {x['chk']} / {x['found']}" for x in data[v]))
print("\n### nvidia-smi under load (samples > 100 W)\n")
print("| run | samples | median SM MHz | median W | max °C |")
print("|---|---|---|---|---|")
for f in sorted(glob.glob(f"{D}/*.smi")):
    rows = []
    for line in open(f):
        p = [x.strip() for x in line.split(",")]
        if len(p) < 5 or not p[1].split()[0].isdigit():
            continue
        try:
            mhz, w, t = float(p[1].split()[0]), float(p[2].split()[0]), float(p[3])
        except ValueError:
            continue
        if w > 100:
            rows.append((mhz, w, t))
    if rows:
        print(f"| {os.path.basename(f)[:-4]} | {len(rows)} | {st.median(r[0] for r in rows):.0f} | {st.median(r[1] for r in rows):.1f} | {max(r[2] for r in rows):.0f} |")

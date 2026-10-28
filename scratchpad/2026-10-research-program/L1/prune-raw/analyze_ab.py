#!/usr/bin/env python3
"""Tables for PRUNE.md from the box logs in prune-raw/box/ (thr_r*_{main,prune}.log,
nm_r*_{main,prune}.json, ept_r*_e*_b*.log)."""
import glob, json, os, re, statistics as st, sys

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "box")
LINE = re.compile(r"JOIN THROUGHPUT .*?base=(\d+) fields=(\d+) .*?secs=([\d.]+) per_field=([\d.]+) rate=([\d.e+]+) n/s \| "
                  r"setup=([\d.]+)s device=([\d.]+)s wall=([\d.]+)s batches=(\d+) slots=(\d+) plan_mib=(\d+) \| "
                  r"empty_top=(\d+) retried=(\d+) splits=(\d+) survivors=(\d+) checked=(\d+) found=(\d+)")

def parse(path):
    out = {}
    for m in LINE.finditer(open(path).read()):
        g = m.groups()
        out[int(g[0])] = dict(secs=float(g[2]), per_field=float(g[3]), rate=float(g[4]), setup=float(g[5]),
                              device=float(g[6]), wall=float(g[7]), batches=int(g[8]), slots=int(g[9]),
                              mib=int(g[10]), retried=int(g[12]), splits=int(g[13]), survivors=int(g[14]),
                              checked=int(g[15]), found=int(g[16]))
    return out

def spread(xs):
    m = st.median(xs)
    return m, (max(xs) - min(xs)) / m * 100

def thr():
    runs = {}
    for p in sorted(glob.glob(os.path.join(D, "thr_r*_*.log"))):
        r, t = re.search(r"thr_r(\d+)_(\w+)\.log", p).groups()
        runs.setdefault(t, {})[int(r)] = parse(p)
    if not runs:
        return
    print("### Fixed-field throughput (1e16, 2 fields per base), per round\n")
    print("| base | tree | " + " | ".join(f"r{r} s/field" for r in sorted(runs['main'])) + " | median s/field | spread | device s/field (median) | batches/field | slots | survivors (r1) | checked (r1) |")
    print("|---|---|" + "---|" * len(runs['main']) + "---|---|---|---|---|---|---|")
    summary = []
    for b in (58, 60, 62, 64):
        med = {}
        for t in ("main", "prune"):
            rs = runs.get(t, {})
            xs = [rs[r][b]["per_field"] for r in sorted(rs) if b in rs[r]]
            ds = [rs[r][b]["device"] for r in sorted(rs) if b in rs[r]]
            if not xs:
                continue
            m, sp = spread(xs)
            med[t] = (m, st.median(ds))
            r1 = rs[min(rs)][b]
            print(f"| {b} | {t} | " + " | ".join(f"{x:.2f}" for x in xs) + f" | **{m:.2f}** | {sp:.1f} % | {st.median(ds):.2f} | {r1['batches']} | {r1['slots']} | {r1['survivors']:.4e} | {r1['checked']:.4e} |")
        if len(med) == 2:
            summary.append((b, med["main"][0], med["prune"][0], med["main"][1], med["prune"][1]))
    print("\n### Speed-up (median main / median prune)\n")
    print("| base | main s/field | prune s/field | wall speed-up | device-time speed-up | time saved |")
    print("|---|---|---|---|---|---|")
    for b, a, p, da, dp in summary:
        print(f"| {b} | {a:.2f} | {p:.2f} | **{a/p:.3f}×** | {da/dp:.3f}× | {100*(1-p/a):.1f} % |")
    # exactness of counts between trees
    print("\n### Counter equality between trees (survivors, checked, found per round)\n")
    for b in (58, 60, 62, 64):
        vals = {(t, r): (runs[t][r][b]["survivors"], runs[t][r][b]["checked"], runs[t][r][b]["found"])
                for t in runs for r in runs[t] if b in runs[t][r]}
        sv = {v[0] for v in vals.values()}; ck = {v[1] for v in vals.values()}; fd = {v[2] for v in vals.values()}
        print(f"- b{b}: survivors {sorted(sv)}; checked {sorted(ck)}; found {sorted(fd)}")

def nicemark():
    files = sorted(glob.glob(os.path.join(D, "nm_r*_*.json")))
    if not files:
        return
    rows = {}
    for p in files:
        r, t = re.search(r"nm_r(\d+)_(\w+)\.json", p).groups()
        try:
            j = json.load(open(p))
        except Exception as e:
            print(f"(bad json {p}: {e})"); continue
        res = j.get("scenarios") or j.get("results") or []
        for s in res:
            f = s.get("field") or s
            jn = f.get("join") or {}
            rows.setdefault(s["key"], {}).setdefault(t, []).append(
                (int(r), s.get("rate"), f.get("route"), f.get("route_reason"),
                 f"{jn.get('sampled')}/{jn.get('partitions')} partitions, {jn.get('slices')} slice(s), {jn.get('slots')} slots" if jn else ""))
        rows.setdefault("score", {}).setdefault(t, []).append((int(r), j.get("score"), "-", None, ""))
    print("\n### NiceMark nice-only (GPU, 150 s budget)\n")
    print("| scenario | route (main / prune) | main rates | prune rates | main median | prune median | spread main / prune | prune / main |")
    print("|---|---|---|---|---|---|---|---|")
    for k, v in rows.items():
        if "main" not in v or "prune" not in v:
            continue
        a = [x[1] for x in sorted(v["main"]) if x[1]]; p = [x[1] for x in sorted(v["prune"]) if x[1]]
        if not a or not p:
            continue
        ra = {f"{x[2]}{'(' + x[3] + ')' if x[3] else ''}" for x in v["main"]}; rp = {f"{x[2]}{'(' + x[3] + ')' if x[3] else ''}" for x in v["prune"]}
        ma, sa = spread(a); mp, sp = spread(p)
        print(f"| {k} | {'/'.join(sorted(ra))} / {'/'.join(sorted(rp))} | " + ", ".join(f"{x:.3g}" for x in a) + " | " + ", ".join(f"{x:.3g}" for x in p) +
              f" | {ma:.4g} | {mp:.4g} | {sa:.1f} / {sp:.1f} % | **{mp/ma:.3f}** |")
    print()
    for k, v in rows.items():
        if k != "score" and "main" in v:
            print(f"- {k}: main {v['main'][0][4]}; prune {v.get('prune', [[None]*5])[0][4]}")

def ept():
    files = sorted(glob.glob(os.path.join(D, "ept_r*_e*_b*.log")))
    if not files:
        return
    rows = {}
    for p in files:
        r, e, b = map(int, re.search(r"ept_r(\d+)_e(\d+)_b(\d+)\.log", p).groups())
        d = parse(p).get(b)
        if d:
            rows.setdefault((b, e), []).append((r, d["per_field"], d["device"]))
    print("\n### EPT sweep with the prune (first field, 1e16; rounds 1-2 interleaved over EPT 2,3,4,5 at b62/b64; round 3 = EPT 1 at b62/b64 and EPT 4,2,1 at b58/b60)\n")
    print("| base | EPT | wall s/field per round | mean wall s/field | mean device s | wall speed-up vs EPT 4 |")
    print("|---|---|---|---|---|---|")
    for b in (58, 60, 62, 64):
        ref = st.mean(x[1] for x in rows.get((b, 4), [(0, float('nan'), 0)]))
        for e in (1, 2, 3, 4, 5):
            xs = sorted(rows.get((b, e), []))
            if not xs:
                continue
            m = st.mean(x[1] for x in xs)
            print(f"| {b} | {e} | " + ", ".join(f"{x[1]:.2f}" for x in xs) + f" | {m:.2f} | {st.mean(x[2] for x in xs):.2f} | {ref/m:.3f}× |")

thr(); nicemark(); ept()

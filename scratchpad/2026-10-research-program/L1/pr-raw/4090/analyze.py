#!/usr/bin/env python3
"""Tables for AB-4090.md from the box logs in pr-raw/4090/ab/ (thr_r*_<tree>_<tag>.log, nm_r*_<tree>.json,
ept_r*_e*_b*.log, ept14_r*_e*.log, compare_*.log). Usage: analyze.py [A tree] [B tree]"""
import glob, json, os, re, statistics as st, sys

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ab")
A = sys.argv[1] if len(sys.argv) > 1 else "main"
B = sys.argv[2] if len(sys.argv) > 2 else "prune"
LINE = re.compile(r"JOIN THROUGHPUT .*?base=(\d+) fields=(\d+) .*?secs=([\d.]+) per_field=([\d.]+) rate=([\d.e+]+) n/s \| "
                  r"setup=([\d.]+)s device=([\d.]+)s wall=([\d.]+)s batches=(\d+) slots=(\d+) plan_mib=(\d+) \| "
                  r"empty_top=(\d+) retried=(\d+) splits=(\d+) survivors=(\d+) checked=(\d+) found=(\d+)")

def parse(path):
    out = {}
    for m in LINE.finditer(open(path).read()):
        g = m.groups()
        out[int(g[0])] = dict(fields=int(g[1]), secs=float(g[2]), per_field=float(g[3]), rate=float(g[4]), setup=float(g[5]),
                              device=float(g[6]), wall=float(g[7]), batches=int(g[8]), slots=int(g[9]),
                              mib=int(g[10]), retried=int(g[12]), splits=int(g[13]), survivors=int(g[14]),
                              checked=int(g[15]), found=int(g[16]))
    return out

def spread(xs):
    m = st.median(xs)
    return m, (max(xs) - min(xs)) / m * 100

def thr():
    runs = {}  # tree -> round -> base -> rec
    for p in sorted(glob.glob(os.path.join(D, "thr_r*_*.log"))):
        r, t = re.search(r"thr_r(\d+)_([a-z]+)_", os.path.basename(p)).groups()
        runs.setdefault(t, {}).setdefault(int(r), {}).update(parse(p))
    if A not in runs or B not in runs:
        print(f"(no A/B logs for {A}/{B}: {sorted(runs)})"); return
    print(f"### Fixed-field throughput (1e16, 2 fields per base), A = {A}, B = {B}\n")
    print("| base | tree | r1 | r2 | r3 | **median s/field** | spread | device s/field (median) | batches | slots | survivors (r1) | checked (r1) |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|")
    summary = []
    for b in (58, 60, 62, 64):
        med = {}
        for t in (A, B):
            rs = runs[t]
            xs = [rs[r][b]["per_field"] for r in sorted(rs) if b in rs[r]]
            ds = [rs[r][b]["device"] for r in sorted(rs) if b in rs[r]]
            if not xs:
                continue
            m, sp = spread(xs)
            med[t] = (m, st.median(ds), sp)
            r1 = rs[min(r for r in rs if b in rs[r])][b]
            print(f"| {b} | {t} | " + " | ".join(f"{x:.2f}" for x in xs) + f" | **{m:.2f}** | {sp:.1f} % | {st.median(ds):.2f} | {r1['batches']} | {r1['slots']} | {r1['survivors']:.4e} | {r1['checked']:.4e} |")
        if len(med) == 2:
            summary.append((b, med[A], med[B]))
    print(f"\n### Speed-up (median {A} / median {B})\n")
    print(f"| base | {A} s/field | {B} s/field | **wall speed-up** | device-time speed-up | time saved | spreads A / B |")
    print("|---|---|---|---|---|---|---|")
    for b, a, p in summary:
        print(f"| {b} | {a[0]:.2f} | {p[0]:.2f} | **{a[0]/p[0]:.3f}×** | {a[1]/p[1]:.3f}× | {100*(1-p[0]/a[0]):.1f} % | {a[2]:.1f} / {p[2]:.1f} % |")
    print("\n### Counters per round (survivors, checked, found)\n")
    for b in (58, 60, 62, 64):
        for t in (A, B):
            v = [(r, runs[t][r][b]["survivors"], runs[t][r][b]["checked"], runs[t][r][b]["found"]) for r in sorted(runs[t]) if b in runs[t][r]]
            print(f"- b{b} {t}: " + "; ".join(f"r{r} {s:.6e} / {c:.6e} / {f}" for r, s, c, f in v))

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
        for s in j.get("scenarios") or []:
            jn = s.get("join") or {}
            rows.setdefault(s["key"], {}).setdefault(t, []).append(
                (int(r), s.get("rate"), s.get("route"), s.get("route_reason"),
                 f"{jn.get('sampled')}/{jn.get('partitions')} partitions, {jn.get('slices')} slice(s), {jn.get('slots')} slots" if jn else "",
                 s.get("window_size")))
        rows.setdefault("score", {}).setdefault(t, []).append((int(r), j.get("score"), "-", None, "", None))
    print(f"\n### NiceMark nice-only (GPU, 150 s budget), A = {A}, B = {B}\n")
    print(f"| scenario | route ({A} / {B}) | sample ({A}; {B}) | {A} rates | {B} rates | {A} median | {B} median | spread A / B | **B / A** |")
    print("|---|---|---|---|---|---|---|---|---|")
    for k, v in rows.items():
        if A not in v or B not in v:
            continue
        a = [x[1] for x in sorted(v[A]) if x[1]]; p = [x[1] for x in sorted(v[B]) if x[1]]
        if not a or not p:
            continue
        ra = {f"{x[2]}{'(' + x[3] + ')' if x[3] else ''}" for x in v[A]}; rp = {f"{x[2]}{'(' + x[3] + ')' if x[3] else ''}" for x in v[B]}
        ma, sa = spread(a); mp, sp = spread(p)
        print(f"| {k} | {'/'.join(sorted(ra))} / {'/'.join(sorted(rp))} | {v[A][0][4]}; {v[B][0][4]} | " + ", ".join(f"{x:.4g}" for x in a) + " | " + ", ".join(f"{x:.4g}" for x in p) +
              f" | {ma:.4g} | {mp:.4g} | {sa:.1f} / {sp:.1f} % | **{mp/ma:.3f}** |")

def ept():
    files = sorted(glob.glob(os.path.join(D, "ept_r*_e*_b*.log")))
    if not files:
        return
    rows = {}
    for p in files:
        r, e, b = map(int, re.search(r"ept_r(\d+)_e(\d+)_b(\d+)\.log", p).groups())
        d = parse(p).get(b)
        if d:
            rows.setdefault((b, e), []).append((r, d["per_field"], d["device"], d["survivors"], d["checked"]))
    epts = sorted({e for _, e in rows})
    print("\n### EPT matrix with the prune (ept tree; first 1e16 field after a 1e14 warm-up; wall s/field, rounds interleaved)\n")
    print("| base | " + " | ".join(f"EPT {e}" for e in epts) + " | best | best vs EPT 4 | EPT 2 vs 4 | EPT 2 vs 6 |")
    print("|---|" + "---|" * len(epts) + "---|---|---|---|")
    for b in (58, 60, 62, 64):
        cells, meds = [], {}
        for e in epts:
            xs = [x[1] for x in sorted(rows.get((b, e), []))]
            if xs:
                m, sp = spread(xs); meds[e] = m
                cells.append(f"{', '.join(f'{x:.2f}' for x in xs)} (med {m:.2f}, ±{sp:.1f} %)")
            else:
                cells.append("–")
        if not meds:
            continue
        best = min(meds, key=meds.get)
        r = lambda x, y: f"×{meds[y]/meds[x]:.3f}" if x in meds and y in meds else "–"
        print(f"| {b} | " + " | ".join(cells) + f" | **EPT {best}** | {r(best, 4)} | {r(2, 4)} | {r(2, 6)} |")
    print("\nDevice seconds (median): " + "; ".join(
        f"b{b} " + ", ".join(f"E{e} {st.median(x[2] for x in rows[(b, e)]):.2f}" for e in epts if (b, e) in rows) for b in (58, 60, 62, 64)))

def ept14():
    files = sorted(glob.glob(os.path.join(D, "ept14_r*_e*.log")))
    if not files:
        return
    rows = {}
    for p in files:
        r, e = map(int, re.search(r"ept14_r(\d+)_e(\d+)\.log", p).groups())
        for b, d in parse(p).items():
            rows.setdefault((b, e), []).append((r, d["per_field"], d["device"], d["fields"], d["batches"], d["slots"]))
    epts = sorted({e for _, e in rows})
    n = next(iter(rows.values()))[0][3]
    print(f"\n### EPT at production size with the prune (1e14 fields, {n} consecutive per base from the A/B starts; wall s/field with 2 in flight)\n")
    print("| base | " + " | ".join(f"EPT {e}" for e in epts) + " | " + " | ".join(f"EPT {e} vs 4" for e in epts if e != 4) + " |")
    print("|---|" + "---|" * (2 * len(epts) - (1 if 4 in epts else 0)))
    for b in (58, 60, 62, 64):
        cells, meds = [], {}
        for e in epts:
            xs = [x[1] for x in sorted(rows.get((b, e), []))]
            if xs:
                m, sp = spread(xs); meds[e] = m
                cells.append(f"{', '.join(f'{x:.3f}' for x in xs)} (med {m:.3f}, ±{sp:.1f} %)")
            else:
                cells.append("–")
        rat = [f"×{meds[4]/meds[e]:.3f}" if 4 in meds and e in meds else "–" for e in epts if e != 4]
        print(f"| {b} | " + " | ".join(cells) + " | " + " | ".join(rat) + " |")

def compare():
    for p in sorted(glob.glob(os.path.join(D, "compare_prune.log"))):
        print(f"\n### {os.path.basename(p)}\n")
        for l in open(p):
            if re.search(r"JOIN THROUGHPUT|STRIDE|test result|panicked|differs", l):
                print("    " + l.rstrip()[:400])

def x1(prefix="x1", title="X1: prune + EPT override on new main against main (1e16, 2 fields per base, interleaved)", fmt=".2f"):
    files = sorted(glob.glob(os.path.join(D, f"{prefix}_r*_*.log")))
    if not files:
        return
    runs = {}
    for p in files:
        r, name = re.search(prefix + r"_r(\d+)_(\w+)\.log", os.path.basename(p)).groups()
        runs.setdefault(name, {})[int(r)] = parse(p)
    names = sorted(runs, key=lambda n: (n != "main", n))
    print(f"\n### {title}\n")
    print("| base | " + " | ".join(f"{n} per round" for n in names) + " | " + " | ".join(f"{n} median (spread)" for n in names) + " | " + " | ".join(f"main / {n}" for n in names if n != "main") + " |")
    print("|---|" + "---|" * (3 * len(names) - 1))
    for b in (58, 60, 62, 64):
        meds, cells, cells2 = {}, [], []
        for n in names:
            xs = [runs[n][r][b]["per_field"] for r in sorted(runs[n]) if b in runs[n][r]]
            if xs:
                m, sp = spread(xs); meds[n] = m
                cells.append(", ".join(f"{x:{fmt}}" for x in xs)); cells2.append(f"**{m:{fmt}}** ({sp:.1f} %)")
            else:
                cells.append("–"); cells2.append("–")
        rat = [f"**×{meds['main']/meds[n]:.3f}**" if "main" in meds and n in meds else "–" for n in names if n != "main"]
        print(f"| {b} | " + " | ".join(cells) + " | " + " | ".join(cells2) + " | " + " | ".join(rat) + " |")
    for b in (58, 60, 62, 64):
        print(f"- b{b}: " + "; ".join(f"{n} r{r} surv {runs[n][r][b]['survivors']:.6e} chk {runs[n][r][b]['checked']:.6e} found {runs[n][r][b]['found']} dev {runs[n][r][b]['device']:.2f}" for n in names for r in sorted(runs[n]) if b in runs[n][r]))

which = sys.argv[3] if len(sys.argv) > 3 else "all"
if which == "all":
    thr(); nicemark(); ept(); ept14(); x1(); x1("x14", "X14: production size, 1e14 fields, 20 per base, interleaved", ".3f"); compare()
elif which == "thr":
    thr()

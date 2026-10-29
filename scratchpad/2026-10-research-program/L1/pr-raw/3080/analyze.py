#!/usr/bin/env python3
"""Tables for the PR A/B on the 3080: fixed-field throughput (thr_r*_{main,pr,ept2}.log),
NiceMark (nm_r*_*.json), stage overruns (fl_*.log, EXP_OVERRAN lines) and the profile
(prof_*.log, GPU_PROFILE lines). Usage: analyze.py <dir>"""
import glob, json, os, re, statistics as st, sys
from collections import defaultdict

d = sys.argv[1] if len(sys.argv) > 1 else "."
kv = lambda line: dict(re.findall(r"(\w+)=([^\s|]+)", line))

def thr(prefix="thr", title="Fixed-field throughput (s/field, two 1e16 fields in flight)"):
    rows = defaultdict(lambda: defaultdict(list))  # base -> tree -> [(r, per_field, device, batches, slots, surv, checked)]
    for f in sorted(glob.glob(os.path.join(d, prefix + "_r*_*.log"))):
        m = re.match(prefix + r"_r(\d+)_(\w+)\.log", os.path.basename(f))
        r, tree = int(m[1]), m[2]
        for line in open(f):
            if "JOIN THROUGHPUT" in line:
                x = kv(line)
                rows[int(x["base"])][tree].append((r, float(x["per_field"]), float(x["device"].rstrip("s")),
                    x["batches"], x["slots"], int(x["survivors"]), int(x["checked"])))
    if not rows:
        return
    trees = [t for t in ("main", "pr", "ept2", "ept2real") if any(t in rows[b] for b in rows)]
    print(f"### {title}\n")
    print("| base | tree | rounds | **median** | spread | device s/field (median) | batches | slots | survivors | checked |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    med = {}
    for b in sorted(rows):
        for t in trees:
            v = sorted(rows[b][t])
            if not v:
                continue
            pf = [x[1] for x in v]; dev = [x[2] for x in v]
            m = st.median(pf); med[(b, t)] = m
            spread = (max(pf) - min(pf)) / m * 100
            print(f"| {b} | {t} | {', '.join(f'{x:.3f}' if x < 10 else f'{x:.2f}' for x in pf)} | **{m:.3f}** | {spread:.1f} % | {st.median(dev):.2f} | {v[0][3]} | {v[0][4]} | {v[0][5]:.4e} | {v[0][6]:.4e} |")
    print("\n| base | " + " | ".join(f"{t} / main" for t in trees if t != "main") + " | ept2 / pr |")
    print("|---|" + "---|" * len(trees))
    for b in sorted(rows):
        cells = []
        for t in trees:
            if t == "main":
                continue
            if (b, t) in med and (b, "main") in med:
                s = med[(b, "main")] / med[(b, t)]
                cells.append(f"**×{s:.3f}** ({(1 - 1 / s) * 100:.1f} % saved)")
            else:
                cells.append("–")
        e2 = f"**×{med[(b, 'pr')] / med[(b, 'ept2')]:.3f}**" if (b, "ept2") in med and (b, "pr") in med else "–"
        print(f"| {b} | " + " | ".join(cells) + f" | {e2} |")
    print()
    # survivors / checked deltas vs main (round 1)
    print("| base | tree | Δ survivors vs main | Δ checked vs main | Δchecked/Δsurvivors |")
    print("|---|---|---|---|---|")
    for b in sorted(rows):
        if not rows[b]["main"]:
            continue
        m0 = rows[b]["main"][0]
        for t in trees:
            if t == "main" or not rows[b][t]:
                continue
            x = rows[b][t][0]
            ds, dc = x[5] - m0[5], x[6] - m0[6]
            print(f"| {b} | {t} | {ds:+.3e} ({ds / m0[5]:+.2e}) | {dc:+.3e} ({dc / m0[6]:+.2e}) | {dc / ds if ds else float('nan'):.3f} |")
    print()

def overran():
    out = []
    fs = [f for pat in ("fl_*.log", "thr_*.log", "prof_*.log") for f in sorted(glob.glob(os.path.join(d, pat)))]
    for f in fs:
        for line in open(f):
            if "EXP_OVERRAN" in line:
                x = kv(line[line.index("EXP_OVERRAN"):])
                out.append((os.path.basename(f), x))
    if not out:
        return
    print("### Stage overruns (EXP_OVERRAN)\n")
    print("| log | base | flush level | overran | survivors (counted) | overran share |")
    print("|---|---|---|---|---|---|")
    for f, x in out:
        print(f"| {f} | {x['base']} | {x['flush_at']} | {int(x['overran']):,} | {int(x['survivors']):.4e} | {float(x['share']):.2e} |")
    print()
    # timings beside them (fl_ logs)
    print("| log | base | per_field | device |")
    print("|---|---|---|---|")
    for f in sorted(glob.glob(os.path.join(d, "fl_*.log"))):
        for line in open(f):
            if "JOIN THROUGHPUT" in line:
                x = kv(line)
                print(f"| {os.path.basename(f)} | {x['base']} | {x['per_field']} | {x['device']} |")
    print()

def nicemark():
    res = defaultdict(lambda: defaultdict(list))
    score = defaultdict(list)
    for f in sorted(glob.glob(os.path.join(d, "nm_r*_*.json"))):
        m = re.match(r"nm_r(\d+)_(\w+)\.json", os.path.basename(f))
        tree = m[2]
        try:
            j = json.load(open(f))
        except Exception as e:
            print(f"<!-- {f}: {e} -->"); continue
        sc = j.get("score") or j.get("nicemark") or j.get("nice_mark")
        if isinstance(sc, dict):
            sc = sc.get("score")
        score[tree].append(round(sc) if isinstance(sc, (int, float)) else sc)
        for s in j.get("scenarios", j.get("results", [])):
            name = s.get("key") or s.get("name") or s.get("scenario")
            rate = s.get("rate") or s.get("numbers_per_sec") or s.get("rate_per_sec")
            res[name][tree].append((rate, s.get("route")))
    if not score:
        return
    trees = [t for t in ("main", "pr", "ept2") if t in score]
    print("### NiceMark nice-only\n")
    print("| scenario | " + " | ".join(f"{t} rates (median)" for t in trees) + " | " + " | ".join(f"{t} / main" for t in trees if t != "main") + " | routes |")
    print("|---|" + "---|" * (2 * len(trees)))
    for name in res:
        cells, meds = [], {}
        for t in trees:
            v = [x[0] for x in res[name][t] if x[0]]
            meds[t] = st.median(v) if v else None
            cells.append(", ".join(f"{x:.3e}" for x in v) + (f" (**{meds[t]:.3e}**)" if v else ""))
        ratios = [f"**{meds[t] / meds['main']:.3f}**" if meds.get(t) and meds.get("main") else "–" for t in trees if t != "main"]
        routes = ",".join(sorted({str(x[1]) for t in trees for x in res[name][t]}))
        print(f"| {name} | " + " | ".join(cells) + " | " + " | ".join(ratios) + f" | {routes} |")
    meds = {t: st.median([s for s in score[t] if s is not None]) for t in trees if any(s is not None for s in score[t])}
    print("| **score** | " + " | ".join(", ".join(str(s) for s in score[t]) + (f" (**{meds[t]}**)" if t in meds else "") for t in trees) + " | " +
          " | ".join(f"**{meds[t] / meds['main']:.3f}**" if t in meds and "main" in meds else "–" for t in trees if t != "main") + " | |")
    print()

def prof():
    fs = sorted(glob.glob(os.path.join(d, "prof_*.log")))
    if not fs:
        return
    acc = defaultdict(lambda: defaultdict(float)); nf = defaultdict(int)
    keys = ["device_wall", "upload", "inputs", "top", "bucket", "join", "check", "read", "probe", "unattributed", "setup",
            "tops", "listed", "pairs", "padded_pairs", "survivors", "checked", "ntlay", "nbp", "slices", "batches"]
    for f in fs:
        tree = re.match(r"prof_(\w+)\.log", os.path.basename(f))[1]
        for line in open(f):
            if "GPU_PROFILE" in line:
                x = kv(line[line.index("GPU_PROFILE"):]); b = int(x["base"])
                if float(x.get("size", 0)) < 1e15:  # the 1e14 warm-up field
                    continue
                for k in keys:
                    if k in x:
                        acc[(tree, b)][k] += float(x[k])
                acc[(tree, b)]["ept"] = float(x.get("ept", 0))
                nf[(tree, b)] += 1
    if not nf:
        return
    print("### Profiled phase split (NICE_EXP_GPU_PROFILE=1), seconds per field (mean of the fields)\n")
    print("| base | tree | ept | device (profiled) | top | bucket | join | check | other | listed/field | pairs/field | padded/pairs | survivors/field | checked/field |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for (tree, b) in sorted(nf, key=lambda k: (k[1], k[0])):
        a = acc[(tree, b)]; n = nf[(tree, b)]
        dev = a["device_wall"] / n
        ph = {k: a[k] / n for k in ("top", "bucket", "join", "check")}
        other = dev - sum(ph.values())
        pct = lambda v: f"{v:.2f} ({v / dev * 100:.1f} %)"
        print(f"| {b} | {tree} | {a['ept']:.0f} | {dev:.2f} | {pct(ph['top'])} | {pct(ph['bucket'])} | {pct(ph['join'])} | {pct(ph['check'])} | {pct(other)} | "
              f"{a['listed'] / n:.3e} | {a['pairs'] / n:.3e} | {a['padded_pairs'] / max(a['pairs'], 1):.2f} | {a['survivors'] / n:.3e} | {a['checked'] / n:.3e} |")
    print()
    print("| base | phase | main s | PR s | saved s | share of the saving |")
    print("|---|---|---|---|---|---|")
    for b in sorted({k[1] for k in nf}):
        if ("xmain", b) not in nf or ("xpr", b) not in nf:
            continue
        am, ap = acc[("xmain", b)], acc[("xpr", b)]; nm, npr = nf[("xmain", b)], nf[("xpr", b)]
        tot = am["device_wall"] / nm - ap["device_wall"] / npr
        for k in ("top", "bucket", "join", "check"):
            sv = am[k] / nm - ap[k] / npr
            print(f"| {b} | {k} | {am[k] / nm:.2f} | {ap[k] / npr:.2f} | {sv:+.2f} | {sv / tot * 100 if tot else 0:.0f} % |")
        om = am["device_wall"] / nm - sum(am[k] / nm for k in ("top", "bucket", "join", "check"))
        op = ap["device_wall"] / npr - sum(ap[k] / npr for k in ("top", "bucket", "join", "check"))
        print(f"| {b} | other | {om:.2f} | {op:.2f} | {om - op:+.2f} | {(om - op) / tot * 100 if tot else 0:.0f} % |")
        print(f"| {b} | **device** | {am['device_wall'] / nm:.2f} | {ap['device_wall'] / npr:.2f} | {tot:+.2f} | 100 % |")
    print()

thr(); thr("x14", "Production size: 20 fields of 1e14 per base (s/field)"); overran(); nicemark(); prof()

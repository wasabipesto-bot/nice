#!/usr/bin/env python3
"""Breakdown table: python3 bd.py LOGDIR (the box's logs/bd)."""
import os, re, statistics as st, sys
D = sys.argv[1]
gp = re.compile(r"GPU_PROFILE base=(\d+) .*?size=10000000000000000 .*?device_wall=([\d.]+) .*?top=([\d.]+) topk=([\d.]+) bucket=([\d.]+) join=([\d.]+) check=([\d.]+) .*?probe=([\d.]+) .*?ntlay=(\d+) .*?tops=(\d+)")
names = ["s1", "s2", "s3", "s4", "s5", "s6", "s7", "s0", "diff", "bar", "both"]
label = {"s1": "1: a, e, clip", "s2": "2: + a^j, e^j (powers16)", "s3": "3: + d = e^j - a^j, ndig(d)",
         "s4": "4: + long division of a^j", "s5": "5: + digits, run/dup selects, rem", "s6": "6: + carry test",
         "s7": "7: + closure (no bookkeeping)", "s0": "0: whole kernel", "diff": "cand. (a) diff powers",
         "bar": "cand. (b) MG/Barrett digits", "both": "(a) + (b)"}
for base in (62, 60):
    rows = {}
    for n in names:
        vals = []
        for r in (1, 2, 3):
            p = f"{D}/{n}_b{base}_r{r}.log"
            if not os.path.exists(p):
                continue
            ms = [m for m in gp.finditer(open(p).read()) if int(m[1]) == base]
            if ms:
                m = ms[-1]  # the 1e16 field (the warm-up is first)
                vals.append(dict(dev=float(m[2]), top=float(m[3]), topk=float(m[4]), tops=int(m[10]), ntlay=int(m[9])))
        if vals:
            rows[n] = vals
    if "s0" not in rows:
        continue
    s0 = st.mean(v["topk"] for v in rows["s0"])
    dev0 = st.mean(v["dev"] for v in rows["s0"])
    top0 = st.mean(v["top"] for v in rows["s0"])
    print(f"\n### b{base} 1e16, 1 field (profiled; means of {len(rows['s0'])} rounds)\n")
    print(f"whole field (profiled device wall) {dev0:.2f} s; top phase {top0:.2f} s; top_kernel {s0:.2f} s; scan+fill {top0 - s0:.2f} s; certified tops {rows['s0'][0]['tops']}\n")
    print("| variant | top_kernel s (rounds) | step s | step share of top_kernel |")
    print("|---|---|---|---|")
    prev = 0.0
    for n in names:
        if n not in rows:
            continue
        t = [v["topk"] for v in rows[n]]
        m = st.mean(t)
        if n.startswith("s") and n != "s0":
            step = m - prev; prev = m
            print(f"| {label[n]} | {m:.3f} ({', '.join(f'{x:.3f}' for x in t)}) | {step:+.3f} | {step / s0 * 100:.1f} % |")
        elif n == "s0":
            step = m - prev
            print(f"| {label[n]} | {m:.3f} ({', '.join(f'{x:.3f}' for x in t)}) | {step:+.3f} (bookkeeping) | {step / s0 * 100:.1f} % |")
            prev = m
        else:
            print(f"| {label[n]} | {m:.3f} ({', '.join(f'{x:.3f}' for x in t)}) | ×{m / s0:.3f} of whole | top phase {st.mean(v['top'] for v in rows[n]):.3f} s, tops {rows[n][0]['tops']} |")

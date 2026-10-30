#!/usr/bin/env python3
"""Tables from the box logs: python3 analyze.py box/"""
import re, sys, glob, os, statistics as st, json
D = sys.argv[1] if len(sys.argv) > 1 else "box"
PAT = re.compile(r"JOIN THROUGHPUT .*base=(\d+) .*per_field=([\d.]+) .*device=([\d.]+)s .*batches=(\d+) slots=(\d+) plan_mib=(\d+) .*retried=(\d+) splits=(\d+) survivors=(\d+) checked=(\d+) found=(\d+)")

def parse(path):
    out = {}
    for line in open(path, errors="replace"):
        m = PAT.search(line)
        if m:
            b = int(m.group(1))
            out[b] = dict(pf=float(m.group(2)), dev=float(m.group(3)), batches=int(m.group(4)),
                          slots=int(m.group(5)), mib=int(m.group(6)), retried=int(m.group(7)),
                          surv=int(m.group(9)), chk=int(m.group(10)), found=int(m.group(11)))
    return out

def smi_mem(path):
    try:
        vals = [int(l.split(",")[5].strip().split()[0]) for l in open(path).readlines()[1:] if l.count(",") >= 5]
        return max(vals) if vals else None
    except Exception:
        return None

def table(size, bud, rounds=3, trees=("main", "pr"), prefix="e"):
    runs = {t: [parse(f"{D}/{prefix}{size}_{bud}_{t}_r{r}.log") for r in range(1, rounds + 1)
                if os.path.exists(f"{D}/{prefix}{size}_{bud}_{t}_r{r}.log")] for t in trees}
    mem = {t: [smi_mem(f"{D}/{prefix}{size}_{bud}_{t}_r{r}.smi") for r in range(1, rounds + 1)] for t in trees}
    print(f"\n### {prefix}{size}: 1e{size}, budget {bud}, {trees[0]} vs {trees[1]} ({len(runs[trees[0]])}/{len(runs[trees[1]])} rounds)\n")
    print("| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |")
    print("|---|---|---|---|---|---|---|---|---|")
    for b in (58, 60, 62, 64):
        cells = []
        med = {}
        for t in trees:
            xs = [r[b]["pf"] for r in runs[t] if b in r]
            if not xs:
                cells += ["-", "-"]; continue
            med[t] = st.median(xs)
            cells.append(f"**{med[t]:.3f}** ({', '.join(f'{x:.3f}' for x in xs)})")
            cells.append(f"{(max(xs)-min(xs))/med[t]*100:.1f} %")
        ratio = f"**×{med[trees[1]]/med[trees[0]]:.3f}**" if len(med) == 2 else "-"
        def first(t, k):
            for r in runs[t]:
                if b in r: return r[b][k]
            return "-"
        def rng(t, k):
            v = sorted({r[b][k] for r in runs[t] if b in r})
            return "/".join(str(x) for x in v) if v else "-"
        print(f"| {b} | {cells[0]} | {cells[1]} | {cells[2]} | {cells[3]} | {ratio} | {rng(trees[0],'slots')} → {rng(trees[1],'slots')} | {rng(trees[0],'batches')} → {rng(trees[1],'batches')} | {rng(trees[0],'mib')} → {rng(trees[1],'mib')} |")
    print("\nPeak nvidia-smi memory.used (MiB) per run: " + "; ".join(f"{t}: {mem[t]}" for t in trees))
    print("\nCounters (survivors / checked / found) per run:\n")
    for b in (58, 60, 62, 64):
        for t in trees:
            print(f"- b{b} {t}: " + "; ".join(f"{r[b]['surv']} / {r[b]['chk']} / {r[b]['found']}" for r in runs[t] if b in r))

if __name__ == "__main__":
    for bud in ("B10", "B20"):
        table("14", bud, trees=("main", "pr64"), prefix="f")
    for bud in ("B10", "B20"):
        table("14", bud)
    for bud in ("B10", "B20"):
        table("16", bud)
    table("16", "B10", trees=("main", "barrier"))
    table("16", "B10", trees=("pr", "barrier"))

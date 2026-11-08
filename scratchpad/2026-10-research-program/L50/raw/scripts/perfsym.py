#!/usr/bin/env python3
"""Per-symbol cycles / instructions / branch-misses from a perf.data with the
three events; prints shares, IPC and mispredictions per 1k instructions.
usage: perfsym.py <perf.data> [top N]"""
import subprocess, sys, re, collections
path = sys.argv[1]
top = int(sys.argv[2]) if len(sys.argv) > 2 else 25
out = subprocess.run(['perf', 'report', '-i', path, '--stdio', '--no-children', '--sort', 'symbol',
                      '--percent-limit', '0.05'], capture_output=True, text=True).stdout
ev = None
tot = {}
pct = collections.defaultdict(dict)
for line in out.splitlines():
    m = re.match(r"# Samples: .* of event '([^']+)'", line)
    if m:
        ev = m.group(1).split(':')[0]
        continue
    m = re.match(r"# Event count \(approx\.\): (\d+)", line)
    if m and ev:
        tot[ev] = int(m.group(1))
        continue
    if line.startswith('#') or not line.strip() or ev is None:
        continue
    m = re.match(r"\s*([\d.]+)%\s+\[[.k]\]\s+(.*)$", line)
    if m:
        sym = m.group(2).split()[0][:100]
        sym = re.sub(r'::h[0-9a-f]{16}$', '', sym)
        pct[sym][ev] = pct[sym].get(ev, 0) + float(m.group(1))
cyc, ins, bm = tot.get('cycles', 0), tot.get('instructions', 0), tot.get('branch-misses', 0)
print(f"totals: cycles {cyc:.4e} instructions {ins:.4e} IPC {ins/max(cyc,1):.2f} branch-misses {bm:.4e} ({1000*bm/max(ins,1):.2f} per 1k instr)")
print(f"{'%cyc':>6} {'%ins':>6} {'%brm':>6} {'IPC':>5} {'brm/ki':>6}  symbol")
rows = sorted(pct.items(), key=lambda kv: -kv[1].get('cycles', 0))
for sym, d in rows[:top]:
    c, i, b = d.get('cycles', 0), d.get('instructions', 0), d.get('branch-misses', 0)
    ipc = (i * ins) / (c * cyc) if c and cyc else 0
    bpk = 1000 * (b * bm) / (i * ins) if i and ins else 0
    print(f"{c:6.2f} {i:6.2f} {b:6.2f} {ipc:5.2f} {bpk:6.2f}  {sym[:110]}")

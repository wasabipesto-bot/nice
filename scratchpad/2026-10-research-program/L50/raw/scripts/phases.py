#!/usr/bin/env python3
"""Group perfsym's per-symbol shares into the join's phases.
usage: phases.py <perf.data>..."""
import subprocess, sys, re, collections
groups = [
    ('scan (AND + extraction)', ['9scan_avx2', '9scan_avx512', '8scan_any']),
    ('survivor (range + prefilter)', ['8survivor']),
    ('full check', ['get_is_nice', 'l50_check']),
    ('top cert (FD read)', ['TopFdSetup4cert']),
    ('top step', ['TopFdSetup4step']),
    ('top seed', ['to_digits', 'cpu_top_fd3sum', 'TopFdSetup4seed', 'divrem_w4', 'shl_digits', 'digit_at']),
    ('tops loop + dh', ['CpuJoin4tops', 'Fx2dh']),
    ('sort tops', ['quicksort', 'smallsort', 'sort_tops']),
    ('list + advance', ['CpuJoin4list', 'CpuJoin7advance']),
    ('extend', ['CpuJoin6extend']),
    ('closure (tops/extend/list/sort inlined)', ['rust_begin_short_backtrace']),
]
for path in sys.argv[1:]:
    out = subprocess.run(['perf', 'report', '-i', path, '--stdio', '--no-children', '--sort', 'symbol',
                          '--percent-limit', '0.01'], capture_output=True, text=True).stdout
    ev = None; tot = {}; acc = collections.defaultdict(lambda: collections.Counter())
    for line in out.splitlines():
        m = re.match(r"# Samples: .* of event '([^']+)'", line)
        if m:
            ev = m.group(1).split(':')[0]; continue
        m = re.match(r"# Event count \(approx\.\): (\d+)", line)
        if m and ev:
            tot[ev] = int(m.group(1)); continue
        if line.startswith('#') or not line.strip() or ev is None:
            continue
        m = re.match(r"\s*([\d.]+)%\s+\[[.k]\]\s+(\S+)", line)
        if not m:
            continue
        sym, p = m.group(2), float(m.group(1))
        g = next((name for name, keys in groups if any(k in sym for k in keys)), 'other')
        acc[g][ev] += p
    cyc, ins, bm = tot.get('cycles', 1), tot.get('instructions', 1), tot.get('branch-misses', 1)
    print(f"## {path.split('/')[-1]}: IPC {ins/cyc:.2f}, {1000*bm/ins:.2f} branch-misses per 1k instructions")
    print("| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |")
    print("|---|---|---|---|---|---|")
    for name in [g for g, _ in groups] + ['other']:
        d = acc.get(name)
        if not d or d['cycles'] < 0.05:
            continue
        c, i, b = d['cycles'], d['instructions'], d['branch-misses']
        print(f"| {name} | {c:.1f} | {i:.1f} | {b:.1f} | {i*ins/(c*cyc):.2f} | {1000*b*bm/max(i*ins,1):.1f} |")
    print()

#!/usr/bin/env python3
"""Phase shares from GPU_PROFILE lines (NICE_EXP_GPU_PROFILE=1). python3 prof.py LOG... (warm-up 1e14 fields skipped
unless the run itself is 1e14). Shares are of profiled device time excluding the probe; other = upload + inputs + read +
unattributed."""
import re, sys
for path in sys.argv[1:]:
    rows = []
    for line in open(path, errors='replace'):
        if 'GPU_PROFILE' not in line:
            continue
        d = dict((k, float(v)) for k, v in re.findall(r'\b(\w+)=([0-9.]+(?:e[+-]?\d+)?)\b', line[line.index('GPU_PROFILE'):]))
        rows.append(d)
    big = [r for r in rows if r.get('size', 0) > 1e14] or rows
    tot = {k: sum(r.get(k, 0) for r in big) for k in ['device_wall', 'probe', 'top', 'bucket', 'join', 'check', 'upload', 'inputs', 'read', 'unattributed', 'setup', 'pairs', 'padded_pairs', 'tops', 'listed', 'live_buckets', 'survivors', 'checked', 'spilled']}
    dev = tot['device_wall'] - tot['probe']
    other = tot['upload'] + tot['inputs'] + tot['read'] + tot['unattributed']
    sh = lambda x: f'{x:.2f} s ({100 * x / dev:.1f} %)'
    print(f'{path.split("/")[-1]}: fields={len(big)} device(excl probe)={dev:.2f} s probe={tot["probe"]:.2f} setup={tot["setup"]:.2f} | top {sh(tot["top"])} | bucket {sh(tot["bucket"])} | join {sh(tot["join"])} | check {sh(tot["check"])} | other {sh(other)}')
    print(f'    tops={tot["tops"]:.4g} listed={tot["listed"]:.4g} pairs={tot["pairs"]:.4g} padded={tot["padded_pairs"]:.4g} live_buckets={tot["live_buckets"]:.4g} survivors={int(tot["survivors"])} checked={int(tot["checked"])} spilled={int(tot["spilled"])}')

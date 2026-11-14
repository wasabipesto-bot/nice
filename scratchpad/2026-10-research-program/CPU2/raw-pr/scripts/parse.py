#!/usr/bin/env python3
"""Summarise /root/out/r*-*.err: per run wall, join run_secs, setup, survivors,
checked, hits, peak RSS, RSS after the join; per case the speed-ups."""
import glob, json, re, sys, statistics as st
d = sys.argv[1] if len(sys.argv) > 1 else '/root/out'
rows = {}
for f in sorted(glob.glob(d + '/r*-*.err')):
    m = re.match(r'.*/r(\d+)-(.+)-(main|br)\.err$', f)
    if not m: continue
    r, tag, bin = int(m[1]), m[2], m[3]
    t = open(f).read()
    j = re.search(r'MEASURE after-join (.*?) threads=(\d+) join=(\{.*\})', t)
    wall = re.search(r'Elapsed \(wall clock\) time \(h:mm:ss or m:ss\): (\S+)', t)
    hwm = re.search(r'Maximum resident set size \(kbytes\): (\d+)', t)
    if not (j and wall and hwm): 
        print('incomplete', f); continue
    js = json.loads(j[3])
    mem = dict(re.findall(r'(VmRSS|VmHWM): (\d+)', j[1]))
    w = wall[1].split(':'); ws = sum(float(x) * 60 ** i for i, x in enumerate(reversed(w)))
    sub = open(f[:-4] + '.submit').read().strip().splitlines() if glob.glob(f[:-4] + '.submit') else []
    hits = json.loads(sub[-1])['nice_numbers'] if sub else None
    rows.setdefault(tag, {}).setdefault(bin, {})[r] = dict(run=js.get('run_secs'), setup=js.get('setup_secs'),
        surv=js.get('survivors'), chk=js.get('checked'), hits=hits, wall=ws, hwm=int(hwm[1]),
        rss_after=int(mem.get('VmRSS', 0)), threads=int(j[2]))
for tag, by in rows.items():
    print(f'== {tag}')
    for bin in ('main', 'br'):
        for r, x in sorted(by.get(bin, {}).items()):
            print(f'  {bin:4} r{r}: run {x["run"]:.2f}s wall {x["wall"]:.1f}s setup {x["setup"]:.2f}s threads {x["threads"]} '
                  f'surv {x["surv"]} chk {x["chk"]} hits {x["hits"]} peakRSS {x["hwm"]/1024:.0f}MB rss-after {x["rss_after"]/1024:.0f}MB')
    rs = sorted(set(by.get('main', {})) & set(by.get('br', {})))
    if rs:
        m = [by['main'][r]['run'] for r in rs]; b = [by['br'][r]['run'] for r in rs]
        same = all((by['main'][r]['surv'], by['main'][r]['chk'], by['main'][r]['hits']) == (by['br'][r]['surv'], by['br'][r]['chk'], by['br'][r]['hits']) for r in rs)
        print(f'  speed-up (join run_secs) medians x{st.median(m)/st.median(b):.3f}, minimums x{min(m)/min(b):.3f}, per round '
              + ' '.join(f'{by["main"][r]["run"]/by["br"][r]["run"]:.3f}' for r in rs)
              + f'; spread main {(max(m)-min(m))/st.median(m)*100:.1f}% br {(max(b)-min(b))/st.median(b)*100:.1f}%; counts identical: {same}')

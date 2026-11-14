#!/usr/bin/env python3
"""Task 1 table from profile_b*.txt (cpu2_prof PART lines).
top share = full_ns / total_ns (tops() timed alone after the partition);
seeding = seeds x (seedall_ns / unclipped); stepping = adv_ns - seeding;
certificate = cert_ns - adv_ns; append (+ Top build) = full_ns - cert_ns."""
import re, sys, statistics as st
for f in sys.argv[1:]:
    rows = []
    for line in open(f):
        if not line.startswith('PART'):
            continue
        kv = dict(re.findall(r'(\w+) (\d+)', line.split('|', 1)[0]))
        parts = line.split('|')
        def g(seg, key):
            return int(re.search(key + r' (\d+)', parts[seg]).group(1))
        total = int(kv['total_ns'])
        full = g(1, 'full_ns'); adv = g(2, 'adv_ns'); un = g(2, 'unclipped')
        seeds = g(2, 'seeds'); steps = g(2, 'steps'); cert = g(3, 'cert_ns'); sa = g(4, 'seedall_ns')
        if un == 0:
            print("  (no top-layer prefixes:", line.split("|")[0].strip(), ")"); continue
        seed_cost = sa / un
        seeding = seeds * seed_cost
        rows.append(dict(tag=line.split()[1] + ' ' + line.split()[2] + ' ' + line.split()[3],
            total=total, full=full, share=full / total, seeding=seeding / total,
            stepping=(adv - seeding) / total, cert=(cert - adv) / total, append=(full - cert) / total,
            seed_ns=seed_cost, step_ns=(adv - seeding) / max(steps, 1), cert_ns=(cert - adv) / un,
            per_prefix=full / un, steps_pp=steps / un, seeds_pp=seeds / un, tops_pp=g(1, 'tops') / un))
    print(f'== {f}: {len(rows)} partitions')
    print('  tag                 total_s  top%   seed%  step%  cert%  app%   ns/prefix seed_ns step_ns cert_ns steps/pfx seeds/pfx pass')
    for r in rows:
        print(f"  {r['tag']:20s} {r['total']/1e9:6.3f} {100*r['share']:5.1f}  {100*r['seeding']:5.1f}  {100*r['stepping']:5.1f}  {100*r['cert']:5.1f}  {100*r['append']:5.1f}  {r['per_prefix']:8.1f} {r['seed_ns']:7.0f} {r['step_ns']:7.1f} {r['cert_ns']:7.1f} {r['steps_pp']:8.2f} {r['seeds_pp']:8.3f} {r['tops_pp']:.3f}")
    T = sum(r['total'] for r in rows)
    def pooled(k):
        return sum(r[k] * r['total'] for r in rows) / T
    sh = [r['share'] for r in rows]
    print(f"  pooled (time-weighted): top {100*pooled('share'):.1f} % (min {100*min(sh):.1f}, median {100*st.median(sh):.1f}, max {100*max(sh):.1f}); "
          f"seeding {100*pooled('seeding'):.1f}, stepping {100*pooled('stepping'):.1f}, certificate {100*pooled('cert'):.1f}, append {100*pooled('append'):.1f}")

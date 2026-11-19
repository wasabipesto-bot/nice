#!/usr/bin/env python3
"""FS review pricing.  Inputs: exact level counts (raw/levels_*.txt, measured), the trunk's measured per-slice
stage times (BUILD-NOTES §9.4 b64, §11.4 b65; RTX 3080 at 240 W), prep split from TUNE-RESULTS (root pass ~65 %,
per-parent ~35 %, a 9070 XT model: GUESS for the 3080).  Labels: [M] measured, [D] derived, [G] guessed."""
import re
def levels(path):
    rows = []
    for line in open(path):
        d = dict((int(a), int(b)) for a, b in re.findall(r'd(\d+)=(\d+)', line))
        rows.append(d)
    # mean over slices
    keys = rows[0].keys()
    return {k: sum(r[k] for r in rows) / len(rows) for k in keys}
ROOT_SHARE = (0.55, 0.65, 0.75)   # [G] share of prep that is proportional to roots processed
for b, path, k, stage in ((64, 'raw/levels_b64.txt', 10, dict(tops=0.361, prep=0.671, kernel=5.459, exp=1.108, chk=0.120)),
                          (65, 'raw/levels_b65.txt', 10, dict(tops=1.80, prep=1.42, kernel=6.72, exp=3.71, chk=0.17)),
                          (68, 'raw/levels_b68.txt', 10, None)):
    L = levels(path); f0 = 4; top = k - 2   # deepest forced digit of the slice key (d8)
    roots = L[f0]
    steps_now = sum(L[j] for j in range(f0, k - 1))           # extension steps per slice, today [M]
    items = {'today (no sharing)': roots,
             'F678 + depth-5 lists per d4 (piece L)': L[f0 + 1] + roots / b,
             'F567, depth-8 survivor lists per d4, d8 inner': L[top] + roots / b}
    steps = {'today (no sharing)': steps_now,
             'F678 + depth-5 lists per d4 (piece L)': sum(L[j] for j in range(f0 + 1, k - 1)) + roots / b,
             'F567, depth-8 survivor lists per d4, d8 inner': L[top] + sum(L[j] for j in range(f0, top)) / b}
    print(f"b{b} (4,{k}) per slice [M]: roots d4 {roots:,.0f}; " + ' '.join(f"d{j} {L[j]:,.0f}" for j in range(f0+1, k)) +
          f"; extension steps today {steps_now:,.0f}")
    for name in items:
        print(f"   {name:48s} roots processed {items[name]/1e6:6.2f}M ({items[name]/roots:5.1%})  steps {steps[name]/1e6:6.2f}M ({steps[name]/steps_now:5.1%})")
    if stage:
        tot = sum(stage.values()); share = (stage['tops'] + stage['prep']) / tot
        print(f"   slice {tot:.2f} ms [M]; tops+prep {stage['tops']+stage['prep']:.2f} ms = {share:.1%}: max gain of ANY grouping at fixed shape x{1/(1-share):.3f} [D]")
        for name in items:
            fr = items[name] / roots
            sav = [stage['prep'] * rs * (1 - fr) for rs in ROOT_SHARE]
            print(f"   {name:48s} prep saving {min(sav):.2f}-{max(sav):.2f} ms/slice = {min(sav)/tot:.1%}-{max(sav)/tot:.1%} [D/G]")
    # memory for F567 survivor-index lists (4 B per root index, all b values of d4 held)
    print(f"   F567 survivor-index lists for all {b} d4 values: {b*L[top]*4/1e9:.2f} GB at 4 B/entry [D]")

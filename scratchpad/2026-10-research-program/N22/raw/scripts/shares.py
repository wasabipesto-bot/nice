#!/usr/bin/env python3
"""shares.py: task 1, where a field's time goes on the RX 9070 XT after the five PRs (exp/integration-1114), derived
from measured card numbers (every input cited below; [M] measured on the card, [A] an assumption). Prints seconds and
shares per part at b62 1e17 and b64 1e17. python3 -I shares.py"""

def show(name, parts, check_total):
    tot = sum(parts.values())
    print(f"== {name}: total {tot:.1f} s (multiplicative estimate from the PR gains: {check_total:.1f} s)")
    for k, v in sorted(parts.items(), key=lambda x: -x[1]):
        print(f"   {k:34s} {v:6.1f} s  {100 * v / tot:5.1f} %")

# ---- b62 1e17 ----
T = 73.0                     # [M] main a7a59c1 on the card, N21.2 (72.74, 73.33)
sh = dict(prefilter=.259, check=.163, AND=.111, walk=.061, tcopy=.009)   # [M] N17.1 doubling shares (73.5 s tree)
p = {k: v * T for k, v in sh.items()}
# [M] N13 mode c (main c0c357a, profiled): top FD 18.21 s, bucket 3.17 s, upload 2.71 s; #250 then x1.041 on the card
# (N13.1), its change being the top kernel's stepped slot counts: [A] all of it in the top phase.
p['top FD'] = 18.21 - 75.7 * (1 - 1 / 1.041)
p['bucket'] = 3.17
p['upload+host'] = 2.71
rest = T - sum(p.values())
p['join base (loads, entry waves, stage, flush)'] = 5.0          # [A] of the rest, the join kernel's own base
p['other (clipped tops, launches)'] = rest - 5.0
# #251: x1.12 against main on the card (N21.2: 72.74 -> 64.94, 73.33 -> 65.09): [A] all in the check.
p['check'] -= 73.0 - 65.0
# #256 (+ #255, identical code at b62): main 73.0 -> 68.5 (N21.2), occupancy 12 -> 16 waves: [A] spread over the
# join kernel's parts in proportion.
J = ['prefilter', 'AND', 'walk', 'tcopy', 'join base (loads, entry waves, stage, flush)']
js = sum(p[k] for k in J); f = (js - 4.5) / js
for k in J: p[k] *= f
# #259: x1.037 at b62 (N21.2, three rounds): all in the prefilter (the test it changes).
p['prefilter'] -= 68.5 * (1 - 1 / 1.037)
show('b62 1e17, integration (derived)', p, 68.5 / 1.037 / 1.12)

# ---- b64 1e17 ----
Told = 151.6                 # [M] N17.1's tree at b64 (before #254), its doubling shares
q = dict(prefilter=.304 * Told, check=.175 * Told, AND=.105 * Told, walk=.080 * Told)
Tm = 136.5                   # [M] main a7a59c1 at b64, N21.2 (N17.1: 135.2)
# #254 (FD tops at b64) took 151.6 -> ~136: the old top minus the new. [A] the card's top falls by the RTX 3080's
# ratio (B64 sec. 5.1: 16.7 % of a field before, 8.4 % of a x1.13 faster field after: x0.445).
d = Told - Tm; top_old = d / (1 - 0.445); q['top FD'] = top_old * 0.445
q['join base (loads, entry waves, stage, flush)'] = 8.0          # [A]
q['bucket, upload, host, other'] = Tm - sum(q.values())
q['check'] -= 136.5 - 120.3                                       # #251 x1.135 (N21.2), [A] all in the check
q['prefilter'] -= 150.16 - 142.90                                 # #255 x1.051 (N17.1, binary P), the prefilter's digits
J = ['prefilter', 'AND', 'walk', 'join base (loads, entry waves, stage, flush)']
js = sum(q[k] for k in J); rem = (136.5 - 117.7) - (150.16 - 142.90); f = (js - rem) / js
for k in J: q[k] *= f                                             # #256: the rest of #255+#256's 18.8 s, occupancy
q['prefilter'] -= 117.7 * (1 - 1 / 1.080)                          # #259 x1.080 (N21.2, one round)
show('b64 1e17, integration (derived)', q, 117.7 / 1.080 / 1.135)

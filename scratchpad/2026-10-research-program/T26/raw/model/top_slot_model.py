#!/usr/bin/env python3
"""Host model of the top FD kernel's per-plane append (`top_slot`), main's (lane 0) and the fix's (lowest kept lane),
over random plane populations, with the fix's account (kept - reserved, written index sum - reserved index sum, mod
2^32) as the host checks it. One slot; several planes of a cube append into shared group counters in random order.

Populations: full, a prefix (partly filled plane: lanes 0..r-1), no lane 0, random holes. Lanes' groups: one group
(the common case), two groups (a plane straddling a group boundary), random groups; dead lanes (live=false) carry g=0.
Variants of the fix: ballot form (width <= 32), scan form (any width), ballot form on a 64-lane plane misreported as 32
(the ballot holds lanes 0-31 only, the shift `1 << lane` masks to lane mod 32 as in WGSL), and either form without
reconvergence after the leader's `if` (lanes other than the leader read the atomic's result before it is written: 0).

A run is WRONG when any kept top is not at a record of its own inside its group's counted range, or a counted record is
not written exactly once. It is UNDETECTED when wrong and the account is zero.
python3 top_slot_model.py [trials] [seed]"""
import random, sys
M = 1 << 32
UNDEF = object()

def plane_lanes(rng, width):
    kind = rng.choice(['full', 'prefix', 'nolane0', 'holes'])
    if kind == 'full':
        act = list(range(width))
    elif kind == 'prefix':
        act = list(range(rng.randint(1, width)))
    elif kind == 'nolane0':
        act = [l for l in range(1, width) if rng.random() < 0.8] or [width - 1]
    else:
        act = [l for l in range(width) if rng.random() < 0.6] or [rng.randrange(width)]
    return kind, act

def make_plane(rng, width, ngroups):
    kind, act = plane_lanes(rng, width)
    gk = rng.choice(['one', 'two', 'rand'])
    g0 = rng.randrange(ngroups)
    cut = rng.randint(0, width)
    lanes = {}
    for l in range(width):
        live = rng.random() < 0.9
        if gk == 'one':
            g = g0
        elif gk == 'two':
            g = g0 if l < cut else (g0 + 1) % ngroups
        else:
            g = rng.randrange(ngroups)
        kept = live and rng.random() < 0.5
        lanes[l] = dict(g=g if live else 0, kept=kept, active=l in act)
    return kind, lanes

def old_slot(lanes, cnt, undef_mode, rng):
    """main's top_slot (ballot form, width <= 32). Returns {lane: at} for kept active lanes."""
    P = [l for l in lanes if lanes[l]['active']]
    def bcast(val_of_lane0):
        if 0 in P:
            return val_of_lane0
        # inactive source lane: undefined. 'stale' = lane 0's own register (llvmpipe-like), 'rand' = garbage
        return val_of_lane0 if undef_mode == 'stale' else rng.randrange(64)
    g0 = bcast(lanes[0]['g'])
    one = all((not lanes[l]['kept']) or lanes[l]['g'] == g0 for l in P)
    kb = [l for l in P if lanes[l]['kept'] and one]
    n = len(kb)
    a0 = {l: 0 for l in lanes}
    if 0 in P and n > 0:
        a0[0] = cnt[g0]; cnt[g0] += n
    a = bcast(a0[0])
    out = {}
    for l in P:
        if not lanes[l]['kept']:
            continue
        if one:
            out[l] = (lanes[l]['g'], a + sum(1 for k in kb if k < l))
        else:
            g = lanes[l]['g']; out[l] = (g, cnt[g]); cnt[g] += 1
    return out, (0, 0)

def new_slot(lanes, cnt, form, misreport, noreconv, base_of):
    """the fix. form 'ballot' or 'scan'. Returns ({lane: (g, at)}, account delta)."""
    P = sorted(l for l in lanes if lanes[l]['active'])
    kept = {l: lanes[l]['kept'] for l in P}
    if form == 'ballot':
        # the ballot's first word: lanes 0-31 only
        kb = [l for l in P if kept[l] and l < 32]
        n = len(kb)
        def rank(l):
            sh = l % 32 if misreport else l
            return sum(1 for k in kb if k < sh)
        src = min(kb) if kb else None
        lead = {l: kept[l] and rank(l) == 0 for l in P}
        def shuffle(vals, l):
            s = src if src is not None else l
            return vals[s]
    else:
        n = sum(1 for l in P if kept[l])
        def rank(l):
            return sum(1 for k in P if k < l and kept[k])
        lead = {l: kept[l] and rank(l) == 0 for l in P}
        def shuffle(vals, l):
            return sum(vals[k] for k in P) % M
    gvals = {l: (lanes[l]['g'] if (form == 'ballot' or lead.get(l, False)) else 0) for l in lanes}
    g0 = {l: shuffle(gvals, l) for l in P}
    one = all((not kept[l]) or lanes[l]['g'] == g0[l] for l in P)
    a0 = {l: 0 for l in lanes}
    dn = ds = 0
    for l in P:
        if lead[l] and one:
            g = g0[l]
            a0[l] = cnt[g]; cnt[g] += n
            r0 = base_of(g) + a0[l]
            dn -= n; ds -= n * r0 + n * (n - 1) // 2
    out = {}
    for l in P:
        a = 0 if (noreconv and not lead[l]) else shuffle(a0, l)
        if not kept[l]:
            continue
        g = lanes[l]['g']
        if one:
            at = a + rank(l)
            dn += 1; ds += base_of(g) + at
        else:
            at = cnt[g]; cnt[g] += 1
        out[l] = (g, at)
    return out, (dn % M, ds % M)

def run(variant, trials, seed):
    rng = random.Random(seed)
    wrong = undetected = false_alarm = 0
    for _ in range(trials):
        ngroups = rng.choice([1, 2, 4])
        width = variant.get('width', 32)
        planes = [make_plane(rng, width, ngroups) for _ in range(rng.randint(1, 6))]
        cnt = [0] * ngroups
        # group segments: room for every lane of every plane
        seg = width * len(planes)
        base_of = lambda g: g * seg
        written = []
        dn = ds = 0
        rng.shuffle(planes)
        want = [0] * ngroups
        for kind, lanes in planes:
            for l, x in lanes.items():
                if x['kept'] and (x['active'] or variant['name'].startswith('old')):
                    # an inactive lane does not run the append in this model's populations (it sits out)
                    pass
            # tops a correct append must place: the kept lanes that run it
            for l, x in lanes.items():
                if x['kept'] and x['active']:
                    want[x['g']] += 1
            if variant['name'].startswith('old'):
                out, acc = old_slot(lanes, cnt, variant['undef'], rng)
            else:
                out, acc = new_slot(lanes, cnt, variant['form'], variant.get('misreport', False),
                                    variant.get('noreconv', False), base_of)
            for l, (g, at) in out.items():
                written.append((g, at))
            dn = (dn + acc[0]) % M; ds = (ds + acc[1]) % M
        ok = cnt == want and sorted(written) == sorted((g, i) for g in range(ngroups) for i in range(cnt[g]))
        if not ok:
            wrong += 1
            if not variant['name'].startswith('old') and dn == 0 and ds == 0:
                undetected += 1
        elif not variant['name'].startswith('old') and (dn or ds):
            false_alarm += 1
    return wrong, undetected, false_alarm

if __name__ == '__main__':
    trials = int(sys.argv[1]) if len(sys.argv) > 1 else 20000
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    V = [
        dict(name='old main, ballot, inactive lane-0 reads = lane 0 register (stale)', undef='stale'),
        dict(name='old main, ballot, inactive lane-0 reads = garbage', undef='rand'),
        dict(name='fix ballot, widths <= 32', form='ballot', width=32),
        dict(name='fix ballot, 8-lane planes', form='ballot', width=8),
        dict(name='fix scan, 64-lane planes', form='scan', width=64),
        dict(name='fix scan, 32-lane planes', form='scan', width=32),
        dict(name='fix ballot on a 64-lane plane misreported as 32', form='ballot', width=64, misreport=True),
        dict(name='fix ballot, no reconvergence after the leader', form='ballot', width=32, noreconv=True),
        dict(name='fix scan, no reconvergence after the leader', form='scan', width=64, noreconv=True),
    ]
    print(f'trials {trials} per variant, seed {seed}')
    for v in V:
        w, u, f = run(v, trials, seed)
        extra = '' if v['name'].startswith('old') else f', undetected by the account {u}, false alarms {f}'
        print(f"{v['name']}: wrong {w}{extra}")

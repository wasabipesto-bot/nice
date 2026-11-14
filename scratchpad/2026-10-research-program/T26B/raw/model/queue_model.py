#!/usr/bin/env python3
"""Host model of niceonly_kernel's two survivor queues (main 41b4b405 and the fix), lane by lane.

A cube of U units is cut into planes; each plane is a list of (unit id UNIT_POS_X, lane id UNIT_POS_PLANE) pairs,
with W = PLANE_DIM the nominal width. Each unit produces a survivor (pf) or not per iteration until its ranges end.
The model replays both queues' arithmetic over shared slots and reports, per launch, survivors queued, checked
(multiset), lost and checked twice, and out-of-bounds slot writes. Plane-scoped: each plane runs its own loop
(plane-uniform). Cube-scoped: all planes in lockstep (cube-uniform, two barriers per iteration).
Usage: queue_model.py [SEED] [LAUNCHES]"""
import random, sys
from collections import Counter

def produce(rng, units, iters):
    # per unit: list of pf per iteration until done (have_range false afterwards)
    life = {u: rng.randint(0, iters) for u in units}
    rate = rng.choice([0.05, 0.3, 0.9])
    seq = {u: [1 if rng.random() < rate else 0 for _ in range(life[u])] for u in units}
    return seq

def plane_old(planes, W, U, seq):
    slots = [None] * (2 * 256); checked = Counter(); oob = 0; queued = Counter()
    for pp, plane in enumerate(planes):
        qbase = pp * 2 * W; qn = 0; it = 0
        while True:
            pf = {u: (seq[u][it] if it < len(seq[u]) else 0) for u, _ in plane}
            have = {u: it + 1 < len(seq[u]) for u, _ in plane}  # range left after this iteration
            # exclusive sum in lane order (scan over the active lanes, by lane id)
            order = sorted(plane, key=lambda x: x[1]); acc = 0; idx = {}
            for u, l in order: idx[u] = acc; acc += pf[u]
            tot = acc; done = all(not have[u] for u, _ in plane)
            for u, l in plane:
                if pf[u]:
                    d = qbase + qn + idx[u]
                    queued[(u, it)] += 1
                    if d >= len(slots): oob += 1
                    else: slots[d] = (u, it)
            qn += tot
            take = W if qn >= W else (qn if done else 0)
            for u, l in plane:
                lip = u % W
                if lip < take:
                    s = qbase + qn - take + lip
                    if s < len(slots) and slots[s] is not None: checked[slots[s]] += 1
            qn -= take; it += 1
            if done and qn == 0: break
            if it > 300: return queued, checked, oob, 'hang'
    return queued, checked, oob, ''

def plane_new(planes, W, U, seq):
    slots = [None] * (2 * 256); checked = Counter(); oob = 0; queued = Counter(); alloc = 0
    bases = []
    for plane in planes:  # reservation by the lowest running lane: 2 slots per running lane
        bases.append(alloc); alloc += 2 * len(plane)
    for pp, plane in enumerate(planes):
        qbase = bases[pp]; qn = 0; it = 0
        while True:
            pf = {u: (seq[u][it] if it < len(seq[u]) else 0) for u, _ in plane}
            have = {u: it + 1 < len(seq[u]) for u, _ in plane}
            order = sorted(plane, key=lambda x: x[1])
            rank = {u: i for i, (u, l) in enumerate(order)}; n = len(order)
            acc = 0; idx = {}
            for u, l in order: idx[u] = acc; acc += pf[u]
            tot = acc; done = all(not have[u] for u, _ in plane)
            for u, l in plane:
                if pf[u]:
                    d = qbase + qn + idx[u]; queued[(u, it)] += 1
                    if d >= len(slots) or d >= qbase + 2 * n: oob += 1
                    else: slots[d] = (u, it)
            qn += tot
            take = n if qn >= n else (qn if done else 0)
            for u, l in plane:
                if rank[u] < take:
                    s = qbase + qn - take + rank[u]
                    if slots[s] is not None: checked[slots[s]] += 1
            qn -= take; it += 1
            if done and qn == 0: break
    return queued, checked, oob, ''

def cube_old(planes, W, U, seq):
    slots = [None] * (2 * 256); checked = Counter(); oob = 0; queued = Counter()
    plane_tot = [0] * 256; plane_done = [0] * 256; num_planes = U // W; qn = 0; it = 0
    while True:
        info = {}
        for plane in planes:
            pf = {u: (seq[u][it] if it < len(seq[u]) else 0) for u, _ in plane}
            have = {u: it + 1 < len(seq[u]) for u, _ in plane}
            order = sorted(plane, key=lambda x: x[1]); acc = 0
            for u, l in order: info[u] = (pf[u], acc); acc += pf[u]
            pd = all(not have[u] for u, _ in plane)
            for u, l in plane:
                if l == 0:
                    plane_tot[u // W] = acc; plane_done[u // W] = 1 if pd else 0
        # barrier 1
        incoming = sum(plane_tot[p] for p in range(num_planes))
        all_done = all(plane_done[p] for p in range(num_planes))
        for plane in planes:
            for u, l in plane:
                pf, i = info[u]
                if pf:
                    base_off = qn + sum(plane_tot[p] for p in range(num_planes) if p < u // W)
                    d = base_off + i; queued[(u, it)] += 1
                    if d >= len(slots): oob += 1
                    else: slots[d] = (u, it)
        qn += incoming
        take = U if qn >= U else (qn if all_done else 0)
        for u in range(U):
            if u < take:
                s = qn - take + u
                if slots[s] is not None: checked[slots[s]] += 1
        qn -= take; it += 1
        if all_done and qn == 0: break
        if it > 300: return queued, checked, oob, 'hang'
    return queued, checked, oob, ''

def cube_new(planes, W, U, seq):
    slots = [None] * (2 * 256); checked = Counter(); oob = 0; queued = Counter(); qn = 0; it = 0
    while True:
        word = 0; offs = {}
        for plane in planes:  # each plane's lowest running lane adds (tot | busy << 10)
            pf = {u: (seq[u][it] if it < len(seq[u]) else 0) for u, _ in plane}
            have = {u: it + 1 < len(seq[u]) for u, _ in plane}
            order = sorted(plane, key=lambda x: x[1]); acc = 0
            for u, l in order: offs[u] = [pf[u], acc]; acc += pf[u]
            busy = sum(1 for u, _ in plane if have[u])
            got = word; word += acc | (busy << 10)
            for u, _ in plane: offs[u].append(got & 1023)
        for u, (pf, i, off) in offs.items():
            if pf:
                d = qn + off + i; queued[(u, it)] += 1
                if d >= 2 * U: oob += 1
                else: slots[d] = (u, it)
        qn += word & 1023; all_done = (word >> 10) == 0
        take = U if qn >= U else (qn if all_done else 0)
        for u in range(take):
            s = qn - take + u
            if slots[s] is not None: checked[slots[s]] += 1
        qn -= take; it += 1
        if all_done and qn == 0: break
    return queued, checked, oob, ''

def layouts(rng, W):
    """(name, U, planes) populations."""
    out = []
    U = 256; out.append(('full linear', U, [[(u, u % W) for u in range(p * W, p * W + W)] for p in range(U // W)]))
    U = rng.choice([100, 48, 36, 200]); n = U // W
    pl = [[(u, u % W) for u in range(p * W, min(U, p * W + W))] for p in range((U + W - 1) // W)]
    out.append(('partial last plane', U, pl))
    U = 256; units = list(range(U)); rng.shuffle(units)
    out.append(('non-linear full planes', U, [[(units[p * W + l], l) for l in range(W)] for p in range(U // W)]))
    U = (W - 1) * (256 // W); units = list(range(U))
    out.append(('no lane 0', U, [[(units[p * (W - 1) + l - 1], l) for l in range(1, W)] for p in range(256 // W)]))
    # random holes: planes of random sizes with random lane ids, units in random order
    U = rng.randint(40, 256); units = list(range(U)); rng.shuffle(units); pl = []; i = 0
    while i < U:
        k = min(U - i, rng.randint(1, W)); lanes = sorted(rng.sample(range(W), k))
        pl.append([(units[i + j], lanes[j]) for j in range(k)]); i += k
    out.append(('holes, random sizes and layout', U, pl))
    return out

def main():
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 7
    launches = int(sys.argv[2]) if len(sys.argv) > 2 else 400
    rng = random.Random(seed)
    stats = {}
    for _ in range(launches):
        W = rng.choice([8, 32, 64])
        for name, U, planes in layouts(rng, W):
            seq = produce(rng, [u for p in planes for u, _ in p], rng.randint(1, 12))
            for vname, fn in [('plane main', plane_old), ('plane fix', plane_new), ('cube main', cube_old), ('cube fix', cube_new)]:
                q, c, oob, h = fn(planes, W, U, seq)
                lost = sum(1 for k in q if c[k] == 0); twice = sum(v - 1 for v in c.values() if v > 1)
                bad = bool(lost > 0 or twice > 0 or oob > 0 or h)
                st = stats.setdefault((name, vname), [0, 0, 0, 0, 0, 0])
                st[0] += 1; st[1] += bad; st[2] += sum(q.values()); st[3] += lost; st[4] += twice; st[5] += oob
    print(f"seed {seed}, {launches} rounds (W drawn from 8/32/64 per round)")
    print(f"{'population':34} {'queue':11} {'launches':>8} {'wrong':>6} {'queued':>9} {'lost':>8} {'twice':>6} {'oob':>6}")
    for (name, vname), st in stats.items():
        print(f"{name:34} {vname:11} {st[0]:8} {st[1]:6} {st[2]:9} {st[3]:8} {st[4]:6} {st[5]:6}")

main()

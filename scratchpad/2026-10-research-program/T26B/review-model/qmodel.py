#!/usr/bin/env python3
"""Reviewer's independent model of niceonly_kernel's two survivor queues (branch 85fe64af).

Each cube: D units cut into planes of width W; each plane runs an arbitrary subset of its
lanes (lane ids), mapped to arbitrary UNIT_POS_X. Unit u has L[u] productive iterations,
each with a survivor bit; afterwards have_range is false. Ranks/positions are taken over the
running lanes in lane-id order (ballot popcount and non-uniform scans agree on that).
Plane-scoped queue: planes run independently, reservations in random order.
Cube-scoped queue: between barriers, the units' memory operations are interleaved randomly
(including unit 0's clear of the other word), so the alternating-word argument is tested,
not assumed. Mutations check that the model can fail: 'oneword' (no alternation),
'main' (main's plane-indexed algorithm), 'fixed_n' (reservation n vs per-iteration n).
Checks: every survivor checked exactly once, no slot out of the 2*256 array, no write into
another plane's region, no overwrite of an unchecked entry, termination.
"""
import random, sys

SLOTS = 512

def make_cube(rng, pop):
    W = rng.choice([8, 16, 32, 64])
    D = rng.randint(1, 256)
    units = list(range(D))
    if pop in ('nonlinear', 'holes', 'nolane0'):
        rng.shuffle(units)
    planes = []
    i = 0
    while i < D:
        if pop == 'holes':
            k = rng.randint(1, W)
        elif pop == 'nolane0':
            k = rng.randint(1, W - 1)
        else:
            k = min(W, D - i)
        mem = units[i:i + k]
        i += k
        if pop in ('holes', 'nolane0'):
            lanes = sorted(rng.sample(range(1 if pop == 'nolane0' else 0, W), len(mem)))
        else:
            lanes = list(range(len(mem)))
        planes.append(list(zip(lanes, mem)))  # (lane id, UNIT_POS_X)
    nu = D
    L = {}
    bits = {}
    for p in planes:
        for (_, u) in p:
            L[u] = rng.choice([0, 0, 1, 2, 5, 17, 40, rng.randint(0, 80)])
            dens = rng.choice([0.0, 0.05, 0.3, 0.7, 1.0])
            bits[u] = [1 if rng.random() < dens else 0 for _ in range(L[u])]
    return W, nu, planes, L, bits

def rank_info(plane, val):
    """per lane: (exclusive count of val among lower lane ids, total)."""
    order = sorted(plane)  # by lane id
    ex, run = {}, 0
    for (lane, u) in order:
        ex[u] = run
        run += val(u)
    return ex, run

def plane_scoped(rng, W, nu, planes, L, bits, mut):
    q = [None] * SLOTS
    owner = [None] * SLOTS
    counter = 0
    order = list(range(len(planes)))
    rng.shuffle(order)
    qbase = {}
    for pi in order:
        n0 = len(planes[pi])
        qbase[pi] = counter
        for s in range(counter, counter + 2 * n0):
            if s < SLOTS:
                owner[s] = pi
        counter += 2 * n0
    checked = []
    errs = []
    for pi in range(len(planes)):
        p = planes[pi]
        qb, qn, it = qbase[pi], 0, 0
        while True:
            pf = {u: (bits[u][it] if it < L[u] else 0) for (_, u) in p}
            have = {u: it < L[u] for (_, u) in p}
            # in the kernel the iteration that ends a range produces nothing: model L
            # productive iterations then one with have_range false.
            idx, tot = rank_info(p, lambda u: pf[u])
            rank, n = rank_info(p, lambda u: 1)
            if mut == 'fixed_n':
                n = W  # main's PLANE_DIM take
            done = all(not have[u] for (_, u) in p)
            for (_, u) in p:
                if pf[u]:
                    dst = qb + qn + idx[u]
                    if dst >= SLOTS:
                        errs.append('oob'); continue
                    if owner[dst] != pi:
                        errs.append('foreign region')
                    if q[dst] is not None:
                        errs.append('overwrite unchecked')
                    q[dst] = (u, it)
            qn += tot
            take = n if qn >= n else (qn if done else 0)
            for (_, u) in p:
                if rank[u] < take:
                    s = qb + qn - take + rank[u]
                    if s < SLOTS and q[s] is not None:
                        checked.append(q[s]); q[s] = None
            qn -= take
            it += 1
            if done and qn == 0:
                break
            if it > 10000:
                errs.append('no termination'); break
    return checked, errs

def cube_scoped(rng, W, nu, planes, L, bits, mut):
    q = [None] * SLOTS
    word = [0, 0]
    unit_plane = {}
    for pi, p in enumerate(planes):
        for (_, u) in p:
            unit_plane[u] = pi
    checked, errs = [], []
    qn = {u: 0 for u in range(nu)}
    it = 0
    while True:
        w = 0 if mut == 'oneword' else (it & 1)
        pf = {u: (bits[u][it] if it < L[u] else 0) for u in range(nu)}
        have = {u: it < L[u] for u in range(nu)}
        info = {}
        for pi, p in enumerate(planes):
            idx, tot = rank_info(p, lambda u: pf[u])
            rank, n = rank_info(p, lambda u: 1)
            lanes_h = sum(1 for (_, u) in p if have[u])
            info[pi] = (idx, tot | (lanes_h << 10), rank)
        # --- barrier 1 --- phase B: leaders' fetch_adds in random order, then writes
        leaders = list(range(len(planes)))
        rng.shuffle(leaders)
        off = {}
        for pi in leaders:
            off[pi] = word[w]; word[w] += info[pi][1]
        ops = []
        for u in range(nu):
            if pf[u]:
                pi = unit_plane[u]
                dst = qn[u] + (off[pi] & 1023) + info[pi][0][u]
                ops.append(('write', u, dst))
        rng.shuffle(ops)
        for (_, u, dst) in ops:
            if dst >= SLOTS:
                errs.append('oob'); continue
            if q[dst] is not None:
                errs.append('overwrite unchecked')
            q[dst] = (u, it)
        # --- barrier 2 --- phase A: loads of word w, unit 0 clears 1-w, drain reads;
        # these interleave freely until barrier 1 of the next iteration.
        per_unit = []
        for u in range(nu):
            seq = [('load', u)]
            if u == 0:
                seq.append(('clear', u))
            seq.append(('drain', u))
            per_unit.append(seq)
        seen = {}
        drains = []
        while any(per_unit):
            cand = [s for s in per_unit if s]
            s = rng.choice(cand)
            op, u = s.pop(0)
            if op == 'load':
                seen[u] = word[w]
            elif op == 'clear':
                word[1 - w if mut != 'oneword' else w] = 0
            else:
                tw = seen[u]
                inc = tw & 1023
                all_done = (tw >> 10) == 0
                qn_u = qn[u] + inc
                take = nu if qn_u >= nu else (qn_u if all_done else 0)
                if u < take:
                    drains.append(qn_u - take + u)
                qn[u] = qn_u - take
                seen[u] = (qn[u], all_done)
        for s in drains:
            if q[s] is not None:
                checked.append(q[s]); q[s] = None
            else:
                errs.append('empty slot read')
        vals = set(seen.values())
        if len(vals) != 1:
            errs.append('non-uniform qn/all_done'); break
        (qn0, ad) = vals.pop()
        it += 1
        if ad and qn0 == 0:
            break
        if it > 10000:
            errs.append('no termination'); break
    return checked, errs

def main():
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    rounds = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    rng = random.Random(seed)
    for variant, fn in (('plane', plane_scoped), ('cube', cube_scoped)):
        for mut in ([None, 'fixed_n'] if variant == 'plane' else [None, 'oneword']):
            for pop in ('full', 'partial', 'nonlinear', 'nolane0', 'holes'):
                wrong = lost = dup = 0; kinds = {}
                for _ in range(rounds):
                    W, nu, planes, L, bits = make_cube(rng, pop)
                    want = sorted((u, i) for u in L for i in range(L[u]) if bits[u][i])
                    got, errs = fn(rng, W, nu, planes, L, bits, mut)
                    g = sorted(got)
                    bad = g != want or errs
                    if bad:
                        wrong += 1
                        lost += len(set(want) - set(g)); dup += len(g) - len(set(g))
                        for e in set(errs):
                            kinds[e] = kinds.get(e, 0) + 1
                print(f"{variant:5} mut={str(mut):8} pop={pop:9} launches={rounds} wrong={wrong} lost={lost} dup={dup} {kinds}")

main()

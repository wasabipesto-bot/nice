"""Independent model of take_entries (8d11e0be) and the host's ensure_checked.

Each plane's lanes have a lane id (UNIT_POS_PLANE). At every take point the lanes
of a plane still in the loop are cut into random disjoint groups; each group is
one dynamic instance of take_entries (the lanes that run it together). Groups of
different planes interleave on the shared counter in random order. Variants:
  ballot / scan            the two forms as written
  ballot_wide              ballot form with lanes >= 32 (misreported width); shift
                           masked mod 32 as WGSL does, ballot word 0 = lanes 0..31
  noreconv_scan/_ballot    the leader runs the sum / shuffle apart from the others
                           (no reconvergence after `if rank == 0`)
"""
import random, sys

UNDEF = object()

def popc(x): return bin(x & 0xFFFFFFFF).count("1")

def take(group, ctr, form, rng):
    """group: list of lane ids running this take together. Returns {lane: (cur, rank)}, new ctr."""
    out = {}
    if form in ("ballot", "ballot_wide", "noreconv_ballot"):
        word0 = 0
        for l in group:
            if l < 32: word0 |= 1 << l
        got = {}
        for l in group:
            sh = l % 32  # WGSL masks the shift amount; CUDA would be UB
            rank = popc(word0 & (((1 << sh) - 1) & 0xFFFFFFFF))
            got[l] = (rank, 0)
        leaders = [l for l in group if got[l][0] == 0]
        g = {}
        for l in leaders:
            g[l] = ctr; ctr += popc(word0)
        lanes = word0
        if lanes == 0:
            lead = None  # (lanes ^ (lanes-1)) wraps: count_ones = 32 -> lead 31
            lead = 31
        else:
            lead = (lanes ^ ((lanes - 1) & 0xFFFFFFFF)).bit_count() - 1
        for l in group:
            if form == "noreconv_ballot" and l not in leaders:
                src = UNDEF  # shuffle from a lane that is not running this instance
            else:
                src = g.get(lead, UNDEF) if lead in group else UNDEF
            if src is UNDEF:
                src = rng.randrange(0, ctr + 64)  # indeterminate value
            out[l] = (src, got[l][0])
        return out, ctr
    elif form in ("scan", "noreconv_scan"):
        order = sorted(group)
        n = len(order)
        got = 0
        for r, l in enumerate(order):
            if r == 0:
                got = ctr; ctr += n
        for r, l in enumerate(order):
            if form == "noreconv_scan":
                cur = got if r == 0 else 0  # the others' sum lacks the leader
            else:
                cur = got
            out[l] = (cur, r)
        return out, ctr
    raise ValueError(form)

def run(count, planes, form, rng, max_steps=10**6):
    """planes: list of lists of lane ids (each plane's active population)."""
    ctr = 0
    checks = [0] * count
    done = 0; isum = 0
    state = {}
    # initial take, then loop
    pending = []  # (plane idx, lanes waiting at a take point, 'init'|'loop')
    for p, lanes in enumerate(planes):
        pending.append((p, list(lanes)))
    steps = 0
    while pending:
        steps += 1
        if steps > max_steps:
            return None  # hang
        k = rng.randrange(len(pending))
        p, lanes = pending.pop(k)
        # lanes of the same plane from other pending instances may join this one
        if rng.random() < 0.5:
            keep = []
            for (q, ls) in pending:
                if q == p and rng.random() < 0.7: lanes = lanes + ls
                else: keep.append((q, ls))
            pending = keep
        # cut this plane's waiting lanes into random groups; run one group now,
        # leave the rest pending (they run their own instance later)
        rng.shuffle(lanes)
        cut = rng.randint(1, len(lanes)) if rng.random() < 0.5 else len(lanes)
        grp, rest = sorted(lanes[:cut]), lanes[cut:]
        if rest: pending.append((p, rest))
        res, ctr = take(grp, ctr, form, rng)
        cont = []
        for l in grp:
            prev = state.get((p, l))
            if prev is not None:
                cur, rank = prev
                i = cur + rank
                if i < count:
                    checks[i] += 1; done += 1; isum = (isum + i) & 0xFFFFFFFF
            state[(p, l)] = res[l]
            if res[l][0] < count:
                cont.append(l)
        if cont: pending.append((p, cont))
    return checks, done, isum

def host_ok(count, done, isum):
    return done == count and isum == (count * (count - 1) // 2) % (1 << 32)

def rand_pop(rng, width):
    mode = rng.random()
    if mode < 0.2: return list(range(width))
    if mode < 0.4:  # partly filled from lane 0
        return list(range(rng.randint(1, width)))
    if mode < 0.6:  # no lane 0, contiguous tail
        a = rng.randint(1, width - 1); return list(range(a, width))
    k = rng.randint(1, width)
    return sorted(rng.sample(range(width), k))

def main():
    rng = random.Random(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
    trials = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
    for form, widths in [("ballot", [4, 8, 16, 32]), ("scan", [4, 8, 16, 32, 64, 128]),
                         ("ballot_wide", [64]), ("noreconv_scan", [64]), ("noreconv_ballot", [32])]:
        bad = undetected = hangs = 0
        for t in range(trials):
            w = rng.choice(widths)
            nplanes = rng.randint(1, 6)
            planes = [rand_pop(rng, w) for _ in range(nplanes)]
            count = rng.choice([0, 1, 2, rng.randint(1, 50), rng.randint(50, 3000)])
            r = run(count, planes, form, rng, max_steps=20000)
            if r is None:
                hangs += 1; continue
            checks, done, isum = r
            wrong = any(c != 1 for c in checks)
            ok = host_ok(count, done, isum)
            bad += wrong
            if wrong and ok: undetected += 1
            if not wrong and not ok:
                print("FALSE ALARM", form, count, planes); return 1
        print(f"{form:16s} trials {trials}: wrong hand-outs {bad}, passed host check while wrong {undetected}, hangs {hangs}")
    return 0

if __name__ == "__main__":
    sys.exit(main())

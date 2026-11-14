#!/usr/bin/env python3
"""Independent reviewer's model of `top_slot` (f9a25017) and of main's (41b4b405).

Written from the kernel source only (common/src/cubecl_join.rs, top_slot and the
FD kernel's append + account), not from the author's model.

A *call* is one dynamic instance of top_slot: the set P of lanes that run it
together, each with (kept, g). Plane ops act over P. Atomics on grp_cnt are
events that may interleave arbitrarily with other calls' atomics.

Checks per launch:
  * every kept top lands in a distinct record of its own group's segment,
    inside [goff[g], goff[g] + cnt[g]), and every counted record is written
    exactly once (complete + non-overlapping);
  * the account (kept - reserved, sum(written) - sum(reserved)) mod 2^32
    is zero exactly when the above holds (false alarm / undetected counts).

Modes:
  exhaustive   every population of an 8-lane plane (active subset x kept
               subset x any 2-group assignment, plus 3-group sorted cuts),
               both forms, fix and main; main also on full planes for the
               per-group top sets.
  random       random multi-plane launches at widths 8/16/32/64, both forms,
               shared counters, interleaved atomics, populations full /
               prefix / no-lane-0 / holes / split calls.
  faults       mechanisms that break the plane ops; how many wrong launches
               the account lets through.
"""
import itertools
import random
import sys

M32 = (1 << 32) - 1
LAST_SQ_ZERO = True


def popc(x):
    return bin(x).count("1")


class Garbage:
    """What a plane op returns when it reads an inactive lane."""

    def __init__(self, rng, kind):
        self.rng, self.kind = rng, kind

    def __call__(self, own):
        if self.kind == "zero":
            return 0
        if self.kind == "own":
            return own
        return self.rng.randrange(0, 1 << 12)


# ---------------------------------------------------------------------------
# One call of the FIX's top_slot. Returns per-lane closures so atomics can be
# interleaved: phase 1 = leader's plane atomic; phase 2 = per-lane atomics.
# For simplicity the model executes a call's plane ops atomically w.r.t. the
# call, but the grp_cnt atomics of *all* calls are executed in a shuffled
# global order (phase barriers inside one call are respected).
# ---------------------------------------------------------------------------


def fix_call(P, lanes, cnt, goff, form, acct, writes, fault=None, garb=None, width=32):
    """P: sorted list of active lane ids; lanes[l] = (kept, g)."""
    kept = {l: lanes[l][0] for l in P}
    g = {l: lanes[l][1] for l in P}
    # --- kept set, n, rank
    if form == "ballot":
        if fault == "misreport64":
            # 64-lane plane, ballot word 0 only, shift masked mod 32 (WGSL)
            kb = 0
            for l in P:
                if kept[l] and l < 32:
                    kb |= 1 << l
            n = {l: popc(kb) for l in P}
            rank = {l: popc(kb & ((1 << (l % 32)) - 1)) for l in P}
        elif fault == "rotlane":
            # UNIT_POS_PLANE is not the ballot bit: CubeCL's CUDA/HIP lane id
            # AbsolutePos % 32 on a grid whose cubes are not multiples of 32
            # (lane id = (hardware lane + rot) % 32); ballot bits and the
            # shuffle use the hardware lane
            rot = garb.rot
            kb = 0
            for l in P:
                if kept[l]:
                    kb |= 1 << l
            n = {l: popc(kb) for l in P}
            rank = {l: popc(kb & ((1 << ((l + rot) % width)) - 1)) for l in P}
        elif fault == "ballot_ghost":
            # inactive lanes' bits set (stale kept): not allowed by any backend,
            # modelled to see whether the account catches it
            kb = 0
            for l in range(width):
                if (l in kept and kept[l]) or (l not in kept and garb.rng.random() < 0.3):
                    kb |= 1 << l
            n = {l: popc(kb) for l in P}
            rank = {l: popc(kb & ((1 << l) - 1)) for l in P}
        else:
            kb = 0
            for l in P:
                if kept[l]:
                    kb |= 1 << l
            n = {l: popc(kb) for l in P}
            rank = {l: popc(kb & ((1 << l) - 1)) for l in P}
    else:
        if fault == "scan_garbage":
            # C++ butterfly on a partial plane: inactive lanes contribute junk
            junk = {l: garb(0) & 1 for l in range(width) if l not in kept}
            vals = {l: (1 if kept[l] else 0) for l in P}
            vals.update(junk)
            tot = sum(vals.values())
            n = {l: tot for l in P}
            rank = {l: sum(v for k, v in vals.items() if k < l) for l in P}
        else:
            tot = sum(1 for l in P if kept[l])
            n = {l: tot for l in P}
            rank = {l: sum(1 for k in P if k < l and kept[k]) for l in P}
    lead = {l: kept[l] and rank[l] == 0 for l in P}
    # --- g0
    if form == "ballot":
        src = {}
        for l in P:
            kbl = kb if fault != "misreport64" else kb
            src[l] = l if kbl == 0 else ((kbl ^ (kbl - 1)) & M32).bit_count() - 1
        def shuf(val, l):
            s = src[l]
            if fault == "bad_shuffle":
                return garb(val[l])
            if s in val:
                return val[s]
            return garb(val[l])
        g0 = {l: shuf(g, l) for l in P}
    else:
        g0s = sum(g[l] for l in P if lead[l])
        g0 = {l: g0s for l in P}
    one_v = all((not kept[l]) or g[l] == g0[l] for l in P)
    one = {l: one_v for l in P}
    # --- leader's atomic (phase 1)
    a0 = {l: 0 for l in P}
    leaders = [l for l in P if lead[l] and one[l]]
    events1 = []
    for l in leaders:
        def ev(l=l):
            take = n[l]
            a = cnt[g0[l]]
            cnt[g0[l]] = a + take
            a0[l] = a
            r0 = goff[g[l]] + a
            acct[0] = (acct[0] - take) & M32
            acct[1] = (acct[1] - (take * r0 + take * (take - 1) // 2)) & M32
            # suggested third word: sum of squares, closed form as the kernel would compute it
            acct[2] = (acct[2] - (take * r0 * r0 + r0 * take * (take - 1)
                                  + (take - 1) * take * (2 * take - 1) // 6)) & M32
        events1.append(ev)
    return dict(P=P, kept=kept, g=g, n=n, rank=rank, lead=lead, g0=g0, one=one, a0=a0,
                src=(src if form == "ballot" else None), form=form, events1=events1,
                fault=fault, garb=garb)


def fix_finish(c, cnt, goff, acct, writes, noreconv=False):
    P, kept, g, rank, one, a0 = c["P"], c["kept"], c["g"], c["rank"], c["one"], c["a0"]
    garb = c["garb"]
    form = c["form"]
    # broadcast of a0
    if form == "ballot":
        a = {}
        for l in P:
            s = c["src"][l]
            if noreconv and s != l and c["lead"].get(s, False) and c["one"][s]:
                a[l] = garb(a0[l])  # leader not in this instance: inactive read
            elif c["fault"] == "bad_shuffle":
                a[l] = garb(a0[l])
            elif s in a0:
                a[l] = a0[s]
            else:
                a[l] = garb(a0[l])
    else:
        if noreconv:
            # leader alone in its own instance; the others sum to 0
            a = {l: (a0[l] if c["lead"][l] else 0) for l in P}
        else:
            tot = sum(a0[l] for l in P)
            a = {l: tot for l in P}
    events2 = []
    for l in P:
        at = (a[l] + rank[l]) & M32
        if kept[l] and not one[l]:
            def ev(l=l):
                at2 = cnt[g[l]]
                cnt[g[l]] += 1
                acct[0] = (acct[0] - 1) & M32
                acct[1] = (acct[1] - (goff[g[l]] + at2)) & M32
                rec = goff[g[l]] + at2
                acct[2] = (acct[2] - rec * rec) & M32
                acct[0] = (acct[0] + 1) & M32
                acct[1] = (acct[1] + rec) & M32
                acct[2] = (acct[2] + rec * rec) & M32
                writes.append((rec, l, g[l]))
            events2.append(ev)
        elif kept[l]:
            rec = (goff[g[l]] + at) & M32
            acct[0] = (acct[0] + 1) & M32
            acct[1] = (acct[1] + rec) & M32
            acct[2] = (acct[2] + rec * rec) & M32
            writes.append((rec, l, g[l]))
    return events2


# ---------------------------------------------------------------------------
# main's top_slot (41b4b405)
# ---------------------------------------------------------------------------


def main_call(P, lanes, cnt, goff, form, writes, garb):
    kept = {l: lanes[l][0] for l in P}
    g = {l: lanes[l][1] for l in P}
    g0v = g[0] if 0 in g else garb(0)
    one = all((not kept[l]) or g[l] == g0v for l in P)
    kc = {l: 1 if (kept[l] and one) else 0 for l in P}
    if form == "ballot":
        b0 = sum(1 << l for l in P if kc[l])
        n = popc(b0)
        pre = {l: popc(b0 & ((1 << l) - 1)) for l in P}
    else:
        n = sum(kc.values())
        pre = {l: sum(kc[k] for k in P if k < l) for l in P}
    holder = {}
    ev1 = []
    if 0 in P and n > 0:
        def ev():
            holder["a0"] = cnt[g0v]
            cnt[g0v] += n
        ev1.append(ev)

    def finish():
        a = holder.get("a0", 0) if 0 in P else garb(0)
        ev2 = []
        for l in P:
            if kept[l] and not one:
                def e(l=l):
                    at = cnt[g[l]]
                    cnt[g[l]] += 1
                    writes.append((goff[g[l]] + at, l, g[l]))
                ev2.append(e)
            elif kept[l]:
                writes.append((goff[g[l]] + a + pre[l], l, g[l]))
        return ev2
    return ev1, finish


# ---------------------------------------------------------------------------
# Verification of one launch
# ---------------------------------------------------------------------------


def verify(tops, writes, cnt, goff, sizes):
    """tops: list of (plane, lane, g) kept. writes: (rec, (plane,lane), g)."""
    ok = True
    want = {}
    for (pl, l, gg) in tops:
        want.setdefault(gg, set()).add((pl, l))
    seen = {}
    for rec, who, gg in writes:
        if rec in seen:
            ok = False
        seen[rec] = (who, gg)
    for gg in sizes:
        lo = goff[gg]
        c = cnt[gg]
        if c > sizes[gg]:
            ok = False
        got = set()
        for r in range(lo, lo + c):
            if r not in seen:
                ok = False
                continue
            who, wg = seen[r]
            if wg != gg:
                ok = False
            got.add(who)
        if got != want.get(gg, set()):
            ok = False
    # writes outside any counted range
    for rec in seen:
        inside = any(goff[gg] <= rec < goff[gg] + cnt[gg] for gg in sizes)
        if not inside:
            ok = False
    return ok


def per_group_sets(writes, cnt, goff, sizes):
    seen = {rec: who for rec, who, _ in writes}
    return {gg: frozenset(seen.get(r) for r in range(goff[gg], goff[gg] + cnt[gg])) for gg in sizes}


def make_layout(rng, width, nplanes, ngroups_mode):
    """Lanes in planes, groups sorted by global position (as the host sorts the
    layer) or random; group sizes are the number of prefixes of each group."""
    total = width * nplanes
    if ngroups_mode == "one":
        gs = [0] * total
    elif ngroups_mode == "two":
        cut = rng.randrange(0, total + 1)
        gs = [0] * cut + [1] * (total - cut)
    elif ngroups_mode == "sorted":
        k = rng.randrange(1, 7)
        cuts = sorted(rng.randrange(0, total + 1) for _ in range(k - 1))
        gs = []
        prev = 0
        for i, c in enumerate(cuts + [total]):
            gs += [i] * (c - prev)
            prev = c
    else:
        gs = [rng.randrange(0, 5) for _ in range(total)]
    nb = max(gs) + 1
    sizes = {gg: gs.count(gg) for gg in range(nb)}
    # goff: groups laid out consecutively, with a random large slot offset to
    # exercise the mod-2^32 sums
    base = rng.choice([0, 7, M32 - 3 * total, 3_000_000_000])
    goff = {}
    o = base
    for gg in range(nb):
        goff[gg] = o & M32
        o += sizes[gg]
    return gs, nb, sizes, goff


def populate(rng, width, kind):
    lanes = list(range(width))
    if kind == "full":
        return lanes
    if kind == "prefix":
        return lanes[: rng.randrange(1, width + 1)]
    if kind == "nolane0":
        return [l for l in lanes[1:] if rng.random() < 0.85] or [width - 1]
    if kind == "holes":
        s = [l for l in lanes if rng.random() < 0.6]
        return s or [rng.randrange(width)]
    raise ValueError(kind)


def split_calls(rng, P, split):
    if not split or len(P) < 2:
        return [P]
    # a plane's lanes split across several dynamic instances (divergence)
    k = rng.randrange(1, min(4, len(P)) + 1)
    parts = [[] for _ in range(k)]
    for l in P:
        parts[rng.randrange(k)].append(l)
    return [p for p in parts if p]


def verify_tagged(planes, nb, sizes, goff, form, rng, garb, width, tops, impl="fix", fault=None,
                  noreconv=False):
    """Run with writes tagged by (plane, lane)."""
    cnt = {gg: 0 for gg in range(nb)}
    acct = [0, 0, 0]
    calls = []
    allw = []
    for pi, (insts, lanes) in enumerate(planes):
        for P in insts:
            w = []
            if impl == "fix":
                c = fix_call(P, lanes, cnt, goff, form, acct, w, fault, garb, width)
                calls.append((pi, c, w))
            else:
                ev1, fin = main_call(P, lanes, cnt, goff, form, w, garb)
                calls.append((pi, (ev1, fin), w))
    ev1 = []
    for pi, c, w in calls:
        ev1 += c["events1"] if impl == "fix" else c[0]
    rng.shuffle(ev1)
    for e in ev1:
        e()
    ev2 = []
    for pi, c, w in calls:
        if impl == "fix":
            ev2 += fix_finish(c, cnt, goff, acct, w, noreconv)
        else:
            ev2 += c[1]()
    rng.shuffle(ev2)
    for e in ev2:
        e()
    for pi, c, w in calls:
        for rec, l, gg in w:
            allw.append((rec, (pi, l), gg))
    ok = verify(tops, allw, cnt, goff, sizes)
    global LAST_SQ_ZERO
    LAST_SQ_ZERO = acct[2] == 0
    return ok, acct[:2] == [0, 0], cnt, allw


def verify_tagged_ok(*a, **k):
    ok, acc0, cnt, allw = verify_tagged(*a, **k)
    return ok, acc0


def random_suite(seed, trials, out, fault=None, noreconv=False, impl="fix", forms=None,
                 widths=None, pkinds=None):
    rng = random.Random(seed)
    stats = {}
    for t in range(trials):
        width = rng.choice(widths or [8, 16, 32, 64])
        if forms:
            form = rng.choice(forms)
        else:
            form = rng.choice(["ballot", "scan"]) if width <= 32 else "scan"
        if fault == "misreport64":
            width, form = 64, "ballot"
        nplanes = rng.randrange(1, 7)
        gmode = rng.choice(["one", "two", "sorted", "random"])
        gs, nb, sizes, goff = make_layout(rng, width, nplanes, gmode)
        pkind = rng.choice(pkinds or ["full", "prefix", "nolane0", "holes"])
        split = rng.random() < 0.3 and impl == "fix"
        pk = rng.choice([0.05, 0.3, 0.7, 1.0])
        planes, tops = [], []
        for p in range(nplanes):
            lanes = {l: (rng.random() < pk, gs[p * width + l]) for l in range(width)}
            P = populate(rng, width, pkind)
            insts = split_calls(rng, P, split)
            for l in range(width):
                if l not in P:
                    lanes[l] = (False, lanes[l][1])
            tops += [(p, l, lanes[l][1]) for l in P if lanes[l][0]]
            planes.append((insts, lanes))
        garb = Garbage(rng, rng.choice(["zero", "own", "rand"]))
        garb.rot = rng.randrange(1, width)
        ok, acc0 = verify_tagged_ok(planes, nb, sizes, goff, form, rng, garb, width, tops,
                                    impl=impl, fault=fault, noreconv=noreconv)
        s = stats.setdefault((width, form, pkind), [0, 0, 0, 0, 0, 0])
        s[0] += 1
        s[1] += (not ok)
        s[2] += (not ok and acc0)       # wrong, passed the host check
        s[3] += (ok and not acc0)       # right, false alarm
        s[4] = (s[4] or 0) + (not ok and acc0 and LAST_SQ_ZERO)   # also passes with squares
        s[5] = (s[5] or 0) + (ok and not (acc0 and LAST_SQ_ZERO))  # false alarm with squares
    tot = [0, 0, 0, 0, 0, 0]
    for k in sorted(stats):
        for i in range(6):
            tot[i] += stats[k][i]
    out.write(f"  seed {seed} impl={impl} fault={fault} noreconv={noreconv}: launches {tot[0]}, "
              f"wrong {tot[1]}, wrong-but-account-zero {tot[2]}, false alarms {tot[3]}; "
              f"with a squares word: undetected {tot[4]}, false alarms {tot[5]}\n")
    return tot


# ---------------------------------------------------------------------------
# Exhaustive: single call on an 8-lane plane, fix in both forms
# ---------------------------------------------------------------------------


def exhaustive(out):
    W = 8
    rng = random.Random(0)
    garb = Garbage(rng, "rand")
    calls = wrong = acct_bad = 0
    group_maps = list(itertools.product([0, 1], repeat=W))
    sorted3 = []
    for c1 in range(W + 1):
        for c2 in range(c1, W + 1):
            sorted3.append(tuple([0] * c1 + [1] * (c2 - c1) + [2] * (W - c2)))
    gmaps = group_maps + sorted3
    for amask in range(1, 1 << W):
        P = [l for l in range(W) if amask >> l & 1]
        for ksub in range(1 << len(P)):
            keptset = {P[i] for i in range(len(P)) if ksub >> i & 1}
            for gm in gmaps:
                nb = max(gm) + 1
                sizes = {gg: gm.count(gg) for gg in range(nb)}
                goff, o = {}, 1000
                for gg in range(nb):
                    goff[gg] = o
                    o += sizes[gg]
                lanes = {l: (l in keptset, gm[l]) for l in range(W)}
                tops = [(0, l, gm[l]) for l in sorted(keptset)]
                for form in ("ballot", "scan"):
                    ok, acc0 = verify_tagged_ok([([P], lanes)], nb, sizes, goff, form, rng, garb,
                                                W, tops)
                    calls += 1
                    wrong += (not ok)
                    acct_bad += (not acc0)
    out.write(f"  exhaustive 8-lane single call, fix, both forms: {calls} calls, wrong {wrong}, "
              f"nonzero account {acct_bad}\n")


def exhaustive_main_full(out):
    """Main vs fix on FULL 8-lane planes: per-group sets of tops equal, both right."""
    W = 8
    rng = random.Random(1)
    garb = Garbage(rng, "rand")
    n = diff_sets = main_wrong = fix_wrong = diff_records = 0
    gmaps = list(itertools.product([0, 1, 2], repeat=W))
    for ksub in range(1 << W):
        for gm in gmaps:
            nb = max(gm) + 1
            sizes = {gg: gm.count(gg) for gg in range(nb)}
            goff, o = {}, 0
            for gg in range(nb):
                goff[gg] = o
                o += sizes[gg]
            lanes = {l: (bool(ksub >> l & 1), gm[l]) for l in range(W)}
            tops = [(0, l, gm[l]) for l in range(W) if lanes[l][0]]
            P = list(range(W))
            for form in ("ballot", "scan"):
                okf, _, cntf, wf = verify_tagged([([P], lanes)], nb, sizes, goff, form, rng, garb,
                                                 W, tops, impl="fix")
                okm, _, cntm, wm = verify_tagged([([P], lanes)], nb, sizes, goff, form, rng, garb,
                                                 W, tops, impl="main")
                n += 1
                fix_wrong += not okf
                main_wrong += not okm
                sf = per_group_sets(wf, cntf, goff, sizes)
                sm = per_group_sets(wm, cntm, goff, sizes)
                diff_sets += sf != sm
                diff_records += sorted(wf) != sorted(wm)
    out.write(f"  full 8-lane planes, 3 groups any order, every kept subset, both forms: {n} calls; "
              f"fix wrong {fix_wrong}, main wrong {main_wrong}, per-group top sets differ {diff_sets}, "
              f"record assignment differs {diff_records}\n")


def main():
    out = sys.stdout
    seeds = [int(s) for s in sys.argv[1:]] or [11]
    out.write("== exhaustive ==\n")
    exhaustive(out)
    exhaustive_main_full(out)
    for seed in seeds:
        out.write(f"== random, seed {seed} ==\n")
        random_suite(seed, 20000, out)
        out.write("  -- main on the same populations (sanity: it should fail without lane 0)\n")
        random_suite(seed, 20000, out, impl="main", pkinds=["nolane0"])
        random_suite(seed, 20000, out, impl="main", pkinds=["full", "prefix"])
        out.write("  -- faults (fix): does the account catch them?\n")
        random_suite(seed, 20000, out, noreconv=True)
        random_suite(seed, 20000, out, fault="misreport64")
        random_suite(seed, 20000, out, fault="scan_garbage", forms=["scan"],
                     pkinds=["prefix", "nolane0", "holes"])
        random_suite(seed, 20000, out, fault="bad_shuffle", forms=["ballot"], widths=[8, 16, 32])
        random_suite(seed, 20000, out, fault="rotlane", forms=["ballot"], widths=[32],
                     pkinds=["full", "prefix"])
        random_suite(seed, 20000, out, fault="ballot_ghost", forms=["ballot"], widths=[8, 16, 32],
                     pkinds=["prefix", "nolane0", "holes"])


if __name__ == "__main__":
    main()

"""Find undetected wrong launches (account zero) under misreport64 / bad_shuffle and show their
per-plane account contributions: do errors of opposite sign cancel across planes, or does one
plane's error vanish by itself?"""
import random, sys
import top_slot_review as m

def run(fault, seed, trials, widths, forms, pkinds):
    rng = random.Random(seed)
    single = multi = 0
    shown = 0
    for t in range(trials):
        width = rng.choice(widths); form = rng.choice(forms)
        nplanes = rng.randrange(1, 7)
        gs, nb, sizes, goff = m.make_layout(rng, width, nplanes, rng.choice(["one", "two", "sorted", "random"]))
        pkind = rng.choice(pkinds); pk = rng.choice([0.05, 0.3, 0.7, 1.0])
        planes, tops = [], []
        for p in range(nplanes):
            lanes = {l: (rng.random() < pk, gs[p * width + l]) for l in range(width)}
            P = m.populate(rng, width, pkind)
            for l in range(width):
                if l not in P: lanes[l] = (False, lanes[l][1])
            tops += [(p, l, lanes[l][1]) for l in P if lanes[l][0]]
            planes.append(([P], lanes))
        garb = m.Garbage(rng, rng.choice(["zero", "own", "rand"])); garb.rot = rng.randrange(1, width)
        st = rng.getstate()
        ok, acc0, cnt, allw = m.verify_tagged(planes, nb, sizes, goff, form, rng, garb, width, tops, fault=fault)
        if ok or not acc0: continue
        # per plane: written records vs the plane's own reservations is not observable from outside;
        # instead re-run each plane alone with the same counters state is not reproducible, so report
        # duplicates/unwritten records and their sums.
        recs = [r for r, _, _ in allw]
        dup = sorted({r for r in recs if recs.count(r) > 1})
        counted = sorted(r for gg in sizes for r in range(goff[gg], goff[gg] + cnt[gg]))
        unw = sorted(set(counted) - set(recs))
        outside = sorted(set(recs) - set(counted))
        planes_hit = len({who[0] for r, who, _ in allw if r in dup or r in outside})
        if planes_hit <= 1: single += 1
        else: multi += 1
        if shown < 4:
            shown += 1
            base = min(goff.values())
            print(f"  {fault} trial {t}: planes {nplanes}, dup {[d-base for d in dup]}, unwritten {[u-base for u in unw]}, "
                  f"outside {[o-base for o in outside]}, planes involved {planes_hit}")
    print(f"{fault}: undetected wrong launches with errors in one plane {single}, in several planes {multi}")

run("misreport64", 11, 20000, [64], ["ballot"], ["full", "prefix", "nolane0", "holes"])
run("bad_shuffle", 11, 20000, [8, 16, 32], ["ballot"], ["full", "prefix", "nolane0", "holes"])

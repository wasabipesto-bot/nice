#!/usr/bin/env python3
"""Host models of the plane-size-dependent appends (T2.4 soundness audit).

1. top_slot (main a7a59c11, cubecl_join.rs 1749-1787): a plane's kept tops are
   appended into their groups' segments. Invariant: every kept lane gets a
   distinct slot in its own group's segment, and the group counts equal the
   kept tops. Checked for plane widths 4-128, with the ballot form where it is
   used (plane_size_max <= 32) and the scan form, plus the ballot form on a
   wider plane than reported (what a wrong plane_size_max would do).

2. check_kernel's work counter (pr/check-d bc9d87c7): lane 0 takes PLANE_DIM
   entries per round and lane i checks entry cur + i. Invariant: every list
   entry is checked once. Checked with full planes, and with a partially
   populated plane (fewer active lanes than PLANE_DIM).

Usage: python3 -I plane_models.py
"""
import random

def top_slot_plane(kept, g, cnt, ballot, real_width=None):
    """One plane's append. kept[i], g[i] per lane; cnt: group -> count (the
    atomics). Returns per-lane slot or None. ballot: the 32-bit ballot form;
    real_width lanes run (default len(kept))."""
    w = len(kept)
    g0 = g[0]
    one = all((not kept[i]) or g[i] == g0 for i in range(w))
    kc = [1 if (kept[i] and one) else 0 for i in range(w)]
    if ballot:
        b0 = 0
        for i in range(min(w, 32)):  # the C++ backends return the first word
            if kc[i]:
                b0 |= 1 << i
        n = bin(b0).count("1")
        def pre(i):
            if i >= 32:
                # (1u32 << UNIT_POS_PLANE) - 1 with UNIT_POS_PLANE >= 32: a
                # shift past the width (UB in WGSL/C++); model it as all
                # ones, the most common result
                m = 0xFFFFFFFF
            else:
                m = (1 << i) - 1
            return bin(b0 & m).count("1")
    else:
        n = sum(kc)
        def pre(i):
            return sum(kc[:i])
    a0 = 0
    if n > 0:
        a0 = cnt.get(g0, 0)
        cnt[g0] = a0 + n
    out = []
    for i in range(w):
        at = a0 + pre(i)
        if kept[i] and not one:
            at = cnt.get(g[i], 0)
            cnt[g[i]] = at + 1
        out.append((g[i], at) if kept[i] else None)
    return out

def check_top_slot(width, ballot, trials, rng):
    bad = 0
    for _ in range(trials):
        cnt = {}
        slots = set()
        kept_total = {}
        for plane in range(6):
            base_g = rng.randrange(4)
            kept = [rng.random() < 0.5 for _ in range(width)]
            # mostly one group per plane, sometimes a straddle
            if rng.random() < 0.3:
                cut = rng.randrange(width)
                g = [base_g if i < cut else base_g + 1 for i in range(width)]
            else:
                g = [base_g] * width
            res = top_slot_plane(kept, g, cnt, ballot)
            for i, r in enumerate(res):
                if r is not None:
                    if r in slots:
                        bad += 1
                    slots.add(r)
                    kept_total[g[i]] = kept_total.get(g[i], 0) + 1
        # every slot inside its group's count, counts exact
        for (grp, at) in slots:
            if at >= kept_total.get(grp, 0):
                bad += 1
        if any(cnt.get(k, 0) != v for k, v in kept_total.items()):
            bad += 1
    return bad

def check_counter(nentries, plane_dim, active, cubes_planes, rng):
    """Entries checked by the work counter when each plane has `active`
    lanes running out of plane_dim."""
    counter = 0
    seen = [0] * nentries
    planes = list(range(cubes_planes))
    done = set()
    curs = {}
    for p in planes:
        curs[p] = counter
        counter += plane_dim
    while len(done) < len(planes):
        p = rng.choice([q for q in planes if q not in done])
        cur = curs[p]
        if cur >= nentries:
            done.add(p)
            continue
        nxt = counter
        counter += plane_dim
        for lane in range(active):
            i = cur + lane
            if i < nentries:
                seen[i] += 1
        curs[p] = nxt
    lost = sum(1 for s in seen if s == 0)
    dup = sum(1 for s in seen if s > 1)
    return lost, dup

def main():
    rng = random.Random(2026_11_13)
    print("top_slot append (6 planes x 2000 trials per row):")
    for width in [4, 8, 16, 32, 64, 128]:
        for ballot in [False, True]:
            if ballot and width > 32:
                continue
            print(f"  plane {width:3d}, {'ballot' if ballot else 'scan  '}: "
                  f"{check_top_slot(width, ballot, 2000, rng)} violations")
    print("  plane  64, ballot (plane_size_max misreported as <= 32): "
          f"{check_top_slot(64, True, 2000, rng)} violations")
    print("check_kernel work counter (pr/check-d), list of 100,000 entries, 64 planes:")
    for dim, active in [(32, 32), (64, 64), (32, 31), (64, 32), (16, 8)]:
        lost, dup = check_counter(100_000, dim, active, 64, rng)
        print(f"  PLANE_DIM {dim:2d}, active lanes {active:2d}: {lost} entries never checked, {dup} twice")

if __name__ == "__main__":
    main()

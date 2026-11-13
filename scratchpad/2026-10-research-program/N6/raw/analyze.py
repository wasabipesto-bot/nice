#!/usr/bin/env python3
"""Summarise n6_top_counts output: python3 analyze.py [--csv] run.log [run2.log ...]

Pools the UNIT and FIELD lines of all files given (one base), prints counts,
failure classes, clustering, and per-scheme test totals and cost ratios.

Cost model (all in units of one FD top test step, today's marginal test):
  sigma  price of a fresh certificate / FD seed: measured 0.350 ns for a
         seeded slot vs 0.198 ns for a stepped one (EXPERIMENTS L35.1, RTX
         3080, b62) = 1.77; 1.8 central, 3 pessimistic, 1.4 optimistic
  eps    price of computing a skip end (bound on the next boundary of a
         colliding digit) -- assumed 0.5 central, 1 pessimistic
Today's top stage: every (parent, partition) pair is one step, and every
(parent, 16-slot batch) pays one seed: per test 1 + (sigma - 1)/16.
"""
import random
import re
import sys
from collections import defaultdict

PRICES = {"central": (1.8, 0.5), "pessimistic": (3.0, 1.0), "optimistic": (1.4, 0.25)}


def parse(paths):
    units, fields = [], []
    for src, p in enumerate(paths):
        for line in open(p):
            if not line.startswith(("UNIT", "FIELD")):
                continue
            d = {}
            for x in line.split()[1:]:
                k, v = x.split("=", 1)
                try:
                    d[k] = int(v)
                except ValueError:
                    try:
                        d[k] = float(v)
                    except ValueError:
                        d[k] = v
            d["_src"] = src
            # At b64 configs() lists [b/2] = [32] and [b] = [64] twice (the
            # same groups as [32], [64]): those keys hold exactly double.
            if d.get("b") == 64:
                for k in list(d):
                    if (k.startswith("g32_") or k.startswith("g64_")) and isinstance(d[k], int):
                        assert d[k] % 2 == 0, (k, d[k])
                        d[k] //= 2
            (units if line.startswith("UNIT") else fields).append(d)
    return units, fields


def tot(rows):
    t = defaultdict(int)
    for u in rows:
        for k, v in u.items():
            if isinstance(v, int) and k not in ("b", "f", "g", "s", "L", "fc_ok", "lengthchange", "_src"):
                t[k] += v
    return t


def schemes(t, w, price):
    """Scheme -> dict(tests=count/T0, cost=cost/today, viol=n, note)."""
    sg, ep = PRICES[price]
    T0 = t["tests"]
    today = T0 * (1 + (sg - 1) / 16)
    out = {}
    out["today"] = dict(tests=1.0, cost=1.0, viol=0, note="one FD step per pair, seed per 16-slot batch")
    floor = t["pass"] + sum(v for k, v in t.items() if re.match(r"frun_\d+$", k))
    out["floor"] = dict(tests=floor / T0, cost=None, viol=0, note="passes + fail runs: fewest tests of any test-and-skip order")
    for k in sorted(t):
        m = re.match(r"(g[\d-]+)_tests$", k)
        if not m:
            continue
        n = m.group(1)
        tests, seeds = t[k], t.get(n + "_seeds", 0)
        L0 = t.get(n + "_L0", 0)
        sizes = [int(x) for x in n[1:].split("-")]
        # restructured: pass 1 walks a parent's top-level groups by FD
        # (stride g); every passing group seeds a walk of its children.
        cost_r = tests + seeds * (sg - 1) + t["par_pass"] * (sg - 1)
        out[n] = dict(tests=tests / T0, cost=cost_r / today, viol=t.get(n + "_viol", 0),
                      note="two-pass, whole b^2 span (top stage decoupled from batches)")
        if len(sizes) == 1 and sizes[0] % 16 == 0:
            # pass 1 ahead of the batches: one thread per layer prefix walks
            # its b²/g groups by FD (stride g; one seed per prefix) and sets a
            # bit per passing group; each 16-slot batch then runs today's
            # kernel (seed per batch) over the prefixes whose group bit is set,
            # after a compaction (assumed 0.1 step per prefix and batch).
            L1 = t.get(n + "_L1", 0)
            cost_p = L0 + t["par_pass"] * (sg - 1) + L1 * (1 + (sg - 1) / 16) + 0.1 * T0 / 16
            out[n + "pre"] = dict(tests=tests / T0, cost=cost_p / today, viol=t.get(n + "_viol", 0),
                                  note="pass 1 (group bits) ahead of today's batches; batches unchanged")
        if all(16 % g == 0 for g in sizes):
            # inside today's 16-slot batches: a top-level group test is a fresh cert
            cost_b = (tests - L0) + L0 * sg + seeds * (sg - 1)
            out[n + "@b16"] = dict(tests=tests / T0, cost=cost_b / today, viol=t.get(n + "_viol", 0),
                                   note="two-pass inside each 16-slot batch")
    for k in sorted(t):
        m = re.match(r"(seg\d\d)_kept$", k)
        if not m:
            continue
        n = m.group(1)
        kept, runs, bnd = t[k], t[n + "_runs"], t[n + "_bnd"]
        cost = kept + runs * (sg - 1) + bnd * sg
        out[n] = dict(tests=kept / T0, cost=cost / today, viol=t.get(n + "_viol", 0),
                      note=f"slow-digit segments: {bnd/t['par_pass']:.0f} roots + {runs/t['par_pass']:.0f} runs per parent")
    tests, skips = t["skipB_tests"], t["skipB_skips"]
    fails = tests - t["pass"]
    out["skip_lane"] = dict(tests=tests / T0, cost=(tests + skips * (sg - 1) + fails * ep) / today,
                            viol=t.get("skipB_viol", 0), note="skip walk, each lane alone (no SIMT divergence): unreachable bound")
    out["skip_pairs"] = dict(tests=tests / T0, cost=(tests * sg + fails * ep) / today,
                             viol=t.get("skipB_viol", 0), note="every pair not jumped is a fresh cert (compacted list)")
    out["today_whole"] = dict(tests=1.0, cost=(T0 + t["par_pass"] * (sg - 1)) / today, viol=0,
                              note="today's tests, one seed per parent instead of per batch (decoupling alone)")
    for W in (16, 32):
        if w.get(f"span{W}_tests"):
            sp = w["span_pairs"]
            tw = sp * (1 + (sg - 1) / 16)
            npar = sp / (T0 / t["par_pass"])
            c = (w[f"span{W}_tests"] + w[f"span{W}_jumps"] * W * (sg - 1)
                 + w[f"span{W}_failspans"] * W * ep + npar * W * (sg - 1))
            out[f"span{W}"] = dict(tests=w[f"span{W}_tests"] / sp, cost=c / tw, viol=w.get(f"span{W}_viol", 0),
                                   note=f"warp per parent, {W} lanes over consecutive partitions, jump to the lanes' reach")
    if w.get("w_warps"):
        wt = w["w_today_iters"]
        tw = wt * (1 + (sg - 1) / 16)
        c = w["w_full_iters"] + w["w_full_reseed"] * (sg - 1) + w["w_full_failit"] * ep
        out["skip_warp_full"] = dict(tests=w["w_full_iters"] / wt, cost=c / tw, viol=0,
                                     note="skip walk, 32 random lanes in lockstep, whole span")
        for sl in (16, 64, 256):
            it = w[f"w_b{sl}_iters"]
            c = it + w[f"w_b{sl}_reseed"] * (sg - 1) + w[f"w_b{sl}_failit"] * ep + w[f"w_b{sl}_active"] * (sg - 1)
            out[f"skip_warp_b{sl}"] = dict(tests=it / wt, cost=c / tw, viol=0,
                                           note=f"skip-until across {sl}-slot batches, 32 random lanes in lockstep")
    return out


def boot(units, w, n=300, seed=1):
    """Bootstrap over field locations (units clustered by field) of the
    central cost of each per-unit scheme."""
    rnd = random.Random(seed)
    res = defaultdict(list)
    byf = defaultdict(list)
    for u in units:
        byf[(u["_src"], u["f"])].append(u)
    groups = list(byf.values())
    for _ in range(n):
        s = [u for _ in groups for u in groups[rnd.randrange(len(groups))]]
        for k, v in schemes(tot(s), {}, "central").items():
            if v["cost"] is not None:
                res[k].append(v["cost"])
            else:
                res[k].append(v["tests"])
    out = {}
    for k, v in res.items():
        v.sort()
        out[k] = (v[int(0.025 * len(v))], v[int(0.975 * len(v)) - 1])
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    units, fields = parse(args)
    t = tot(units)
    w = tot(fields)
    nf = len(fields)
    empty = sum(1 for f in fields if f.get("fc_ok") == 0)
    lc = sum(1 for f in fields if f.get("lengthchange"))
    nunits = w["units"]
    print(f"files {args}")
    print(f"fields {nf} (field certificate fails: {empty}; length change: {lc}); units drawn {nunits}, "
          f"grandparent and ancestors certified {w['gp_pass']}")
    T0, P = t["tests"], t["pass"]
    nv = T0 // t["par_pass"]
    print(f"parents tested {t['par_tests']}, in layer {t['par_pass']} ({t['par_pass']/t['par_tests']:.3f}); "
          f"pair tests {T0} = {t['par_pass']} x {nv}; pass {P} ({P/T0:.4f}), fail {1-P/T0:.4f}")
    print(f"cert cross-check: {t['chk_n']} checked, {t.get('chk_bad',0)} mismatches")
    F = T0 - P
    print("failures: repeat %.4f closure %.4f | first repeat: n2-n2 %.3f n3-n3 %.3f n2-n3 %.3f | "
          "new-vs-parent %.3f new-vs-new %.3f parent-parent %.3f" % (
              t["f_dup"] / F, t.get("f_closure", 0) / F, t["f_sqsq"] / F, t["f_cucu"] / F,
              t["f_sqcu"] / F, t["f_newpar"] / F, t["f_newnew"] / F, t.get("f_parpar", 0) / F))
    nd = {int(k[8:]): v for k, v in t.items() if k.startswith("f_depth_")}
    print("fewest top digits per power that show a repeat (share of repeat failures):",
          " ".join(f"{k}:{v/t['f_dup']:.3f}" for k, v in sorted(nd.items())))
    for pi, nm in ((0, "n2"), (1, "n3")):
        nn = {int(k.split("_")[-1]): v for k, v in t.items() if k.startswith(f"newdig_{pi}_")}
        print(f"{nm} positions a pair certifies beyond its parent (share of pairs):",
              " ".join(f"{k}:{v/T0:.3f}" for k, v in sorted(nn.items())))
        no = {int(k.split("_")[-1]): v for k, v in t.items() if k.startswith(f"f_newoff_{pi}_")}
        tot_no = sum(no.values())
        print(f"  first repeat's new {nm} digit, offset below the parent's lowest common position:",
              " ".join(f"{k}:{v/F:.3f}" for k, v in sorted(no.items())), f"(per failure; total {tot_no/F:.3f})")
    ff, fp, pf, pp = t["adj_ff"], t["adj_fp"], t["adj_pf"], t["adj_pp"]
    print(f"along partitions: P(fail | previous fails) {ff/(ff+fp):.4f}, P(fail | previous passes) {pf/(pf+pp):.4f}")
    sff, sfp, spf, spp = (t.get("sib_" + k, 0) for k in ("ff", "fp", "pf", "pp"))
    if sff + sfp:
        print(f"sibling parents, same partition: P(fail | sibling fails) {sff/(sff+sfp):.4f}, "
              f"P(fail | sibling passes) {spf/max(1,spf+spp):.4f}")
    fr = {int(k[6:]): v for k, v in t.items() if k.startswith("frunw_")}
    print("failing pairs by length of their run of consecutive failures:",
          " ".join(f"{1<<(k-1)}-{(1<<k)-1}:{v/F:.3f}" for k, v in sorted(fr.items())))
    pfh = {int(k[8:]): v for k, v in t.items() if k.startswith("parfrac_")}
    print("parents by share of passing partitions (0: none; k: ((k-1)/10, k/10]):",
          " ".join(f"{k}:{v/t['par_pass']:.3f}" for k, v in sorted(pfh.items())))
    print(f"mean jump after a repeat failure (pairs proven failing beyond it): first repeat "
          f"{t['f_skipF_sum']/t['f_dup']:.1f}, best repeat {t['f_skipB_sum']/t['f_dup']:.1f}")
    ci = boot(units, w) if len(units) > 10 else {}
    for price in ("central", "pessimistic", "optimistic"):
        sc = schemes(t, w, price)
        print(f"\nscheme ({price}: sigma {PRICES[price][0]}, eps {PRICES[price][1]}) | tests/today | "
              "cost/today | cost with append share alpha 0.2 of a passing test | exactness violations | 95% field-bootstrap of central cost | note")
        for k, v in sorted(sc.items(), key=lambda kv: (kv[1]["cost"] if kv[1]["cost"] is not None else kv[1]["tests"])):
            c = ci.get(k)
            cost = "-" if v["cost"] is None else f"{v['cost']:.3f}"
            pa = t["pass"] / T0
            ca = "-" if v["cost"] is None else f"{(v['cost'] + 0.2 * pa) / (1 + 0.2 * pa):.3f}"
            print(f"  {k:16s} {v['tests']:.3f} {cost:>6s} a0.2:{ca:>6s} {v['viol']} "
                  + (f"[{c[0]:.3f},{c[1]:.3f}]" if (c and price == 'central') else "") + f"  {v['note']}")
    # per field location
    print("\nper field (central costs): frac | pair tests per unit drawn | pass rate | g32 | g16@b16 | seg11 | skip_lane")
    for f in fields:
        if "tests" not in f or not f["tests"]:
            print(f"  {f.get('frac')} empty (fc_ok={f.get('fc_ok')})")
            continue
        sc = schemes(tot([f]), {}, "central")
        print(f"  {f['frac']} {f['tests']/f['units']:.0f} {f['pass']/f['tests']:.3f} "
              f"{sc['g32']['cost']:.3f} {sc['g16@b16']['cost']:.3f} {sc['seg11']['cost']:.3f} {sc['skip_lane']['cost']:.3f}")


if __name__ == "__main__":
    main()

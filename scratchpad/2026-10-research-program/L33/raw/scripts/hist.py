#!/usr/bin/env python3
"""Parse TOP_HIST lines (NICE_EXP_TOP_HIST=1) and print the failure-stage histograms."""
import sys, re
SP = {57: (23, 34), 58: (24, 35), 60: (24, 36), 62: (25, 37), 64: (26, 38)}
CD = 2  # b^2 < 2^16 for every live base

def blocks(v):
    return dict(cat=v[0:16], g=v[16:56], gp=v[56:96], wg=v[96:136], wgp=v[136:176],
                td2=v[176:216], td3=v[216:256], n2=v[256:296], n3=v[296:336], misc=v[336:344])

def pct(x, t):
    return 100.0 * x / t if t else 0.0

def report(base, size, v):
    s2, s3 = SP[base]
    P2, P3 = -(-s2 // CD), -(-s3 // CD)
    END, KEPT = P2 + P3, P2 + P3 + 1
    h = blocks(v)
    m = h["misc"]
    act, sqd, sqdp, viol, warps, wdead, wdeadp, _ = m
    cat = h["cat"]
    kept = cat[0]
    fail = act - kept
    out = []
    out.append(f"## b{base} {size}: {act:,} (prefix, partition) pairs in range, {kept:,} kept ({pct(kept, act):.1f} %), {fail:,} fail ({pct(fail, act):.1f} %)")
    out.append(f"square passes P2 = {P2} (s2 = {s2}), cube passes P3 = {P3} (s3 = {s3}), 2 digits a pass")
    out.append("")
    out.append("### Failure categories (final certificate; A = repeat within a², B = within a³, C = a² and a³ share a digit, D = closure only)")
    out.append("| category | pairs | % of failures | % of pairs |")
    out.append("|---|---|---|---|")
    names = {1: "A only", 2: "B only", 4: "C only", 3: "A + B", 5: "A + C", 6: "B + C", 7: "A + B + C", 8: "D (closure) only"}
    for k in [1, 2, 4, 3, 5, 6, 7, 8]:
        out.append(f"| {names[k]} | {cat[k]:,} | {pct(cat[k], fail):.1f} | {pct(cat[k], act):.1f} |")
    other = sum(cat[9:16])
    if other:
        out.append(f"| (impossible bins 9-15) | {other} | | |")
    anyA = sum(cat[k] for k in range(16) if k & 1)
    anyB = sum(cat[k] for k in range(16) if k & 2)
    anyC = sum(cat[k] for k in range(16) if k & 4)
    out.append(f"| any A (square dead on its own) | {anyA:,} | {pct(anyA, fail):.1f} | {pct(anyA, act):.1f} |")
    out.append(f"| any B | {anyB:,} | {pct(anyB, fail):.1f} | {pct(anyB, act):.1f} |")
    out.append(f"| any C | {anyC:,} | {pct(anyC, fail):.1f} | {pct(anyC, act):.1f} |")
    out.append("")
    out.append(f"- square dead after the square (A): {sqd:,} = {pct(sqd, act):.1f} % of pairs, {pct(sqd, fail):.1f} % of failures")
    out.append(f"- square dead with the parent's cube digits (A or a² ∩ parent's a³ digits): {sqdp:,} = {pct(sqdp, act):.1f} % of pairs, {pct(sqdp, fail):.1f} % of failures; violations (dead but kept): {viol}")
    out.append(f"- warps (32 lanes) with an in-range pair: {warps:,}; all in-range lanes square-dead: {wdead:,} ({pct(wdead, warps):.3f} %); with the parent: {wdeadp:,} ({pct(wdeadp, warps):.3f} %); mean in-range lanes per warp {act / warps if warps else 0:.1f}")
    out.append("")
    def ghist(name, arr, title, denom_label):
        tot = sum(arr)
        out.append(f"### {title}")
        out.append(f"| passes done when the pair is known dead | stage | {denom_label} | % | cum % |")
        out.append("|---|---|---|---|---|")
        cum = 0
        for g, c in enumerate(arr):
            if c == 0:
                continue
            cum += c
            if g == 0:
                st = "none (idle)"
            elif g < P2:
                st = f"square pass {g} of {P2}"
            elif g == P2:
                st = "end of square"
            elif g < END:
                st = f"cube pass {g - P2} of {P3}"
            elif g == END:
                st = "end of cube (incl. closure)"
            elif g == KEPT:
                st = "kept (full work)"
            else:
                st = "?"
            out.append(f"| {g} | {st} | {c:,} | {pct(c, tot):.2f} | {pct(cum, tot):.2f} |")
        out.append("")
    ghist("g", h["g"], "Per pair: earliest sound detection, production order (a² low digits first, then a³), no parent information", "pairs")
    ghist("gp", h["gp"], "Per pair: the same, with the parent's cube digits", "pairs")
    ghist("wg", h["wg"], "Per warp: the last lane's detection point (what an in-place early exit could skip)", "warps")
    ghist("wgp", h["wgp"], "Per warp, with the parent's cube digits", "warps")
    def dh(arr, title, unit):
        tot = sum(arr)
        out.append(f"### {title} (n = {tot:,})")
        out.append(f"| {unit} | pairs | % | cum % |")
        out.append("|---|---|---|---|")
        cum = 0
        for i, c in enumerate(arr):
            if c == 0:
                continue
            cum += c
            out.append(f"| {i} | {c:,} | {pct(c, tot):.2f} | {pct(cum, tot):.2f} |")
        out.append("")
    dh(h["td2"], "Square, pairs with a repeat (A): index from the top of the first certified digit that repeats one above it", "index from top (0 = top digit)")
    dh(h["td3"], "Cube, pairs with a repeat (B): index from the top of the first repeating certified digit", "index from top")
    dh(h["n2"], "Certified digits of a² (every in-range pair)", "digits")
    dh(h["n3"], "Certified digits of a³ (every in-range pair)", "digits")
    return "\n".join(out)

for path in sys.argv[1:]:
    for line in open(path, errors="replace"):
        mm = re.search(r"TOP_HIST base=(\d+) size=(\d+) n=(\d+) ([\d,]+)", line)
        if mm:
            v = [int(x) for x in mm.group(4).split(",")]
            print(report(int(mm.group(1)), f"{float(mm.group(2)):.0e}", v))
            print()

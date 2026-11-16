"""E6: optimal ADAPTIVE two-sided decision tree vs fixed strategies.

Node = (prefix P of depth t, residue R mod b^k), t + k <= L. A node is created at cost 1 and is
"alive" iff cert(P) and cert(R) are each distinct and disjoint (and P's interval is in range).
An alive node with t + k < L is refined either at the top (children P*b+d) or at the bottom
(children R + d*b^k); the algorithm chooses per node. At t + k = L the node is one n: alive
leaves cost 1 for the full check if n is admissible.
OPT = min over all adaptive strategies of total cost (exact DP);
ALT = alternate top/bottom; TOPFIRST = all top then bottom; BOTFIRST; also best fixed
switching depth. Usage: opt_tree.py b1,b2,..."""
import sys, json
from functools import lru_cache
from nicelib import *

sys.setrecursionlimit(10000)
import os
NORES = bool(os.environ.get('NORES'))


def run(b):
    lo, hi = nice_range(b)
    L = ndig(lo, b)
    roots = set(residues(b))

    @lru_cache(maxsize=None)
    def tmask(t, P):
        W = b ** (L - t)
        a, z = max(P * W, lo), min((P + 1) * W, hi) - 1
        if a > z:
            return -1  # empty
        if t == 0:
            return 0
        m = mask_of(top_cert(a, z, b))
        return -2 if m is None else m

    @lru_cache(maxsize=None)
    def bmask(k, R):
        if k == 0:
            return 0
        m = mask_of(bottom_cert(R, k, b))
        return -2 if m is None else m

    def alive(t, P, k, R):
        a = tmask(t, P)
        if a < 0:
            return False
        c = bmask(k, R)
        if c < 0:
            return False
        return (a & c) == 0

    def leaf(t, P, k, R):
        n = P * b ** k + R
        return 1 if (lo <= n < hi and (NORES or n % (b - 1) in roots)) else 0

    memo = {}

    def cost(t, P, k, R, strat):
        # cost of the subtree below an alive node (excluding the node's own creation)
        key = (t, P, k, R, strat)
        if key in memo:
            return memo[key]
        if t + k == L:
            v = leaf(t, P, k, R)
            memo[key] = v
            return v
        opts = []
        choices = []
        if strat == "opt":
            choices = ["top", "bot"]
        elif strat == "alt":
            choices = ["top" if t <= k else "bot"]
        elif strat == "top":
            choices = ["top" if t < L else "bot"]
        elif strat == "bot":
            choices = ["bot" if k < L - 1 else "top"]
        for ch in choices:
            s = 0
            if ch == "top" and t < L:
                for d in range(b):
                    P2 = P * b + d
                    if tmask(t + 1, P2) == -1:
                        continue
                    s += 1
                    if alive(t + 1, P2, k, R):
                        s += cost(t + 1, P2, k, R, strat)
            elif ch == "bot" and k < L:
                for d in range(b):
                    R2 = R + d * b ** k
                    s += 1
                    if alive(t, P, k + 1, R2):
                        s += cost(t, P, k + 1, R2, strat)
            else:
                continue
            opts.append(s)
        v = min(opts)
        memo[key] = v
        return v

    out = dict(b=b, L=L)
    for strat in ("alt", "top", "bot", "opt"):
        memo.clear()
        out[strat] = cost(0, 0, 0, 0, strat)
    out["states_opt"] = len(memo)
    return out


for b in [int(x) for x in sys.argv[1].split(",")]:
    print(json.dumps(run(b)), flush=True)

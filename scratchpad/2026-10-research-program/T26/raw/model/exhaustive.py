#!/usr/bin/env python3
"""Exhaustive single-call check of the fix's append on 8-lane planes: every non-empty set of active lanes, every set
of kept lanes among them, groups split at every cut (lanes below the cut in group 0, the rest in group 1; cut 0 and 8
= one group): both forms place every kept lane at a distinct record of its own group inside the counted range, and
the account is zero."""
import top_slot_model as T
W = 8; calls = bad = 0
for form in ('ballot', 'scan'):
    for A in range(1, 1 << W):
        act = [l for l in range(W) if A >> l & 1]
        for K in range(1 << len(act)):
            kept = {act[j] for j in range(len(act)) if K >> j & 1}
            for cut in range(W + 1):
                lanes = {l: dict(g=0 if l < cut else 1, kept=l in kept, active=l in act) for l in range(W)}
                cnt = [5, 9]; start = list(cnt)
                out, (dn, ds) = T.new_slot(lanes, cnt, form, False, False, lambda g: 100 * g)
                want = [sum(1 for l in kept if lanes[l]['g'] == g) for g in (0, 1)]
                ok = [cnt[g] - start[g] for g in (0, 1)] == want and dn == 0 and ds == 0 and \
                    sorted(out.values()) == sorted((g, start[g] + i) for g in (0, 1) for i in range(want[g])) and \
                    set(out) == kept
                calls += 1; bad += not ok
print(f'{calls} calls (8-lane planes, both forms), {bad} wrong')

#!/usr/bin/env python3
"""A synthetic coordinator record (submissions.jsonl, the format of scripts/midout_coordinator.py) for testing
`scripts/coverage_fields.py` and `lake exe coverage`. Nothing is searched: every field of one quantum of the
coordinate gets an accepted submission with an empty nice_numbers list, and every third field also gets a
rejected submission ("field already submitted").

  --drop I   field I (negative: from the end) gets only a rejected submission (so a script that took
             rejected submissions would see the field covered)
  --nice I   field I's accepted submission lists one nice number

usage: coverage_testdata.py BASE K0 K1 Q0 OUT.jsonl [--drop I] [--nice I]
"""
import json
import sys


def ceil_root(e, x):
    lo, hi = 0, 1
    while hi ** e < x:
        hi *= 2
    while lo + 1 < hi:  # lo^e < x <= hi^e
        m = (lo + hi) // 2
        if m ** e >= x:
            hi = m
        else:
            lo = m
    return hi if x > 0 else 0


def base_range(b):
    k = b // 5
    r = b % 5
    if r == 0:
        return ceil_root(3, b ** (3 * k - 1)), b ** k
    if r == 1:
        return None
    if r == 2:
        return b ** k, ceil_root(3, b ** (3 * k + 1))
    if r == 3:
        return ceil_root(3, b ** (3 * k + 1)), ceil_root(2, b ** (2 * k + 1))
    return ceil_root(2, b ** (2 * k + 1)), ceil_root(3, b ** (3 * k + 2))


def main(argv):
    b, k0, k1, q0 = (int(x) for x in argv[1:5])
    out = argv[5]
    opts = dict(zip(argv[6::2], (int(x) for x in argv[7::2])))
    lo, hi = base_range(b)
    h0 = lo // b ** k1
    H = (hi - 1) // b ** k1 - h0 + 1
    Q = H * b ** q0
    v_end = lo + H * b ** k1
    n = (v_end - lo) // Q
    drop = opts.get("--drop")
    nice = opts.get("--nice")
    drop = None if drop is None else drop % n
    nice = None if nice is None else nice % n
    coord = f"midout:{k0},{k1},{q0}"
    with open(out, "w") as o:
        for i in range(n):
            work = {"base": b, "coordinate": coord, "range_start": lo + i * Q, "range_end": lo + (i + 1) * Q,
                    "range_size": 0}
            sub = {"claim_id": 1000 + i, "username": "test", "client_version": "test",
                   "unique_distribution": None, "nice_numbers": [], "telemetry": {"pipeline": {"route": "midout"}}}
            if i == nice:
                sub["nice_numbers"] = [{"number": 0, "num_uniques": b}]
            rec = {"recv": 0.0, "claim_id": 1000 + i, "field": i, "claim_time": 0.0, "accepted": True,
                   "reason": None, "work": work, "submission": sub}
            if i != drop:
                o.write(json.dumps(rec) + "\n")
            if i % 3 == 0 or i == drop:
                rec = dict(rec, accepted=False, reason="field already submitted (claim %d)" % (1000 + i))
                o.write(json.dumps(rec) + "\n")
    sys.stderr.write(f"coverage_testdata: base {b} {coord}: lo {lo} v_end {v_end} quantum {Q}, {n} fields\n")


if __name__ == "__main__":
    main(sys.argv)

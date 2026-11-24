#!/usr/bin/env python3
"""The searched fields of a middle-out coordinator's record, for `lake exe coverage`.

Reads a `submissions.jsonl` written by `scripts/midout_coordinator.py` (format as of the fork's `dev/mo-clean`
at eb9ef776: one JSON object per line with "accepted", "field", "work" = the work-list entry
{"base","coordinate","range_start","range_end","range_size"} and "submission" = the client's DataToServer
with "nice_numbers": [{"number","num_uniques"}, ...]) and writes, one line per ACCEPTED submission only
(records with "accepted" not exactly true are skipped and counted on stderr):

    range_start  range_end-range_start  nice_count

The second column is the field's length in the coordinate's values v. It is NOT the coordinator's
"range_size", which counts the numbers n the field holds (common/examples/midout_fields.rs). nice_count is the
length of the submission's "nice_numbers" list: every entry counts, so a submission listing anything gives a
non-zero count and the checker says no (entries whose num_uniques is not the base are reported on stderr).

Every accepted record must have the same base and coordinate id "midout:K0,K1,Q0"; the first lines of the
output are comments naming them, and the command to run is printed on stderr.

usage: coverage_fields.py SUBMISSIONS.jsonl [OUT.txt]
"""
import json
import sys


def main(argv):
    if len(argv) not in (2, 3):
        sys.exit(__doc__.split("usage: ")[1].strip())
    out = open(argv[2], "w") if len(argv) == 3 else sys.stdout
    base = coord = None
    taken = skipped = odd = 0
    rows = []
    for i, line in enumerate(open(argv[1]), 1):
        if not line.strip():
            continue
        rec = json.loads(line)
        if rec.get("accepted") is not True:
            skipped += 1
            continue
        w = rec.get("work") or {}
        b, c = w.get("base"), w.get("coordinate")
        s, e = w.get("range_start"), w.get("range_end")
        if not all(isinstance(x, int) and not isinstance(x, bool) and x >= 0 for x in (b, s, e)):
            sys.exit(f"line {i}: accepted record without integer base/range_start/range_end")
        if e <= s:
            sys.exit(f"line {i}: empty field [{s}, {e})")
        if not (isinstance(c, str) and c.startswith("midout:")):
            sys.exit(f"line {i}: coordinate {c!r} is not midout:K0,K1,Q0")
        if base is None:
            base, coord = b, c
        elif (b, c) != (base, coord):
            sys.exit(f"line {i}: base {b} coordinate {c}, but earlier records have base {base} coordinate {coord}")
        nice = (rec.get("submission") or {}).get("nice_numbers")
        if not isinstance(nice, list):
            sys.exit(f"line {i}: accepted submission without a nice_numbers list")
        for x in nice:
            if not (isinstance(x, dict) and x.get("num_uniques") == b):
                odd += 1
        rows.append((s, e - s, len(nice)))
        taken += 1
    if base is None:
        sys.exit("no accepted submission")
    k0, k1, q0 = (int(x) for x in coord.split(":", 1)[1].split(","))
    out.write(f"# from {argv[1]}: {taken} accepted submissions, base {base}, coordinate {coord}\n")
    out.write("# range_start range_size(v) nice_count\n")
    for r in rows:
        out.write("%d %d %d\n" % r)
    if out is not sys.stdout:
        out.close()
    sys.stderr.write(f"coverage_fields: {taken} accepted, {skipped} not accepted (skipped)"
                     + (f", {odd} nice_numbers entries whose num_uniques is not {base}" if odd else "") + "\n")
    sys.stderr.write(f"check with: lake exe coverage {base} {k0} {k1} {q0} {argv[2] if len(argv) == 3 else 'FILE'}\n")


if __name__ == "__main__":
    main(sys.argv)

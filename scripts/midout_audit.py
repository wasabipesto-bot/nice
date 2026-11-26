#!/usr/bin/env python3
"""Audit the state of a middle-out development server (scripts/midout_coordinator.py) against its work list (read
only; standard library). It may run while the server runs.

usage: midout_audit.py --worklist W.json --state DIR [--stale SECONDS] [--quiet]

Prints the fields searched (one canon each; further accepted submissions are checks, agreeing or not), open (never
claimed), claimed (latest claim younger than --stale, default 3600 s) and claimed-and-stale; every problem: a field
with more than one canon, a check recorded before its field's canon, an accepted submission whose claim is not on
record or is another field's, two accepted submissions under one claim, a body that describes another field than its
claim (the typed body's `field`, or in records of the earlier wire, the route's telemetry `pipeline.field`), a record
whose field is not the work list's field at that index, a claim id recorded twice, a check that disagrees with its
canon; whether the canons cover the work list; and the nice numbers reported (every accepted submission, canon or
check, those of a check missing from its canon marked; refused ones separately). Records of the earlier wire (no `status`: POST /submit with the field in telemetry) are read as canons,
with a note. A torn last line (a write cut short, never acknowledged) is ignored with a note.

Exit status: 0 only if every field of the work list has exactly one canon and there is no problem; 1 otherwise;
2 if a state file has an unreadable line other than a torn last one.
"""
import argparse, json, os, sys, time

ap = argparse.ArgumentParser()
ap.add_argument("--worklist", required=True)
ap.add_argument("--state", required=True)
ap.add_argument("--stale", type=float, default=3600.0)
ap.add_argument("--quiet", action="store_true", help="print only problems and the verdict")
a = ap.parse_args()

fields = json.load(open(a.worklist))
problems, notes = [], []


def say(*x):
    if not a.quiet:
        print(*x)


def load(name):
    path = os.path.join(a.state, name)
    if not os.path.exists(path):
        return []
    data = open(path, "rb").read()
    whole = data.rfind(b"\n") + 1
    if whole < len(data):
        notes.append("%s: torn last line of %d bytes ignored (never acknowledged)" % (name, len(data) - whole))
    out = []
    for n, line in enumerate(data[:whole].splitlines(), 1):
        try:
            out.append((n, json.loads(line)))
        except ValueError as e:
            print("FATAL: %s line %d does not read: %s" % (name, n, e))
            sys.exit(2)
    return out


def num(x):
    return x if type(x) is int else int(x) if isinstance(x, str) and x.isdigit() else None


def field_of(name, n, rec):
    """The work-list index a record names, if the work list still has that field there (else a problem)."""
    i, w = rec.get("field"), rec.get("work")
    if not isinstance(i, int) or not 0 <= i < len(fields):
        problems.append("%s line %d: field %r is not in the work list" % (name, n, i))
        return None
    if w is None and name == "claims.jsonl":
        notes.append("claims.jsonl line %d: an older record without its field's value (trusted by index)" % n)
    elif w != fields[i]:
        problems.append("%s line %d: names field %d as %s, the work list has %s" % (name, n, i, json.dumps(w),
                                                                                     json.dumps(fields[i])))
        return None
    return i


def describes(d, f):
    """None if the body describes field f; else why not."""
    if not isinstance(d, dict):
        return "no body"
    if type(d.get("claim_id")) is not int:
        return "claim_id %r is not an integer" % (d.get("claim_id"),)
    want = (f.get("coordinate"), f.get("base"), f.get("range_start"), f.get("range_end", 0) - f.get("range_start", 0),
            f.get("range_size"))
    if isinstance(d.get("field"), dict):  # the typed body of POST /submit/midout
        fd = d["field"]
        got = (fd.get("coordinate"), fd.get("base"), num(fd.get("v_start")), num(fd.get("v_size")),
               num(fd.get("range_size")))
        return None if got == want else "describes %s, the claim's field is %s" % (got, want)
    tel = d.get("telemetry")
    pl = tel.get("pipeline") if isinstance(tel, dict) else None
    fd = pl.get("field") if isinstance(pl, dict) else None
    if not isinstance(pl, dict) or pl.get("route") != "midout":
        return "route %r, not 'midout'" % (pl.get("route") if isinstance(pl, dict) else None,)
    if not isinstance(fd, dict):
        return "no pipeline.field"
    got = (pl.get("coordinate"), num(fd.get("base")), num(fd.get("v_start")), num(fd.get("v_size")),
           num(fd.get("range_size")))
    return None if got == want else "describes %s, the claim's field is %s" % (got, want)


def numbers(d):
    """The nice numbers of a body, as integers (typed: decimal strings; earlier wire: {"number": n} objects)."""
    out = []
    raw = d.get("nice_numbers") if isinstance(d, dict) else None
    for x in raw if isinstance(raw, list) else []:
        v = x.get("number") if isinstance(x, dict) else x
        out.append(num(v) if num(v) is not None else v)
    return out


claims = {}       # claim_id -> (field index, time)
latest = {}       # field index -> time of its latest claim
for n, c in load("claims.jsonl"):
    cid = c.get("claim_id")
    if cid in claims:
        problems.append("claims.jsonl line %d: claim id %r recorded twice" % (n, cid))
        continue
    i = field_of("claims.jsonl", n, c)
    claims[cid] = (i, c.get("time", 0))
    if i is not None:
        latest[i] = max(latest.get(i, 0), c.get("time", 0))

accepted = {}     # field index -> [claim ids] of its canons
checks = {}       # field index -> number of checks
disagree = []     # (line, field, claim) of checks that differ from the canon
canon_result = {} # field index -> the canon's (numbers, shape, counters)
by_claim = set()
older = 0
nice_acc, nice_ref, refused = [], [], {}
for n, s in load("submissions.jsonl"):
    d = s.get("submission")
    nums = numbers(d)
    if not s.get("accepted"):
        r = str(s.get("reason")).split(" (")[0]
        refused[r] = refused.get(r, 0) + 1
        if nums:
            nice_ref.append((n, s.get("claim_id"), nums))
        continue
    i = field_of("submissions.jsonl", n, s)
    if i is None:
        continue
    cid = s.get("claim_id")
    status = s.get("status")
    if status is None:
        older += 1
        status = "canon"
    if cid in by_claim:
        problems.append("submissions.jsonl line %d: a second accepted submission under claim %r" % (n, cid))
    by_claim.add(cid)
    result = (nums, d.get("shape"), d.get("survivors"), d.get("checked"), d.get("slices")) \
        if isinstance(d, dict) else None
    if status == "canon":
        accepted.setdefault(i, []).append(cid)
        canon_result.setdefault(i, result)
    elif status == "check":
        if i not in accepted:
            problems.append("submissions.jsonl line %d: field %d recorded as a check before its canon" % (n, i))
        checks[i] = checks.get(i, 0) + 1
        c = canon_result.get(i)
        if c is not None and result is not None and (
                c[0] != result[0] or (c[1] == result[1] and c[2:] != result[2:])):
            disagree.append((n, i, cid))
            # a check that differs from its canon means one of the two searches is wrong: the canon may record a
            # field as searched that was not
            problems.append("submissions.jsonl line %d: field %d: the check under claim %r disagrees with the canon"
                            " (nice %s vs the canon's %s; counts %s vs %s)"
                            % (n, i, cid, result[0], c[0], list(result[2:]), list(c[2:])))
    else:
        problems.append("submissions.jsonl line %d: status %r" % (n, status))
    if cid not in claims:
        problems.append("submissions.jsonl line %d: field %d accepted under claim %r, which is not on record" % (n, i, cid))
    elif claims[cid][0] != i:
        problems.append("submissions.jsonl line %d: field %d accepted under claim %r, which is field %r's"
                        % (n, i, cid, claims[cid][0]))
    why = describes(d, fields[i])
    if why is None and d.get("claim_id") != cid:
        why = "body's claim_id %r is not the record's %r" % (d.get("claim_id"), cid)
    if why:
        problems.append("submissions.jsonl line %d: field %d accepted, but the submission %s" % (n, i, why))
    if status in ("canon", "check"):
        canon_nums = (canon_result.get(i) or (None,))[0] or []
        for x in nums:
            nice_acc.append((i, cid, x, status, status == "check" and x not in canon_nums))
if older:
    notes.append("%d accepted records of the earlier wire (POST /submit, no status), read as canons" % older)

now = time.time()
open_, live, stale = [], [], []
for i in range(len(fields)):
    if i in accepted:
        if len(accepted[i]) > 1:
            problems.append("field %d has %d canons (claims %s)" % (i, len(accepted[i]), accepted[i]))
        continue
    if i not in latest:
        open_.append(i)
    elif now - latest[i] >= a.stale:
        stale.append(i)
    else:
        live.append(i)

say("work list: %d fields (%s)" % (len(fields), a.worklist))
say("searched:  %d (one canon each); checks: %d, of which %d disagree with the canon%s"
    % (len(accepted), sum(checks.values()), len(disagree),
       (": " + "; ".join("line %d field %d claim %s" % x for x in disagree)) if disagree else ""))
say("open:      %d (never claimed)" % len(open_))
say("claimed:   %d (latest claim younger than %g s, not searched)" % (len(live), a.stale))
say("stale:     %d (latest claim %g s or older, not searched)%s"
    % (len(stale), a.stale, (": fields " + ", ".join(map(str, stale[:20])) + (" ..." if len(stale) > 20 else ""))
       if stale else ""))
say("claims on record: %d; refused submissions: %s" % (len(claims), refused or 0))
covered = len(accepted) == len(fields) and all(len(v) == 1 for v in accepted.values())
say("coverage: %s" % ("INCOMPLETE: %d of %d fields accepted" % (len(accepted), len(fields)) if not covered else
                      "every field of the work list searched, one canon each" + (", but see the problems below"
                                                                               if problems else "")))
say("nice numbers reported (every accepted submission): %s" % (", ".join("%s (field %d, claim %s, %s%s)" % (
    x, i, cid, st, ", NOT IN THE CANON" if missing else "") for i, cid, x, st, missing in nice_acc) or "none"))
if nice_ref:
    say("nice numbers in REFUSED submissions: %s" % "; ".join("line %d claim %s: %s" % r for r in nice_ref))
for x in notes:
    say("note: " + x)
for x in problems:
    print("PROBLEM: " + x)
ok = covered and not problems
print("audit: %s" % ("OK" if ok else "NOT OK (%d problems, %d of %d fields accepted)"
                     % (len(problems), len(accepted), len(fields))))
sys.exit(0 if ok else 1)

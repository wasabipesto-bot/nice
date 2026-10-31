#!/usr/bin/env python3
"""Alpha-equivalence diff of two kernel sources (main vs branch).

  kalign.py MAIN_FILE BRANCH_FILE [--show]

Names (l_N, l_mut_N, l_arr_N, a_N) are erased to align the two sources line
by line (difflib on the name-erased text). Over every aligned line pair the
names must correspond one to one: a single consistent renaming maps main's
aligned code onto the branch's. The report gives the renaming's conflicts
(must be 0), the lines only in main and only in the branch (with main's names
carried over through the renaming, new names marked with '), and the
variable declarations, compared as sets under the renaming.
"""
import difflib, re, sys

NAME = re.compile(r"\b(l_mut|l_arr|l|a)_(\d+)\b")
DECL = re.compile(r"^(?:var (?:l_mut|a)_\d+: .*;|\w+ (?:l_mut|l_arr)_\d+(?:\[\d+\])?;)$")

def load(path):
    lines = [l.rstrip() for l in open(path).read().splitlines()]
    decl = [l.strip() for l in lines if DECL.match(l.strip())]
    body = [l for l in lines if not DECL.match(l.strip())]
    return decl, body

def key(l):
    return NAME.sub(lambda m: m.group(1) + "_#", l)

def names(l):
    return [m.group(0) for m in NAME.finditer(l)]

def main():
    fa, fb = sys.argv[1], sys.argv[2]
    show = "--show" in sys.argv
    da, a = load(fa)
    db, b = load(fb)
    sm = difflib.SequenceMatcher(None, [key(l) for l in a], [key(l) for l in b], autojunk=False)
    fwd, bwd, conflicts = {}, {}, []
    ops = sm.get_opcodes()
    for tag, i1, i2, j1, j2 in ops:
        if tag != "equal":
            continue
        for i, j in zip(range(i1, i2), range(j1, j2)):
            for x, y in zip(names(a[i]), names(b[j])):
                if fwd.setdefault(x, y) != y or bwd.setdefault(y, x) != x:
                    conflicts.append((i + 1, j + 1, x, y, fwd[x], bwd[y]))
    # main's lines in the branch's names; branch-only names get a prime
    to_b = lambda l: NAME.sub(lambda m: fwd.get(m.group(0), m.group(0) + "?main"), l)
    mark_b = lambda l: NAME.sub(lambda m: m.group(0) if m.group(0) in bwd else m.group(0) + "'", l)
    hunks = [(t, i1, i2, j1, j2) for t, i1, i2, j1, j2 in ops if t != "equal"]
    only_a = sum(i2 - i1 for _, i1, i2, _, _ in hunks)
    only_b = sum(j2 - j1 for _, _, _, j1, j2 in hunks)
    print(f"{fa} -> {fb}: body {len(a)} -> {len(b)} lines; aligned {len(a) - only_a}; "
          f"only in main {only_a}, only in branch {only_b}; renaming {len(fwd)} names, conflicts {len(conflicts)}")
    for c in conflicts[:10]:
        print("  CONFLICT main line %d / branch line %d: %s~%s (had %s / %s)" % c)
    da_b = sorted(to_b(l) for l in da)
    db_m = sorted(mark_b(l) for l in db)
    extra_decl_b = sorted(set(db_m) - set(da_b))
    extra_decl_a = sorted(set(da_b) - set(db_m))
    print(f"  declarations: main {len(da)}, branch {len(db)}; only in main {extra_decl_a}; only in branch {extra_decl_b}")
    if show:
        for t, i1, i2, j1, j2 in hunks:
            print(f"  @@ {t} main {i1 + 1}-{i2} / branch {j1 + 1}-{j2}")
            for l in a[i1:i2]:
                print("  - " + to_b(l))
            for l in b[j1:j2]:
                print("  + " + mark_b(l))
    sys.exit(1 if conflicts else 0)

main()

#!/usr/bin/env python3
"""Host model of join_kernel's survivor stage and flush (T2.4 soundness audit).

Planes of one cube run the batch loop's protocol with an arbitrary interleaving
of their steps between barriers. Barriers match by count, not by call site (as
on hardware: a plane that skips a barrier pairs with the next one the others
reach). Each appended pair is unique; at the end every pair must be in the
global list exactly once, and the list's count must equal the pairs appended.

Protocols:
  new  - main a7a59c11 (and pr/join-survivor-stage-512): barrier, read sc,
         barrier, flush if sc >= FLUSH.
  old  - before #222 (per-chunk check inside the walk): barrier, read sc, flush
         (+ barrier) if sc >= FLUSH, and the next chunk's appends follow at once.

Usage: python3 -I stage_model.py
"""
import random

def run(protocol, cap, flush_at, nplanes, batches, rng, gcap=10**9):
    sh = {"cnt": 0, "base": 0}
    stage = [None] * cap
    glist = {}
    gcount = [0]
    pairs = []
    def plane(pid, appends):
        # one batch per element of appends
        nxt = 0
        for b, na in enumerate(appends):
            for j in range(na):
                pr = (pid, b, j)
                pairs.append(pr)
                def app(pr=pr):
                    at = sh["cnt"]; sh["cnt"] += 1
                    if at < cap:
                        stage[at] = pr
                    else:
                        g = gcount[0]; gcount[0] += 1
                        if g < gcap:
                            glist.setdefault(g, []).append(pr)
                yield ("step", app)
            yield ("barrier",)
            box = {}
            def rd(box=box):
                box["sc"] = sh["cnt"]
            yield ("step", rd)
            if protocol == "new":
                yield ("barrier",)
            if box["sc"] >= flush_at:
                yield from flush(pid, box)
                if protocol == "old":
                    yield ("barrier",)
            if protocol == "new":
                yield ("barrier",)  # end of batch (line 1024)
        # end of kernel
        yield ("barrier",)
        box = {}
        def rd2(box=box):
            box["sc"] = sh["cnt"]
        yield ("step", rd2)
        if box["sc"] > 0:
            yield from flush(pid, box)
    def flush(pid, box):
        n = min(box["sc"], cap)
        if pid == 0:
            def res():
                sh["base"] = gcount[0]; gcount[0] += n
            yield ("step", res)
        yield ("barrier",)
        lb = {}
        def rdb(lb=lb):
            lb["at"] = sh["base"]
        yield ("step", rdb)
        for i in range(pid, n, nplanes):
            def cp(i=i):
                g = lb["at"] + i
                if g < gcap:
                    glist.setdefault(g, []).append(stage[i])
            yield ("step", cp)
        yield ("barrier",)
        if pid == 0:
            def clr():
                sh["cnt"] = 0
            yield ("step", clr)
    gens = []
    for pid in range(nplanes):
        appends = [rng.choice([0, 0, 1, 5, 40, 120, 300]) for _ in range(batches)]
        gens.append(plane(pid, appends))
    waiting = [False] * nplanes
    done = [False] * nplanes
    while not all(done):
        live = [i for i in range(nplanes) if not done[i] and not waiting[i]]
        if not live:
            # all live planes at a barrier: release (exited planes do not hold it)
            for i in range(nplanes):
                waiting[i] = False
            continue
        i = rng.choice(live)
        try:
            ev = next(gens[i])
        except StopIteration:
            done[i] = True
            continue
        if ev[0] == "barrier":
            waiting[i] = True
        else:
            ev[1]()
    got = []
    for g in range(gcount[0]):
        got.extend(glist.get(g, [None]))
    lost = set(pairs) - set(x for x in got if x is not None)
    dup = len([x for x in got if x is not None]) - len(set(x for x in got if x is not None))
    stale = sum(1 for x in got if x is None)
    return len(pairs), gcount[0], len(lost), dup, stale

def main():
    for protocol in ["new", "old"]:
        for cap, fl in [(1024, 512), (512, 256), (8, 4)]:
            rng = random.Random(12345)
            bad = 0
            trials = 300
            worst = None
            for t in range(trials):
                n, cnt, lost, dup, stale = run(protocol, cap, fl, nplanes=8, batches=6, rng=rng)
                if lost or dup or stale or cnt != n:
                    bad += 1
                    worst = worst or (n, cnt, lost, dup, stale)
            print(f"{protocol:3s} stage {cap:4d} flush {fl:4d}: {bad}/{trials} runs lose, duplicate "
                  f"or miscount (first bad: pairs, count, lost, dup, stale = {worst})")

if __name__ == "__main__":
    main()

# summarise the time_* runs: per binary and base, processing_secs and device_wait_secs of each field (field 1 of 3 is
# the cold one: plan build and floor controller start), medians over the three rounds.
import json, glob, os, statistics as st, collections
rows = collections.defaultdict(list)
for d in sorted(glob.glob("/root/sra/runs/time_*")):
    tag = os.path.basename(d); _, w, b, r = tag.split("_")
    subs = []
    for l in open(d + "/out.jsonl"):
        x = json.loads(l)
        if x.get("claim_id", 1) == 1: continue
        p = x["telemetry"]["pipeline"]
        subs.append((x["claim_id"], x["telemetry"]["processing_secs"], p["device_wait_secs"], p["launches"], x["nice_numbers"]))
    subs.sort()
    for i, s in enumerate(subs):
        rows[(b, w, i + 1)].append(s)
print("base binary field#  processing_s (r1 r2 r3) median | device_wait_s median | launches | nice")
for k in sorted(rows):
    v = rows[k]; ps = [s[1] for s in v]; dw = [s[2] for s in v]
    print(k[0], k[1].ljust(4), k[2], " ".join(f"{x:.3f}" for x in ps), f"med {st.median(ps):.3f} | {st.median(dw):.3f} |", [s[3] for s in v], {str(s[4]) for s in v})
for b in ("b62", "b64"):
    for w in ("v348", "fix"):
        tot = [sum(s[1] for s in (rows[(b, w, i)][r] for i in (1, 2, 3))) for r in range(3)]
        print(b, w, "sum of 3 fields per round:", " ".join(f"{t:.3f}" for t in tot), f"median {st.median(tot):.3f}")

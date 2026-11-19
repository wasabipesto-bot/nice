import json,sys,collections
sent=collections.Counter(); bad=[]
for l in open(sys.argv[1]):
    d=json.loads(l)
    p=(d.get("telemetry") or {}).get("pipeline") or {}
    nice=[x.get("number") for x in d.get("nice_numbers") or []]
    if d["claim_id"]==1:
        sent[str(nice)]+=1
        if nice!=[69] and len(bad)<5: bad.append((nice,p.get("launches"),p.get("num_ranges"),p.get("valid_numbers"),p.get("device_busy_secs")))
        continue
    print("SUBMIT", d["claim_id"], "nice", nice, "route", p.get("route"), "launches", p.get("launches"),
          "ranges", p.get("num_ranges"), "valid", p.get("valid_numbers"), "busy", p.get("device_busy_secs"), "devwait", p.get("device_wait_secs"))
print("B10-SENTINEL (claim 1, b10 [47,100), truth [69]):", dict(sent), "non-[69] examples:", bad)

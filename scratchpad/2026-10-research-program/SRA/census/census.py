#!/usr/bin/env python3
"""SRA census (read-only, light): every nice-only submission since v3.4.0's release day, by bounded
submission-id ranges (100k ids per request, primary key), from ivory, 0.25 s apart.
Per range, two requests:
  (1) version, backend and route of every nice-only row  -> counted, not stored;
  (2) the rows that could have run the stride kernel on CubeCL's CUDA runtime, or any explicit stride route:
        (route present and not 'join')  OR  (backend = cubecl-cuda and route absent)
      with their field's base and size -> stored in rows.jsonl.
Resumable: state.json holds the next range. usage: census.py LO HI"""
import json, sys, time, os, urllib.request, urllib.parse, urllib.error, collections
API = "https://data.nicenumbers.net"
def get(path, tries=6):
    for k in range(tries):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
            with urllib.request.urlopen(req, timeout=120) as r: return json.load(r)
        except urllib.error.HTTPError as e:
            body = e.read()[:300].decode("utf8", "replace"); print("http", e.code, body, flush=True)
            if e.code in (400, 404): raise
        except Exception as e:
            print("retry", k, repr(e)[:120], flush=True)
        if k == tries - 1: raise SystemExit("giving up")
        time.sleep(3 * 2 ** k)
lo, hi = int(sys.argv[1]), int(sys.argv[2])
q = lambda s, safe: urllib.parse.quote(s, safe=safe)
sel1 = q("client_version,backend:telemetry->hardware->>gpu_backend,route:telemetry->pipeline->>route", ",:>-")
sel2 = q("id,field_id,username,client_version,submit_time,disqualified,build:telemetry->>build_sha,"
         "gpu:telemetry->hardware->>gpu_model,backend:telemetry->hardware->>gpu_backend,"
         "route:telemetry->pipeline->>route,reason:telemetry->pipeline->>stride_reason,"
         "valid:telemetry->pipeline->>valid_numbers,launches:telemetry->pipeline->>launches,"
         "nice:numbers,fields(base_id,range_start,range_size)", ",:>-()")
flt = q("(and(telemetry->pipeline->>route.not.is.null,telemetry->pipeline->>route.neq.join),"
        "and(telemetry->hardware->>gpu_backend.eq.cubecl-cuda,telemetry->pipeline->>route.is.null))", "(),.>-")
st = {"next": lo, "agg": {}, "rows": 0, "total": 0}
if os.path.exists("state.json"): st = json.load(open("state.json"))
agg = collections.Counter({k: v for k, v in st["agg"].items()})
t0 = time.time(); out = open("rows.jsonl", "a")
a = st["next"]
while a < hi:
    r1 = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&select={sel1}")
    for x in r1: agg[f'{x["client_version"]}|{x["backend"]}|{x["route"]}'] += 1
    time.sleep(0.25)
    try:
        r2 = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&or={flt}&select={sel2}")
    except urllib.error.HTTPError:
        # the 'numbers' column may not exist under that name: retry once without it
        sel2b = sel2.replace(q("nice:numbers,", ",:"), "")
        r2 = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&or={flt}&select={sel2b}")
    for x in r2: out.write(json.dumps(x, separators=(",", ":")) + "\n")
    out.flush()
    st = {"next": a + 100000, "agg": dict(agg), "rows": st["rows"] + len(r2), "total": st["total"] + len(r1)}
    json.dump(st, open("state.json", "w"))
    if (a - lo) // 100000 % 25 == 0:
        print(f"{a} total {st['total']} stored {st['rows']} {time.time()-t0:.0f}s", flush=True)
    a += 100000; time.sleep(0.25)
print("CENSUS_DONE", st["total"], "nice-only rows;", st["rows"], "stored;", f"{time.time()-t0:.0f}s", flush=True)

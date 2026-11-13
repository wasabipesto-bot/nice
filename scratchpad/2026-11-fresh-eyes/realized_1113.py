"""Realized gain on demoux of build a7a59c1 (main with #250, #252-#254) over c0c357a, from public telemetry.
Same method as launch_regression.py's groups: within a plan group (same launch count), join seconds against
survivors is a line; compare the two builds' lines at the pooled median survivors of the group.
Inputs: demoux_launches_1112.json (c0c357a, 11-11/12) and recent_niceonly_1113.json (both builds)."""
import json, collections
import numpy as np
f=lambda x: float(x) if x not in (None,"") else np.nan
old=[r for r in json.load(open("demoux_launches_1112.json")) if r["build"].startswith("c0c357a")]
new=[r for r in json.load(open("recent_niceonly_1113.json")) if r["username"]=="demoux" and (r["build"] or "").startswith("a7a59c1")]
old+= [r for r in json.load(open("recent_niceonly_1113.json")) if r["username"]=="demoux" and (r["build"] or "").startswith("c0c357a")]
seen=set(); o2=[]
for r in old:
    if r["id"] in seen: continue
    seen.add(r["id"]); o2.append(r)
def arr(rows): 
    A=np.array([[f(r["run"]),f(r["surv"]),f(r["launches"]),f(r.get("slots"))] for r in rows]); return A[~np.isnan(A).any(axis=1)]
O=arr(o2); N=arr(new)
print(f"c0c357a fields {len(O)} (non-empty {np.sum(O[:,2]>0)}); a7a59c1 fields {len(N)} (non-empty {np.sum(N[:,2]>0)})")
O=O[O[:,2]>0]; N=N[N[:,2]>0]
print("launch-count groups in the new build:", collections.Counter(N[:,2]).most_common(8))
res=[]
for l,n in collections.Counter(N[:,2]).most_common():
    mo=O[:,2]==l; mn=N[:,2]==l
    if mo.sum()<60 or mn.sum()<60: continue
    S0=np.median(np.concatenate([O[mo,1],N[mn,1]]))
    po=np.polyfit(O[mo,1]/1e11,O[mo,0],1); pn=np.polyfit(N[mn,1]/1e11,N[mn,0],1)
    ro=np.polyval(po,S0/1e11); rn=np.polyval(pn,S0/1e11)
    # bootstrap
    rng=np.random.default_rng(1); bs=[]
    for _ in range(300):
        io=rng.integers(0,mo.sum(),mo.sum()); i_n=rng.integers(0,mn.sum(),mn.sum())
        a=np.polyfit(O[mo][io,1]/1e11,O[mo][io,0],1); b=np.polyfit(N[mn][i_n,1]/1e11,N[mn][i_n,0],1)
        bs.append(np.polyval(a,S0/1e11)/np.polyval(b,S0/1e11))
    lo,hi=np.percentile(bs,[2.5,97.5])
    res.append((l,mo.sum(),mn.sum(),ro,rn,ro/rn,lo,hi))
    print(f"  launches {l:5.0f}: old n={mo.sum():4d} new n={mn.sum():4d}  at S={S0:.3e}: {ro:6.2f}s -> {rn:6.2f}s  x{ro/rn:.3f} [{lo:.3f}, {hi:.3f}]")
w=np.array([min(r[1],r[2]) for r in res]); x=np.array([r[5] for r in res])
print(f"weighted mean over groups: x{np.sum(w*x)/np.sum(w):.3f}  (groups {len(res)})")

# --- 2026-11-13: the card was shared with another load in some hours of 11-12 (join seconds doubled). Clean rule:
# keep an hour only if its 1,350-launch fields have p90 of join seconds < 15 s; then the same line comparison.
by=collections.defaultdict(list)
allr={r["id"]:r for r in o2}; allr.update({r["id"]:r for r in new})
for r in allr.values(): by[r["submit_time"][:13]].append(r)
clean=set()
for h,R in by.items():
    g=[f(r["run"]) for r in R if r["launches"]=="1350"]
    if len(g)>=20 and np.percentile(g,90)<15: clean.add(h)
dirty=sorted(h for h in by if h not in clean and any(r["launches"]=="1350" for r in by[h]))
print(f"\nclean hours {len(clean)} of {len(by)}; shared-card hours dropped: {dirty}")
Oc=arr([r for r in o2 if r["submit_time"][:13] in clean]); Nc=arr([r for r in new if r["submit_time"][:13] in clean])
Oc=Oc[Oc[:,2]>0]; Nc=Nc[Nc[:,2]>0]
res=[]
for l,n in collections.Counter(Nc[:,2]).most_common():
    mo=Oc[:,2]==l; mn=Nc[:,2]==l
    if mo.sum()<60 or mn.sum()<40: continue
    S0=np.median(np.concatenate([Oc[mo,1],Nc[mn,1]]))
    rng=np.random.default_rng(2); bs=[]
    po=np.polyfit(Oc[mo,1]/1e11,Oc[mo,0],1); pn=np.polyfit(Nc[mn,1]/1e11,Nc[mn,0],1)
    ro=np.polyval(po,S0/1e11); rn=np.polyval(pn,S0/1e11)
    for _ in range(400):
        io=rng.integers(0,mo.sum(),mo.sum()); i_n=rng.integers(0,mn.sum(),mn.sum())
        bs.append(np.polyval(np.polyfit(Oc[mo][io,1]/1e11,Oc[mo][io,0],1),S0/1e11)/np.polyval(np.polyfit(Nc[mn][i_n,1]/1e11,Nc[mn][i_n,0],1),S0/1e11))
    lo,hi=np.percentile(bs,[2.5,97.5]); res.append((min(mo.sum(),mn.sum()),ro/rn))
    print(f"  launches {l:5.0f}: old n={mo.sum():4d} new n={mn.sum():4d}  at S={S0:.3e}: {ro:6.2f}s -> {rn:6.2f}s  x{ro/rn:.3f} [{lo:.3f}, {hi:.3f}]")
w=np.array([r[0] for r in res]); x=np.array([r[1] for r in res])
print(f"clean hours, weighted mean over groups: x{np.sum(w*x)/np.sum(w):.3f}")

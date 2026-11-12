"""N16/H1 from production telemetry: does demoux's join time per field carry a per-launch term?
Rows: demoux nice-only b60 1e16 fields on build c0c357a (public API, id-range pull -> demoux_launches_1112.json).
Model: run_secs = a + alpha*survivors + beta*checked + gamma*launches (non-empty fields; two fields in flight)."""
import json, sys, collections
import numpy as np
rows=json.load(open(sys.argv[1] if len(sys.argv)>1 else "demoux_launches_1112.json"))
f=lambda x: float(x) if x not in (None,"") else np.nan
D=np.array([[f(r["run"]),f(r["surv"]),f(r["chk"]),f(r["launches"]),f(r["slots"]),f(r["slices"]),f(r["setup"]),f(r["tot"]),f(r["inflight"])] for r in rows if r["build"].startswith("c0c357a")])
D=D[~np.isnan(D).any(axis=1)]
ne=D[D[:,3]>0]; em=D[D[:,3]==0]
print(f"fields {len(D)}  non-empty {len(ne)}  empty {len(em)} ({len(em)/len(D):.1%})  in flight: {collections.Counter(D[:,8]).most_common(3)}")
print(f"empty fields: run {np.median(em[:,0]):.3f}s setup {np.median(em[:,6]):.3f}s total {np.median(em[:,7]):.3f}s")
run,S,C,L=ne[:,0],ne[:,1],ne[:,2],ne[:,3]
print(f"non-empty: run median {np.median(run):.2f}s, launches median {np.median(L):.0f}, run/launch {np.median(run/L)*1e3:.2f} ms, S median {np.median(S):.3e}, C/S {np.median(C/S):.4f}")
print("corr(S,L)=%.3f corr(S,C)=%.3f corr(run,S)=%.3f corr(run,L)=%.3f"%(np.corrcoef(S,L)[0,1],np.corrcoef(S,C)[0,1],np.corrcoef(run,S)[0,1],np.corrcoef(run,L)[0,1]))
def fit(cols,names,y=run):
    X=np.column_stack([np.ones(len(y))]+cols); b,res,rk,sv=np.linalg.lstsq(X,y,rcond=None)
    r=y-X@b; s2=r@r/(len(y)-X.shape[1]); cov=s2*np.linalg.inv(X.T@X); se=np.sqrt(np.diag(cov))
    print("  "+"  ".join(f"{n}={v:.4g}±{e:.2g}" for n,v,e in zip(["a"]+names,b,se)), f" rmse={np.sqrt(s2):.3f}s R2={1-r.var()/y.var():.4f}")
    return b,se
print("fit run ~ S:");            fit([S/1e11],["per1e11S"])
print("fit run ~ S + L:");        b,se=fit([S/1e11,L/1e3],["per1e11S","per1e3L"])
print("fit run ~ S + C + L:");    b3,se3=fit([S/1e11,C/1e10,L/1e3],["per1e11S","per1e10C","per1e3L"])
g=b[2]; print(f"gamma = {g:.3f} ± {se[2]:.3f} s per 1000 launches = {g:.3f} ms per launch; at 1350 launches: {g*1.35:.2f}s of a {np.median(run[L==1350]):.2f}s run ({g*1.35/np.median(run[L==1350]):.1%})")
# within-group check: fixed launches, slope on S; and matched-S comparison between launch groups
print("per launch group (n>=50): n, median run, median S, run at S=1.5e11 by the group's own line")
for l,n in collections.Counter(L).most_common(12):
    m=L==l
    if n<50: continue
    p=np.polyfit(S[m]/1e11,run[m],1); print(f"  L={l:5.0f} slots={np.median(ne[m,4]):.0f} n={n:4d} run={np.median(run[m]):6.2f} S={np.median(S[m]):.3e} slope={p[0]:.3f} s/1e11  pred@1.5e11={np.polyval(p,1.5):.2f}  pred@0.8e11={np.polyval(p,0.8):.2f}")

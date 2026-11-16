# Test: is the middle uniform given clean ends?  For each base: among n whose end-determined
# digits E (low k of n^2,n^3 + prefix certificate of top t digits) are distinct, compare the
# distribution of total distinct digits with the iid-uniform-middle model.
import json, math, sys
from math import comb, factorial
bases=[int(x) for x in sys.argv[1:]] or [17,18,19,20,22,23,24,25,27,28,29,30]
def model(b,e):
    m=b-e
    p=[0.0]*(m+1); p[0]=1.0
    for _ in range(m):
        q=[0.0]*(m+1)
        for s,v in enumerate(p):
            if v==0: continue
            q[s]+=v*(e+s)/b
            if s<m: q[s+1]+=v*(b-e-s)/b
        p=q
    return p  # p[s]: s fresh distinct -> total distinct e+s
def Puni(b,e): return math.prod((b-i)/b for i in range(e))
print("base L  frac_Eclean  /uniformE |  ratio meas/model of P(total>=b-j | Eclean), j=0..4  [counts]  | chi2/dof")
for b in bases:
    try: s=json.load(open('data/b%d_stats.json'%b))
    except FileNotFoundError: continue
    T=s['total']; H=s['hist_e_mid']
    ecl=sum(sum(r) for r in H)
    # expected E-clean under uniform E, weighted by e distribution of all n: approx using ecoll hist? use e of clean ones not avail for all; report frac
    # aggregate over e
    meas=[0]*5; mod=[0.0]*5; chi=0; dof=0
    exp_ecl=0
    for e,row in enumerate(H):
        Ne=sum(row)
        if Ne==0: continue
        p=model(b,e)
        for j in range(5):
            meas[j]+=sum(row[b-jj] for jj in range(j+1))
            mod[j]+=Ne*sum(p[b-e-jj] for jj in range(j+1) if 0<=b-e-jj<len(p))
        # chi2 over bins with expected >=5
        for sidx,pv in enumerate(p):
            ex=Ne*pv; ob=row[e+sidx]
            if ex>=5: chi+=(ob-ex)**2/ex; dof+=1
    es=[e for e,row in enumerate(H) if sum(row)>0]
    rat=' '.join("%.3f"%(meas[j]/mod[j]) if mod[j]>0 else '-' for j in range(5))
    cnt=' '.join(str(meas[j]) for j in range(5))
    print(f"{b:3d} {s['L']:2d} {ecl/T:.4f} e={min(es)}..{max(es)} | {rat} [{cnt}] | {chi/max(dof-1,1):.2f} ({dof})")

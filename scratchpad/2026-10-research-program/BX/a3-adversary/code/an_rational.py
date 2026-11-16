# Is near-niceness (given clean ends, weighted by the model given e) enriched near small rationals x = n/b^L ≈ p/q?
import numpy as np, sys, math
sys.path.insert(0,'code'); from load import load; from an_middle_model import model
rows=[]
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); L=s['L']
    ref=smp[smp['eclean']==1]; thr=b-s['slack']+1
    P=pos[(pos['eclean']==1)&(pos['nice']>=thr)]
    pe={e:sum(v for si,v in enumerate(model(b,e)) if e+si>=thr) for e in np.unique(ref['e'])}
    w=np.array([pe[e] for e in ref['e']]); w/=w.sum()
    xp=P['n'].astype(float)/b**L; xr=ref['n'].astype(float)/b**L
    out=[]
    for Q in [2,3,5,8,13,21,34]:
        for eps in [1e-3]:
            def near(x):
                m=np.zeros(len(x),bool)
                for q in range(1,Q+1): m|= np.abs(q*x-np.round(q*x))<eps*q
                return m
            fp=near(xp).mean(); fr=(w*near(xr)).sum()
            z=(fp-fr)/math.sqrt(max(fr*(1-fr),1e-12)/len(xp))
            out.append(f"Q{Q}:{fp/fr if fr else 0:.2f}({z:+.1f})")
    print(f"b{b} pos={len(P)} near p/q (|qx-p|<1e-3 q) lift(z): "+' '.join(out))

# Broad "anything cheap" test: can a gradient-boosted model predict the interior (core) collisions
# from cheap features of n (every digit of n, n mod small primes, n mod b±1, position x)?
# Targets: (a) collisions among core digits only, (b) core digits hitting the outer digit set.
import numpy as np, sys, json, math, os
from sklearn.ensemble import HistGradientBoostingRegressor
for b in [int(x) for x in sys.argv[1].split(',')]:
    s=json.load(open(f'data/b{b}_stats.json')); l2=s['l2']; l3=s['l3']; k=s['k']; t=s['t']; L=s['L']
    D=np.load(f"data/b{b}_sampleD.npy")[:600000].astype(np.int16)
    from load import load
    _,smp,_=load(b); n=smp["n"][:600000].astype(np.int64)
    core=[i for i in range(k+2,l2-t-2)]+[l2+j for j in range(k+2,l3-t-2)]
    outer=[i for i in range(l2+l3) if i not in core]
    C=D[:,core]; N=len(n)
    srt=np.sort(C,axis=1); ycore=(np.diff(srt,axis=1)==0).sum(1).astype(float)
    mask=np.zeros((N,b),bool); mask[np.arange(N)[:,None],D[:,outer]]=True
    yhit=mask[np.arange(N)[:,None],C].sum(1).astype(float)-len(core)*mask.sum(1)/b  # residual vs null given |outer set|
    # features
    F=[]; cat=[]
    x=n.copy()
    for i in range(L): F.append(x%b); x//=b; cat.append(True)
    for p in [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,b-1,b+1]:
        F.append(n%p); cat.append(p<=255)
    F.append(n/ (s['range'][1])); cat.append(False)
    X=np.stack(F,1).astype(float)
    rng=np.random.default_rng(0); idx=rng.permutation(N); tr=idx[:int(.75*N)]; te=idx[int(.75*N):]
    for name,y in [('core-internal collisions',ycore),('core hits outer (resid)',yhit)]:
        res=[]
        for shuffle in [False,True]:
            yy=y.copy()
            if shuffle: yy=yy[rng.permutation(N)]
            m=HistGradientBoostingRegressor(max_iter=200,learning_rate=0.1,max_leaf_nodes=31,categorical_features=np.array(cat),
                                            early_stopping=True,validation_fraction=0.1,random_state=0)
            m.fit(X[tr],yy[tr]); pr=m.predict(X[te])
            r2=1-((yy[te]-pr)**2).mean()/yy[te].var()
            res.append(r2)
        print(f"b{b} {name:26s} held-out R2 {res[0]:+.5f} (shuffled-target control {res[1]:+.5f}); target var {y.var():.3f}",flush=True)

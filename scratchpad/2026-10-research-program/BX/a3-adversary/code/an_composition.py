# Does the core's chance of hitting the outer digit set depend on WHICH digits the outer set holds?
import numpy as np, sys, json, math
for b in [int(x) for x in sys.argv[1].split(',')]:
    s=json.load(open(f'data/b{b}_stats.json')); l2=s['l2']; l3=s['l3']; k=s['k']; t=s['t']
    D=np.load(f'data/b{b}_sampleD.npy').astype(np.int64); N=len(D)
    core=[i for i in range(k+2,l2-t-2)]+[l2+j for j in range(k+2,l3-t-2)]
    outer=[i for i in range(l2+l3) if i not in core]
    O=D[:,outer]; C=D[:,core]
    mask=np.zeros((N,b),bool); mask[np.arange(N)[:,None],O]=True
    size=mask.sum(1)
    hits=mask[np.arange(N)[:,None],C].sum(1)            # core digits lying in the outer set
    exp=len(core)*size/b
    resid=hits-exp
    feats={
      'mean outer digit (quintile)': np.digitize((mask*np.arange(b)).sum(1)/size, np.quantile((mask*np.arange(b)).sum(1)/size,[.2,.4,.6,.8])),
      'outer has 0': mask[:,0].astype(int),
      'outer has b-1': mask[:,b-1].astype(int),
      'outer #even (quintile)': np.digitize(mask[:,::2].sum(1)-size/2, np.quantile(mask[:,::2].sum(1)-size/2,[.2,.4,.6,.8])),
      'outer #digits<b/4 (quintile)': np.digitize(mask[:,:b//4].sum(1)-size/4, np.quantile(mask[:,:b//4].sum(1)-size/4,[.2,.4,.6,.8])),
    }
    sd=math.sqrt(len(core)*(size.mean()/b)*(1-size.mean()/b))
    print(f"b{b} N={N} core={len(core)} outer={len(outer)}; residual hits (obs-exp) per n, by group [z]:")
    for name,f in feats.items():
        out=[]
        for v in np.unique(f):
            r=resid[f==v]; out.append(f"{v}:{r.mean():+.4f}[{r.mean()/(sd/math.sqrt(len(r))):+.1f}]")
        print(f"   {name:30s} "+' '.join(out))

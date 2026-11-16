# Square/cube digit-set dependence: matched (A(n), C(n)) vs shuffled pairing within strata.
import numpy as np, sys, math
sys.path.insert(0,'code'); from load import load
rng=np.random.default_rng(7)
def popc(x):
    x=x.copy(); c=np.zeros(len(x),dtype=np.int64)
    while x.any():
        c+= (x&np.uint64(1)).astype(np.int64); x>>=np.uint64(1)
    return c
print("base | strata | mean|A∩C| matched shuffled (z) | among A,C internally distinct: P(overlap<=1) matched/shuffled (z) | P(overlap=k) ratio k=0..3")
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); L=s['L']
    n=smp['n'].astype(np.int64); mA=smp['mA']; mC=smp['mC']
    for strat_name, key in [('n mod b', n%b), ('n mod b^2, x-bin', (n%(b*b))*20 + np.minimum((n/s['range'][1]*20).astype(int),19))]:
        # shuffle C within strata
        order=np.lexsort((rng.random(len(n)),key)); ks=key[order]
        perm=order.copy()
        # within each stratum, rotate by one
        starts=np.r_[0,np.flatnonzero(np.diff(ks))+1]; ends=np.r_[starts[1:],len(ks)]
        sh=np.empty_like(order)
        for a,e in zip(starts,ends):
            if e-a<2: sh[a:e]=order[a:e]; continue
            sh[a:e]=np.roll(order[a:e],1)
        Csh=np.empty_like(mC); Csh[order]=mC[sh]
        ndA=smp['ndA'].astype(int); lA=smp['lA'].astype(int); lC=smp['lC'].astype(int)
        ndC=smp['ndC'].astype(int)
        # shuffled C's internal-distinctness travels with it
        ndCsh=np.empty_like(ndC); ndCsh[order]=ndC[sh]
        om=popc(mA&mC); osh=popc(mA&Csh)
        z=(om.mean()-osh.mean())/math.sqrt(om.var()/len(om)+osh.var()/len(osh))
        dm=(ndA==lA)&(ndC==lC); ds=(ndA==lA)&(ndCsh==lC)
        pm=(om[dm]<=1).mean() if dm.sum() else float('nan'); ps=(osh[ds]<=1).mean() if ds.sum() else float('nan')
        zz=(pm-ps)/math.sqrt(pm*(1-pm)/max(dm.sum(),1)+ps*(1-ps)/max(ds.sum(),1)) if dm.sum() and ds.sum() else 0
        rat=[]
        for k in range(4):
            a=(om[dm]==k).mean() if dm.sum() else 0; c=(osh[ds]==k).mean() if ds.sum() else 0
            rat.append(f"{a/c:.2f}" if c>0 else '-')
        print(f"b{b:2d} | {strat_name:16s} | {om.mean():.4f} {osh.mean():.4f} ({z:+.1f}) | n={dm.sum()} {pm:.4f}/{ps:.4f} ({zz:+.1f}) | {' '.join(rat)}")

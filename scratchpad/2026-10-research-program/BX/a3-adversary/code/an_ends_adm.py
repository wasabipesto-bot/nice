# E-clean fraction among admissible n (residue-pass mod b-1) vs uniform product, from the sample.
import numpy as np, sys, math
sys.path.insert(0,'code'); from load import load
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b)
    roots=[x for x in range(b-1) if (x*x+x**3)%(b-1)==(b*(b-1)//2)%(b-1)]
    if not roots: continue
    n=smp['n'].astype(np.int64); adm=np.isin(n%(b-1),roots)
    out=[]
    for name,msk in [('all',np.ones(len(n),bool)),('adm',adm)]:
        e=smp['e'][msk].astype(int); cl=smp['eclean'][msk]
        pu=np.array([math.prod((b-i)/b for i in range(k)) for k in range(65)])
        r=cl.mean()/pu[e].mean()
        out.append(f"{name}: n={msk.sum()} clean {cl.mean():.4f} uniform {pu[e].mean():.4f} ratio {r:.3f}")
    print(f"b{b} roots {len(roots)} | "+' | '.join(out))

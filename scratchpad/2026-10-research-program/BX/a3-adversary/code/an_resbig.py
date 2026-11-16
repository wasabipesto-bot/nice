# Residues of near-nice n for structured moduli: b^2+1, b^3-1, b^3+1, b^2+b+1, (b-1)^2, (b+1)^2, b^4-1 (coprime part)
import numpy as np, sys, math
from math import gcd
sys.path.insert(0,'code'); from load import load
from scipy.stats import chi2 as CHI2
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); T=s['total']
    for slack in [s['slack'], s['slack']-1]:
        P=pos[pos['nice']>=b-slack]; n=P['n'].astype(np.int64)
        out=[]
        for name,m in [('b2+1',b*b+1),('b3-1',b**3-1),('b3+1',b**3+1),('b2+b+1',b*b+b+1),('(b-1)^2',(b-1)**2),('(b+1)^2',(b+1)**2),('b2-b+1',b*b-b+1)]:
            # bin to keep expected >= 5
            cnt=np.bincount(n%m,minlength=m).astype(float)
            ex=len(n)/m
            if ex<5:
                # coarse test: dispersion of counts vs Poisson (index of dispersion)
                st=((cnt-ex)**2/ex).sum(); dof=m-1
            else:
                st=((cnt-ex)**2/ex).sum(); dof=m-1
            z=(st-dof)/math.sqrt(2*dof)
            out.append(f"{name}:{z:+.1f}")
        print(f"b{b} nice>={b-slack} n={len(n)} chi2 z-scores: {' '.join(out)}")

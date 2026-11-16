# Do middle collisions of n and n+delta correlate beyond what shared views explain?
# For sampled n: c(n) = number of repeated digits (b - niceness) counted on the fixed interior
# positions only (excluding low k+2 and top t+2 of n^2 and n^3), and E-clean flags.
import numpy as np, sys, json, math
sys.path.insert(0,'code'); from load import load
rng=np.random.default_rng(3)
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); L=s['L']; l2=s['l2']; l3=s['l3']; k=s['k']; t=s['t']
    I2=list(range(k+2,l2-t-2)); I3=list(range(k+2,l3-t-2))
    ns=[int(x) for x in rng.choice(smp['n'],60000,replace=False)]
    def interior(n):
        a=n*n; c=a*n; da=[]; dc=[]
        for i in range(l2): da.append(a%b); a//=b
        for j in range(l3): dc.append(c%b); c//=b
        v=[da[i] for i in I2]+[dc[j] for j in I3]
        return len(v)-len(set(v)), v
    deltas=[1,2,3,b-1,b,b+1,b**k,b**k+1,b**(k+1),b**(L-2),12345]
    base=[interior(n) for n in ns]; c0=np.array([x[0] for x in base])
    out=[]
    for d in deltas:
        c1=np.array([interior(n+d)[0] for n in ns])
        r=np.corrcoef(c0,c1)[0,1]
        out.append(f"d={d}:{r:+.3f}")
    print(f"b{b} interior n {len(I2)}+{len(I3)} digits, corr(c(n),c(n+d)) (null sd {1/math.sqrt(len(ns)):.3f}): "+' '.join(out))

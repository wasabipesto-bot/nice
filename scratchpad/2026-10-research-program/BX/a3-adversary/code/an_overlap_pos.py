# Where are the digits shared by n^2 and n^3, for n whose n^2 and n^3 are each internally distinct
# (taken from the near-nice file, so overlap <= slack)?  Uniform expectation: each n^2 position
# equally likely, each n^3 position equally likely.
import numpy as np, sys, math
sys.path.insert(0,'code'); from load import load
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); l2=s['l2']; l3=s['l3']
    P=pos[(pos['ndA']==l2)&(pos['ndC']==l3)]
    c2=np.zeros(l2); c3=np.zeros(l3); tot=0
    for x in P['n']:
        x=int(x); a=x*x; c=a*x
        da=[(a//b**i)%b for i in range(l2)]; dc=[(c//b**j)%b for j in range(l3)]
        sh=set(da)&set(dc); tot+=len(sh)
        for i,d in enumerate(da):
            if d in sh: c2[i]+=1
        for j,d in enumerate(dc):
            if d in sh: c3[j]+=1
    e2=tot/l2; e3=tot/l3
    print(f"b{b} n={len(P)} shared digits={tot}")
    print("  n^2 pos obs/exp:", ' '.join(f"{c2[i]/e2:.2f}" for i in range(l2)))
    print("  n^3 pos obs/exp:", ' '.join(f"{c3[j]/e3:.2f}" for j in range(l3)))

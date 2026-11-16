# Collision rate for every pair of output positions (sample of n), vs 1/b.
# Positions: n^2 digit i -> 'S i', n^3 digit j -> 'C j' (0 = least significant).
import numpy as np, sys, math
sys.path.insert(0,'code'); from load import load
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); L=s['L']; l2=s['l2']; l3=s['l3']
    n=smp['n'].astype(object)
    # digits via python ints in chunks (n^3 may exceed int64)
    N=len(n); D=np.zeros((N,l2+l3),dtype=np.int16)
    for idx in range(N):
        x=int(n[idx]); a=x*x; c=a*x
        for i in range(l2): D[idx,i]=a%b; a//=b
        for j in range(l3): D[idx,l2+j]=c%b; c//=b
    names=[f"S{i}" for i in range(l2)]+[f"C{j}" for j in range(l3)]
    rows=[]
    for i in range(l2+l3):
        for j in range(i+1,l2+l3):
            r=(D[:,i]==D[:,j]).mean(); z=(r-1/b)/math.sqrt((1/b)*(1-1/b)/N)
            rows.append((z,r*b,names[i],names[j]))
    rows.sort()
    zs=np.array([r[0] for r in rows])
    print(f"b{b} L{L} N={N} pairs={len(rows)}  |z|>4: {(abs(zs)>4).sum()}  |z|>6: {(abs(zs)>6).sum()}")
    big=[r for r in rows if abs(r[0])>4]
    print("   ", ' '.join(f"{a}-{c}:{rb:.3f}({z:+.0f})" for z,rb,a,c in sorted(big,key=lambda r:-abs(r[0]))[:24]))
    np.save(f'data/b{b}_sampleD.npy',D)

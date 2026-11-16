# Mutual information between pairs of output digits (sample), interior vs null.
# Null for independent digits: E[MI] ~ (b-1)^2/(2N) nats.
import numpy as np, sys, json, math
for b in [int(x) for x in sys.argv[1].split(',')]:
    s=json.load(open(f'data/b{b}_stats.json')); l2=s['l2']; l3=s['l3']; k=s['k']; t=s['t']
    D=np.load(f'data/b{b}_sampleD.npy').astype(np.int64); N=len(D)
    # interior: n^2 positions k+2 .. l2-t-3 ; n^3 positions k+2 .. l3-t-3 (cert ~ t digits each, 2-digit buffers)
    S=list(range(k+2,l2-t-2)); C=[l2+j for j in range(k+2,l3-t-2)]
    nm=lambda q: f"S{q}" if q<l2 else f"C{q-l2}"
    null=(b-1)**2/(2*N)
    res=[]
    idx=S+C
    for a in range(len(idx)):
        for c in range(a+1,len(idx)):
            i,j=idx[a],idx[c]
            h=np.bincount(D[:,i]*b+D[:,j],minlength=b*b).reshape(b,b)/N
            pi=h.sum(1); pj=h.sum(0); m=h>0
            mi=(h[m]*np.log(h[m]/np.outer(pi,pj)[m])).sum()
            res.append((mi/null,nm(i),nm(j)))
    res.sort(reverse=True)
    r=np.array([x[0] for x in res])
    print(f"b{b} N={N} interior S{S[0] if S else '-'}..S{S[-1] if S else '-'} C{C[0]-l2}..C{C[-1]-l2}: pairs {len(res)}  MI/null mean {r.mean():.3f} (indep ~1, sd ~{math.sqrt(2/((b-1)**2)):.3f})  max {res[0][0]:.3f} {res[0][1]}-{res[0][2]}")

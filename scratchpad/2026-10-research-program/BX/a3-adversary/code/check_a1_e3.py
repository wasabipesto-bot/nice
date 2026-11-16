# Independent exhaustive check of A1 E3's tail proxy: P(niceness >= b-j) in ramified slices p^j | n vs whole range.
import numpy as np, sys, json, math
sys.path.insert(0,'code'); from load import load
for b,ps in [(28,[7,2]),(33,[11,3]),(30,[5,3,2]),(32,[2])]:
    s,smp,pos=load(b); T=s['total']; rs,re=s['range']
    for p in ps:
        for j in [1,2,3]:
            m=p**j
            Nsl=(re-1)//m-(rs-1)//m
            out=[]
            for sl in [2,3,4]:
                if sl>s['slack']: continue
                allc=sum(s['hist_nice'][b-i] for i in range(sl+1))
                slc=(pos['nice']>=b-sl)&(pos['n'].astype(np.int64)%m==0)
                k=int(slc.sum()); ratio=(k/Nsl)/(allc/T)
                out.append(f">=b-{sl}: {k} ratio {ratio:.2f}±{ratio/math.sqrt(max(k,1)):.2f}")
            print(f"b{b} slice {p}^{j} | n (N={Nsl}): "+' | '.join(out))

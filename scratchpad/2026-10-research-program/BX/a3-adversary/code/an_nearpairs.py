# Where do near-nice numbers collide?  For n with niceness b-2 or b-3 (few collisions), compare the
# positions of their colliding pairs with the odds-weighted expectation from all-n pair rates (sample).
import numpy as np, sys, json, math
sys.path.insert(0,'code'); from load import load
def digs(x,b,l2,l3):
    a=x*x; c=a*x; out=[]
    for i in range(l2): out.append(a%b); a//=b
    for j in range(l3): out.append(c%b); c//=b
    return out
tot_obs={}; tot_exp={}
for b in [int(x) for x in sys.argv[1].split(',')]:
    s,smp,pos=load(b); l2=s['l2']; l3=s['l3']; P=l2+l3
    import os
    D=np.load(f'data/b{b}_sampleD.npy').astype(np.int64) if os.path.exists(f'data/b{b}_sampleD.npy') else None
    if D is None:
        idx=np.random.default_rng(1).choice(len(smp),300000,replace=False)
        D=np.array([digs(int(x),b,l2,l3) for x in smp['n'][idx]])
    r=np.zeros((P,P))
    for i in range(P):
        for j in range(i+1,P): r[i,j]=(D[:,i]==D[:,j]).mean()
    odds=r/(1-r+1e-12)
    def cls(i,j):
        a='S' if i<l2 else 'C'; c='S' if j<l2 else 'C'
        ii=i if i<l2 else i-l2; jj=j if j<l2 else j-l2
        # region of each position: low (< k+2), top (within t+2 of top), mid
        def reg(p,ln): return 'lo' if p< s['k']+2 else ('hi' if p>=ln-s['t']-2 else 'mid')
        ra=reg(ii,l2 if a=='S' else l3); rc=reg(jj,l2 if c=='S' else l3)
        return a+c+':'+'-'.join(sorted([ra,rc]))
    sel=pos[(pos['nice']>=b-3)]
    obs={}; exp={}
    for x in sel['n']:
        d=digs(int(x),b,l2,l3)
        pairs=[(i,j) for i in range(P) for j in range(i+1,P) if d[i]==d[j]]
        for (i,j) in pairs: obs[cls(i,j)]=obs.get(cls(i,j),0)+1
        # expected: same number of pairs distributed by odds (marginal approximation)
    npairs=sum(obs.values())
    W=sum(odds[i,j] for i in range(P) for j in range(i+1,P))
    for i in range(P):
        for j in range(i+1,P):
            exp[cls(i,j)]=exp.get(cls(i,j),0)+npairs*odds[i,j]/W
    keys=sorted(set(obs)|set(exp))
    chi=sum((obs.get(k_,0)-exp[k_])**2/exp[k_] for k_ in keys if exp.get(k_,0)>=5)
    print(f"b{b} n={len(sel)} pairs={npairs} chi2={chi:.1f} dof~{sum(exp.get(k_,0)>=5 for k_ in keys)-1}  "+' '.join(f"{k_}:{obs.get(k_,0)}/{exp.get(k_,0):.0f}" for k_ in keys if exp.get(k_,0)>=20))
    for k_ in keys: tot_obs[k_]=tot_obs.get(k_,0)+obs.get(k_,0); tot_exp[k_]=tot_exp.get(k_,0)+exp.get(k_,0)
print("pooled obs/exp:",' '.join(f"{k_}:{tot_obs[k_]/tot_exp[k_]:.3f}(z{(tot_obs[k_]-tot_exp[k_])/math.sqrt(tot_exp[k_]):+.1f})" for k_ in sorted(tot_exp) if tot_exp[k_]>=20))

# Feature lift: positives (top niceness class) vs population sample, for residues and digit features.
import numpy as np, json, sys, math
sys.path.insert(0,'code'); from load import load, digits
from math import gcd
from scipy.stats import chi2 as CHI2
BASES=[int(x) for x in sys.argv[1].split(',')]
MODE=sys.argv[2]  # 'all' or 'eclean'
TARGET=float(sys.argv[3]) if len(sys.argv)>3 else 1e-3
res_rows=[]; feat_rows={}
for b in BASES:
    s,smp,pos=load(b); L=s['L']; T=s['total']
    H=np.array(s['hist_nice']); 
    if MODE=='eclean':
        ref=smp[smp['eclean']==1]; P=pos[pos['eclean']==1]
        Hc=np.array(s['hist_e_mid']).sum(0); base_tot=Hc.sum(); Hh=Hc
    else:
        ref=smp; P=pos; base_tot=T; Hh=H
    # choose threshold level: largest j such that frac(nice>=b-j) <= TARGET*3 and count >= 30
    best=None
    for j in range(0,s['slack']+1):
        c=Hh[b-j:b+1].sum()
        if c>=30: best=j; 
        if c/base_tot>=TARGET: break
    j=best; thr=b-j
    Pc=P[P['nice']>=thr]
    print(f"# b{b} L{L} mode={MODE} class nice>={thr} (slack {j}) n_pos={len(Pc)} frac={len(Pc)/base_tot:.2e} ref={len(ref)}",flush=True)
    npos=Pc['n'].astype(np.int64); nref=ref['n'].astype(np.int64)
    # residues mod m coprime to b: positives vs uniform (contiguous range => uniform) ; for eclean mode use ref sample instead
    for m in range(2,301):
        if gcd(m,b)!=1: continue
        cp=np.bincount(npos%m,minlength=m).astype(float)
        # contiguous full range and m coprime to b: n mod m is (to O(m/N)) uniform and independent
        # of the suffix/prefix views, in both modes; the sample would only add its own noise
        ex=np.full(m,len(npos)/m)
        ok=ex>0
        st=((cp[ok]-ex[ok])**2/ex[ok]).sum(); dof=ok.sum()-1
        p=CHI2.sf(st,dof)
        res_rows.append((b,m,st/dof,p,(m==b-1) or (m==b+1) or ((b*b-1)%m==0)))
    # digit features
    dp=digits(npos,b,L); dr=digits(nref,b,L)
    def feats(d,n):
        srt=np.sort(d,axis=1)
        ndist=1+(np.diff(srt,axis=1)!=0).sum(1)
        x=n/ (b**(L-1))
        return {
         'n_digits_distinct': (ndist==L).astype(int),
         'n_ndistinct': ndist,
         'n_digitsum_mod_b+1': d.sum(1)%(b+1),
         'n_has_zero': (d==0).any(1).astype(int),
         'n_maxdigit_top_half': (d.max(1)>=b//2).astype(int),
         'n_mindigit_0or1': (d.min(1)<=1).astype(int),
         'x_decile': np.minimum((10*(x-x.min()*0)/ (s['range'][1]/b**(L-1))).astype(int),9),
         'n_digitsum_hi': (d.sum(1)>L*(b-1)/2).astype(int),
         'n_alt_sum_mod_b+1': (n%(b+1)),
         'n_sum_digits_sq_parity': ((d*d).sum(1)%2),
         'n_lead': d[:,L-1],
        }
    fp=feats(dp,npos); fr=feats(dr,nref)
    # weight reference by the uniform-middle model probability of reaching the class given e
    sys.path.insert(0,'code'); from an_middle_model import model
    if MODE=='eclean':
        pe={e:sum(model(b,e)[sidx] for sidx in range(len(model(b,e))) if e+sidx>=thr) for e in np.unique(ref['e'])}
        w=np.array([pe[e] for e in ref['e']])
    else:
        w=np.ones(len(ref))
    for name in fp:
        a=fp[name]; r=fr[name]
        vals=np.unique(np.concatenate([a,r]))
        if len(vals)>60: continue
        rows=[]
        for v in vals:
            pp=(a==v).mean(); pr=w[r==v].sum()/w.sum()
            if pr*len(a)<5: continue
            k=(a==v).sum(); se=math.sqrt(max(k,1))/len(a)
            z=(pp-pr)/math.sqrt(pr*(1-pr)/len(a)+pr*(1-pr)/len(r))
            rows.append((v,pp/pr,z))
        feat_rows.setdefault(name,[]).append((b,rows))
# summarise residues
import collections
print("\n## residues mod m (gcd(m,b)=1): smallest p-values")
res_rows.sort(key=lambda r:r[3])
ntests=len(res_rows)
for r in res_rows[:25]:
    print(f"b{r[0]} m{r[1]} chi2/dof {r[2]:.2f} p {r[3]:.2e} bonf {min(1,r[3]*ntests):.2e} {'(b-1/b+1/b^2-1 family)' if r[4] else ''}")
ps=np.array([r[3] for r in res_rows])
print(f"tests {ntests}; frac p<0.01 {np.mean(ps<0.01):.4f} (null 0.01); frac p<0.001 {np.mean(ps<0.001):.4f}")
fam=[r for r in res_rows if r[4]]
print("b±1 family p-values:", ' '.join(f"b{r[0]}m{r[1]}:{r[3]:.1e}" for r in sorted(fam)))
print("\n## digit / position features: per base, max |z| bin and its lift")
for name,lst in feat_rows.items():
    out=[]
    for b,rows in lst:
        if not rows: continue
        v,l,z=max(rows,key=lambda t:abs(t[2]))
        out.append(f"b{b}:{v}:{l:.2f}({z:+.1f})")
    print(name.ljust(26),' '.join(out))

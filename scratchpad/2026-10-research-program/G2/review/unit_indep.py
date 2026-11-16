"""Independent from-scratch enumeration of one transversal unit {n in base range: digits 4..9 of n = U}
for shape (f0 4, k 10): tops and bottoms from the definition (Python big ints, numpy for the pairing).
Compares the survivor set with the prototype's dump and reports counts."""
import sys, time, numpy as np
sys.path.insert(0, '.')
from qstar import rng, classes, digits
b=int(sys.argv[1]); U=int(sys.argv[2]); dump=sys.argv[3]
f0,k=4,10
lo,hi=rng(b); cls=classes(b); m=b-1
B4,B10=b**4,b**10
t0=time.time()
# ---- tops
tops=[]; tested=0
for lead in range(lo//B10, (hi-1)//B10+1):
    p0=lead*B10+U*B4
    a=max(p0,lo); c=min(p0+B4-1,hi-1)
    if a>c: continue
    tested+=1
    seen=0; ok=True
    for e in (2,3):
        A=a**e; C=c**e
        if len(digits(A,b))!=len(digits(C,b)): continue
        dA=digits(A,b)
        for j in range(len(dA)-1,k-1,-1):
            if A//b**j!=C//b**j: break
            bit=1<<dA[j]
            if seen&bit: ok=False;break
            seen|=bit
        if not ok: break
    if ok: tops.append((lead,a,c,seen))
t1=time.time()
# ---- bottoms: r = U*b^4 + x, digits 0..9 of r^2, r^3 distinct
bm=[];br=[]
base_r=U*B4
for x in range(B4):
    r=base_r+x
    s=(r*r)%B10; q=(s*r)%B10
    seen=0; ok=True
    for v in (s,q):
        for _ in range(k):
            v,d=divmod(v,b); bit=1<<d
            if seen&bit: ok=False;break
            seen|=bit
        if not ok: break
    if ok: bm.append(seen); br.append(r)
t2=time.time()
bm=np.array(bm,dtype=np.uint64); br_np=np.array(br,dtype=object)
bcls=np.array([r%m for r in br],dtype=np.int64)
pairs=0; surv=set()
L0=lo//B10; L1=(hi-1)//B10+1; NB=10
dec_p=[0]*NB; dec_s=[0]*NB; dec_t=[0]*NB; dec_n=[0]*NB
for lead in range(L0,L1): dec_n[min(NB-1,(lead-L0)*NB//(L1-L0))]+=1
for lead,a,c,tm in tops:
    di=min(NB-1,(lead-L0)*NB//(L1-L0)); dec_t[di]+=1
    want=np.array([(x-lead)%m for x in cls])
    sel=np.isin(bcls,want)
    pairs+=int(sel.sum()); dec_p[di]+=int(sel.sum())
    hit=np.nonzero(sel & ((bm & np.uint64(tm))==0))[0]
    for i in hit:
        n=lead*B10+br[i]
        if a<=n<=c: surv.add(n); dec_s[di]+=1
t3=time.time()
got=set(int(x) for x in open(dump).read().split())
adm=((hi-1)//B10-lo//B10+1)*B4*len(cls)/m
print(f"b{b} unit U={U}: tops {len(tops)}/{tested} bottoms {len(bm)} pairs {pairs} survivors {len(surv)} | per adm: pairs {pairs/adm:.3e} surv {len(surv)/adm:.3e} bottoms {len(bm)/adm:.3e}")
print(f"  prototype survivors {len(got)}; equal={got==surv} missing_in_proto {len(surv-got)} extra_in_proto {len(got-surv)}; times tops {t1-t0:.0f}s bots {t2-t1:.0f}s pair {t3-t2:.0f}s")

print("  deciles of the leading range (per adm of the decile, relative to the unit mean): tops / pairs / survivors")
mp=pairs/sum(dec_n); ms=len(surv)/sum(dec_n); mt=len(tops)/sum(dec_n)
for i in range(NB):
    print(f"   d{i}: leads {dec_n[i]:6d} tops {dec_t[i]/dec_n[i]/mt:5.2f} pairs {dec_p[i]/dec_n[i]/mp:5.2f} surv {dec_s[i]/dec_n[i]/ms:5.2f}")

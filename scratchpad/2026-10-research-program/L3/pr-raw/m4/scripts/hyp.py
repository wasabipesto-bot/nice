import re
import os; os.chdir(os.path.dirname(os.path.abspath(__file__)) + "/..")
M32=(1<<32)-1
def digits(x,b,L):
    d=[]
    for _ in range(L): d.append(x%b); x//=b
    return d
def uniq(S,C,b,ls,lc):
    return len(set(digits(S,b,ls))|set(digits(C,b,lc)))
obs={}
for l in open("diag3.log"):
    m=re.match(r"WRONG b(\d+) n=(\d+) cpu=\[\((\d+), 1\)\] fd=\[\((\d+), 1\)\]",l)
    if m:
        b,n,c,f=map(int,m.groups()); obs[(b,n)]=(c,f)
P={23:(795831,3000,9,14),50:(26507984537059635,400,20,30)}
def check(name,fn):
    res={}
    for b,(s,cnt,ls,lc) in P.items():
        ok=0
        for n in range(s,s+cnt):
            S,C=fn(n,b)
            want=obs.get((b,n),(None,None))[1]
            true=uniq(n*n,n**3,b,ls,lc)
            if want is None: want=true
            ok+= (uniq(S,C,b,ls,lc)==want)
        res[b]=f"{ok}/{cnt}"
    print(f"{name:40s}",res)
check("correct", lambda n,b:(n*n,n**3))
# limb helpers
def limbs(x,k): return [(x>>(32*i))&M32 for i in range(k)]
def join(l): return sum(v<<(32*i) for i,v in enumerate(l))
def hi_as_lo_S(n,b):
    s=n*n; L=limbs(s,3); L[1]=L[0]; return join(L)
check("S hi limb := lo limb", lambda n,b:(hi_as_lo_S(n,b),n**3))
check("S hi limb := 0", lambda n,b:(n*n & M32,n**3))
check("C limb1 := limb0", lambda n,b:(n*n, join([limbs(n**3,3)[0],limbs(n**3,3)[0],limbs(n**3,3)[2]])))
check("C limb2 := 0", lambda n,b:(n*n, n**3 & ((1<<64)-1)))
check("C limb2 := limb1", lambda n,b:(n*n, join([limbs(n**3,3)[0],limbs(n**3,3)[1],limbs(n**3,3)[1]])))
check("C limb2 := limb0", lambda n,b:(n*n, join([limbs(n**3,3)[0],limbs(n**3,3)[1],limbs(n**3,3)[0]])))
for k in (1,2,3):
    check(f"n off by +{k}", lambda n,b,k=k:((n+k)**2,(n+k)**3))
    check(f"n off by -{k}", lambda n,b,k=k:((n-k)**2,(n-k)**3))
check("S correct, C from n+1", lambda n,b:(n*n,(n+1)**3))
check("C correct, S from n+1", lambda n,b:((n+1)**2,n**3))

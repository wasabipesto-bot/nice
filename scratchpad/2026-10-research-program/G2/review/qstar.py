"""Independent predicate Q*(n) for shape (f0, k): written from the definition, not from the prototype.
Certified positions: of n^2 and n^3, positions j >= k where floor(x^e / b^j) is the same at both ends of
n's f0-top interval (clipped to the base range), plus positions 0..k-1. Q*(n): n mod (b-1) in the
admissible classes, and the digits of n^2, n^3 at the certified positions are pairwise distinct.
Niceness implies Q* (a subset of all digits is distinct; digit sum condition gives the classes)."""
import sys
def rng(b):
    k=b//5
    def icbrt_ceil(v):
        x=int(round(v**(1/3)))
        while x**3<v:x+=1
        while x>0 and (x-1)**3>=v:x-=1
        return x
    def isqrt_ceil(v):
        import math
        x=math.isqrt(v)
        return x if x*x==v else x+1
    m=b%5
    if m==0: return icbrt_ceil(b**(3*k-1)), b**k
    if m==2: return b**k, icbrt_ceil(b**(3*k+1))
    if m==3: return icbrt_ceil(b**(3*k+1)), isqrt_ceil(b**(2*k+1))
    if m==4: return isqrt_ceil(b**(2*k+1)), icbrt_ceil(b**(3*k+2))
def classes(b):
    # n nice => digit sum of n^2 and n^3 = b(b-1)/2, and digit sum == value mod (b-1)
    m=b-1; return {r for r in range(m) if (r**2+r**3-b*(b-1)//2)%m==0}
def digits(x,b):
    d=[]
    while x: x,r=divmod(x,b); d.append(r)
    return d
def qstar(n,b,f0,k,lo,hi,cls,cache):
    if n%(b-1) not in cls: return False
    p=n//b**f0
    if p not in cache:
        a=max(p*b**f0,lo); c=min(p*b**f0+b**f0-1,hi-1)
        pos=[]
        for e in (2,3):
            A=a**e; C=c**e; j=k; P=[]
            # constant positions j>=k: floor(A/b^j)==floor(C/b^j)
            L=len(digits(C,b))
            for j in range(k, L):
                if A//b**j==C//b**j: P.append(j)
            pos.append(P)
        cache.clear(); cache[p]=pos
    pos=cache[p]
    seen=0
    for e,P in zip((2,3),pos):
        d=digits(n**e,b)
        for j in list(range(k))+P:
            dj=d[j] if j<len(d) else 0
            bit=1<<dj
            if seen&bit: return False
            seen|=bit
    return True
def _main():
    b,f0,k=map(int,sys.argv[1:4]); dump=sys.argv[4]
    lo,hi=rng(b); cls=classes(b)
    cache={}
    want=[n for n in range(lo,hi) if qstar(n,b,f0,k,lo,hi,cls,cache)]
    nice=[n for n in want if len(set(digits(n*n,b)+digits(n**3,b)))==b and len(digits(n*n,b)+digits(n**3,b))==b]
    got=[int(x) for x in open(dump).read().split()]
    print(f"b{b} (f0 {f0}, k {k}) range [{lo},{hi}) classes {sorted(cls)}: Q* {len(want)} prototype {len(got)} equal={set(want)==set(got)} "
          f"missing_in_proto {len(set(want)-set(got))} extra_in_proto {len(set(got)-set(want))} nice {nice}")
    
if __name__=='__main__': _main()
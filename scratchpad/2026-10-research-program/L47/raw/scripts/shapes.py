#!/usr/bin/env python3
"""Shapes (b, L, f0, k2, s2, s3) of every field the check sees: production bands b40-64, the test windows."""
def nd(x,b):
    n=0
    while x>0: x//=b; n+=1
    return n
def band(b):
    def f(n): return nd(n*n,b)+nd(n**3,b)
    lo,hi=1,b**20
    # minimal n with f(n) >= b
    a,z=1,b**20
    while a<z:
        m=(a+z)//2
        if f(m)>=b: z=m
        else: a=m+1
    s=a
    a,z=s,b**20
    while a<z:
        m=(a+z)//2
        if f(m)>=b+1: z=m
        else: a=m+1
    return s,a  # [s, e)
def shape(b,s,e,t,k,p):
    L=nd(e-1,b); assert nd(s,b)==L
    s2=nd(s*s,b); s3=nd(s**3,b)
    assert nd((e-1)**2,b)==s2 and nd((e-1)**3,b)==s3, (b,s,e)
    f0=L-t
    mid=2
    while mid>0 and (k+mid>s2 or b**(k+mid-f0)>=2**32 or k+mid>12): mid-=1
    k2=k+mid
    Hmax=(e-1)//b**k2
    return dict(b=b,L=L,f0=f0,k2=k2,s2=s2,s3=s3,Hbits=Hmax.bit_length(),nbits=(e-1).bit_length())
WINDOWS=[(20,58945,160000,3,2,0),(20,58945,160000,2,3,1),(20,60001,150003,2,3,1),(25,3339797,4339797,4,3,1),
(25,5000123,5700456,3,4,2),(30,300000000,301000000,5,4,2),(34,12000000017,12001000017,5,5,2),(40,3000000000000,3000002000000,6,5,2),
(40,3000000000000,3000002000000,7,4,2),(50,62082117268529817,62082117268829817,7,4,1),(54,2321864499473908801,2321864499474208801,8,4,1),
(57,30000000000000000000,30000000000000300000,10,4,1),(57,20635899893042801193,20635899893043101193,9,5,1),
(57,78920310198429586458,78920310198429886458,9,5,2),(58,114041927169846138720,114041927169846438720,10,4,2),
(60,1573714731429953349518,1573714731429953649518,10,4,2),(64,52125117810081128433988,52125117810081128733988,11,4,2),
(10,47,100,2,1,0)]
if __name__=='__main__':
    print("windows:")
    for w in WINDOWS:
        b,s,e,t,k,p=w
        try: print(w[0],w[3:],shape(*w))
        except AssertionError as x: print(w,'ASSERT',x)
    print("production bands (t=L-3,k=6,p=2):")
    for b in range(40,65):
        s,e=band(b)
        # split band by L
        Ls=sorted(set([nd(s,b),nd(e-1,b)]))
        for L in Ls:
            ss=max(s,b**(L-1)); ee=min(e,b**L)
            if ss>=ee: continue
            # s2/s3 may change within band; split at their boundaries
            pts=[ss,ee]
            for j in range(1,60):
                for pw,dd in ((2,2),(3,3)):
                    pass
            # find sub-bands of constant (s2,s3)
            import math
            cuts=set([ss,ee])
            for m in range(1,3*L+3):
                # n^2 >= b^m  -> n >= ceil(b^(m/2)); n^3 >= b^m
                for q in (2,3):
                    r=int(round((b**m)**(1.0/q)))
                    for c in range(max(r-3,1),r+4):
                        if c**q>=b**m and (c-1)**q<b**m and ss<c<ee: cuts.add(c)
            cuts=sorted(cuts)
            for a,z in zip(cuts,cuts[1:]):
                if L<7: continue
                try:
                    sh=shape(b,a,z,L-3,6,2)
                    if sh['s2']+sh['s3']==b: print(b,(a,z),sh)
                except AssertionError as x: print(b,'ASSERT',a,z,x)

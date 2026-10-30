def iroot_ceil(x, k):
    lo, hi = 0, 1
    while hi**k < x: hi *= 2
    while lo < hi:
        m = (lo+hi)//2
        if m**k >= x: hi = m
        else: lo = m+1
    return lo
def ndig(x,b):
    c=0
    while x: x//=b; c+=1
    return c
def plan(b):
    for ls in range(1,b):
        lc=b-ls
        lo=max(iroot_ceil(b**(ls-1),2), iroot_ceil(b**(lc-1),3))
        hi=min(iroot_ceil(b**ls,2), iroot_ceil(b**lc,3))
        if lo<hi: return ls,lc,lo,hi
    return None
def chunk16(b):
    e=0;d=1
    while d*b < 1<<16: d*=b; e+=1
    return e,d
import math
for b in range(10,65):
    p=plan(b)
    if not p: continue
    ls,lc,lo,hi=p
    nmax=hi-1
    limbs=max(1,math.ceil(nmax.bit_length()/32))
    lds=ndig(2*hi+1,b); ldc=ndig(3*hi*hi+3*hi+1,b); lddc=ndig(6*hi+6,b)
    e,d=chunk16(b)
    ws=-(-ls//4); wc=-(-lc//4); wds=-(-lds//4); wdc=-(-ldc//4); wddc=-(-lddc//4)
    ks=min(-(-(lds+1)//4),ws); kc=min(-(-(ldc+1)//4),wc)
    print(f"b{b}: limbs={limbs} e={e} div={d} ls={ls} lc={lc} lds={lds} ldc={ldc} lddc={lddc} ws={ws} wc={wc} wds={wds} wdc={wdc} wddc={wddc} ks={ks} kc={kc} nch_s={-(-ls//e)} nch_c={-(-lc//e)} sqbits={(nmax*nmax).bit_length()} cubits={(nmax**3).bit_length()} nbits={nmax.bit_length()} lo={lo}")

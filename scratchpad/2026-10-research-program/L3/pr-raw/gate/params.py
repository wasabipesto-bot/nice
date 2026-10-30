# Per-base FD kernel parameters (wgpu split16 path), to look for what separates
# the M4's failing bases {23,27,28,29,30,49,50,52,53,54,55} from the rest.
def iroot(x, k):  # ceiling k-th root
    lo, hi = 0, 1
    while hi**k < x: hi *= 2
    while lo < hi:
        m = (lo+hi)//2
        if m**k >= x: hi = m
        else: lo = m+1
    return lo
def rng(b):
    k = b//5; r = b % 5
    if r == 0: return iroot(b**(3*k-1),3), b**k
    if r == 1: return None
    if r == 2: return b**k, iroot(b**(3*k+1),3)
    if r == 3: return iroot(b**(3*k+1),3), iroot(b**(2*k+1),2)
    if r == 4: return iroot(b**(2*k+1),2), iroot(b**(3*k+2),3)
def nd(x,b):
    c=0
    while x: x//=b; c+=1
    return c
def chunk16(b):
    e=0; p=1
    while p*b < (1<<16): p*=b; e+=1
    return e,p
FAIL={23,27,28,29,30,49,50,52,53,54,55}
if __name__ == "__main__":
    print("b  fail limbs bits(n_hi) ls lc lds ldc lddc  e  div    ws wc wds wdc wddc ks kc  sqL cuL  nch(S,C,dS,dC,ddC)  bias   ")
    for b in range(10,65):
        R=rng(b)
        if not R: continue
        lo,hi=R
        nmax=hi-1
        limbs=max(1,-(-nmax.bit_length()//32))
        ls=nd(lo*lo,b); lc=nd(lo**3,b)
        lds=nd(2*hi+1,b); ldc=nd(3*hi*hi+3*hi+1,b); lddc=nd(6*hi+6,b)
        e,div=chunk16(b)
        ws,wc,wds,wdc,wddc=[-(-x//4) for x in (ls,lc,lds,ldc,lddc)]
        ks=min(-(-(lds+1)//4),ws); kc=min(-(-(ldc+1)//4),wc)
        nch=tuple(-(-x//e) for x in (ls,lc,lds,ldc,lddc))
        print(f"{b:2d} {'FAIL' if b in FAIL else '    '} {limbs:4d} {nmax.bit_length():4d}     {ls:2d} {lc:2d} {lds:3d} {ldc:3d} {lddc:3d}  {e:2d} {div:6d} {ws:2d} {wc:2d} {wds:3d} {wdc:3d} {wddc:3d} {ks:2d} {kc:2d} {2*limbs:3d} {3*limbs:3d}  {str(nch):20s} {256-b}")

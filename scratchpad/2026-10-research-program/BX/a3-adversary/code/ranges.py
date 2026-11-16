def iroot(x,k):
    lo,hi=0,1
    while hi**k<=x: hi*=2
    while lo<hi:
        m=(lo+hi)//2
        if m**k<x: lo=m+1
        else: hi=m
    return lo  # ceiling root
def rng(b):
    k=b//5; r=b%5
    if r==0: return iroot(b**(3*k-1),3), b**k
    if r==1: return None
    if r==2: return b**k, iroot(b**(3*k+1),3)
    if r==3: return iroot(b**(3*k+1),3), iroot(b**(2*k+1),2)
    if r==4: return iroot(b**(2*k+1),2), iroot(b**(3*k+2),3)
if __name__=="__main__":
    for b in range(10,46):
        r=rng(b)
        if r: print(b, r[0], r[1], r[1]-r[0], "%.2e"%(r[1]-r[0]), len(str(r[0])))

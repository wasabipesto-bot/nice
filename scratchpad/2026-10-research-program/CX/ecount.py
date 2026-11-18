# Heuristic expected number of nice numbers per base: (#n in the base's range) * b!/b^b.
# The residue filter redistributes candidates among classes but leaves the total expectation unchanged
# (roots exist => density in root classes is (b-1)/R higher); a base with no roots or no range has none.
from math import lgamma, log, exp, log10
def rng_log10(b):
    r=b%5
    if r==1: return None
    L=-(-b//5)  # ceil
    lb=log10(b)
    # intervals of exponent e with n=b^e: digits(n^2)+digits(n^3)=b
    iv={0:(L-1/3,L),4:(L-1/2,L-1/3),3:(L-2/3,L-1/2),2:(L-1,L-2/3)}[r]
    lo,hi=iv
    return log10(b**0)+hi*lb+log10(1-10**((lo-hi)*lb))
def roots(b):
    m=b-1; t=(b*(b-1)//2)%m
    return sum(1 for n in range(m) if (n*n*(n+1))%m==t)
cum=0; rows=[]
for b in range(11,201):
    rl=rng_log10(b); R=roots(b)
    if rl is None or R==0: continue
    lp=(lgamma(b+1)-b*log(b))/log(10)
    E=10**(rl+lp); cum+=E; rows.append((b,R,rl,E,cum))
for b,R,rl,E,cum in rows:
    if b in (40,50,58,60,62,64,65,68,69,70,80,90,100,110,115,120,124,125,128,129,130,132,134,135,138,139,140,144,145,150,160,180,200) :
        print(f"b{b:4d} R={R:3d} log10(#n)={rl:6.2f}  E={E:9.3g}  cum(11..b)={cum:9.3g}")
print('valid bases 11..200:',len(rows))
print('cum 61..66: %.3g'%sum(r[3] for r in rows if 61<=r[0]<=66), ' cum 11..60: %.3g'%sum(r[3] for r in rows if r[0]<=60))

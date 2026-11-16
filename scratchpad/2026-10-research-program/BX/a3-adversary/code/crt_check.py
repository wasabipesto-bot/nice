# Is digit j of n^2 (base b = p*q) mod p a function of n mod p^(j+1)?  (CRT / p-adic decoupling)
# Test: for random n, n' with n == n' mod p^M (M = j+1 .. j+6), compare digit_j(n^2) mod p.
import random
def dig(x,b,j): return (x//b**j)%b
random.seed(1)
for b,p in [(30,2),(30,3),(30,5),(62,2),(62,31),(12,2),(12,3)]:
    for j in [1,2,4]:
        out=[]
        for extra in [0,2,6,12]:
            M=j+1+extra; agree=0; T=4000
            for _ in range(T):
                n=random.randrange(b**8,b**9); n2=n+p**M*random.randrange(1,b**4)
                agree+= dig(n*n,b,j)%p==dig(n2*n2,b,j)%p
            out.append(f"M={M}:{agree/T:.3f}")
        print(f"b{b} p{p} digit {j}: P(agree) {' '.join(out)}  (chance {1/p:.3f})")

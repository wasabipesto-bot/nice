"""Which f(x) for the faulty quotient reproduces the M4's moved counts where
H1 (f(x) = x // K) does not?  x = the top limb of n^2 (x >= 2^16 there)."""
import sys
import sweep_model as sm
from b52probe import make
from magic import magic16
from seed_model import chunk16
M32 = (1 << 32) - 1
TARGET = {  # base: [(start, M4 moved)]
    27: [(14348907, 23347), (28697814, 7852)],
    28: [(52260814, 1910), (71664761, 0)],
    29: [(110455918, 6512), (152031667, 11246)],
    52: [(144555105949057024, 0), (342054325839405870, 4292)],
}
def F(name, K):
    M, s = magic16(K)
    return {
        'x//K': lambda x: x // K,
        'x*M>>s (exact 64-bit)': lambda x: (x * M) >> s,
        '(x*M mod 2^32)>>s': lambda x: ((x * M) & M32) >> s,
        'mulhi(x,M<<(32-s))': lambda x: (x * ((M << (32 - s)) & M32)) >> 32 if s <= 32 else None,
        '(x mod 2^16)//K': lambda x: (x & 0xFFFF) // K,
        '((x*M)>>s) mod 2^16': lambda x: ((x * M) >> s) & 0xFFFF,
        '(x*M mod 2^32)>>s mod 2^16': lambda x: (((x * M) & M32) >> s) & 0xFFFF,
    }[name]
names = ['x//K', 'x*M>>s (exact 64-bit)', '(x*M mod 2^32)>>s', '(x mod 2^16)//K', '((x*M)>>s) mod 2^16', '(x*M mod 2^32)>>s mod 2^16']
bases = [int(a) for a in sys.argv[1:]] or list(TARGET)
for b in bases:
    e, K = chunk16(b)
    print(f"b{b} K={K} magic16={magic16(K)}", flush=True)
    for name in names:
        f = F(name, K)
        sm.digits_fault = make(lambda x, K, f=f: f(x))
        got = [sm.window(b, s, 100000)[1] for s, _ in TARGET[b]]
        want = [m for _, m in TARGET[b]]
        print(f"   {name:28s} moved {got} want {want} {'MATCH' if got == want else ''}", flush=True)

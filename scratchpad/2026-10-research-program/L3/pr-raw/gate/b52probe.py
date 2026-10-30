import sweep_model as sm
from seed_model import chunk16, M32
def make(fn):
    def digits_fault(v, ndig, b, fault):
        v = list(v); n = len(v); e, K = chunk16(b); out = []
        for k in range(-(-ndig // e)):
            rem = 0
            for ii in range(n):
                i = n - 1 - ii; x = v[i]
                c1 = ((rem << 16) | (x >> 16)) & M32
                q1 = c1 // K
                if fault and k == 0 and ii == 0 and (K & (K - 1)):  # a power-of-two K is a shift, not a division
                    q1 = fn(x, K) & M32
                r1 = (c1 - q1 * K) & M32
                c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
                q2 = c2 // K; rem = (c2 - q2 * K) & M32
                v[i] = ((q1 << 16) | q2) & M32
            chunk = rem
            for j in range(e):
                if k * e + j < ndig:
                    cq = chunk // b; out.append(chunk - cq * b); chunk = cq
        return out
    return digits_fault
if __name__ == '__main__':
  import sys
  b = 52
  lo, hi = sm.rng(b)
  for name, fn in [(f"x>>{j}//K", (lambda j: lambda x, K: (x >> j) // K)(j)) for j in range(0, 17, 1)]:
      sm.digits_fault = make(fn)
      r_mid = sm.window(b, 342054325839405870, 100000)
      r_st = sm.window(b, 144555105949057024, 20000)
      print(name, "mid (wrong, moved)", r_mid, "start(2e4)", r_st, flush=True)

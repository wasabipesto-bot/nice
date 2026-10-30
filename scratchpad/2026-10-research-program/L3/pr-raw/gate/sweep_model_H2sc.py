"""H2 on both n^2 and n^3: in the seed's conversion of n^2 to digits, the first quotient of the
top limb reads the low 16 bits of that limb instead of the high 16:
q1 = (x & 0xFFFF) / K for (x >> 16) / K (remainder minuend correct).
Simulate every M4 sweep window (production shape) and compare the moved
count with the M4's."""
import re
import sweep_model as sm
from b52probe import make
sm.digits_fault = make(lambda x, K: (x & 0xFFFF) // K)
W = []
for l in open("../m4/diag2.log"):
    m = re.search(r"SWEEP b(\d+) (start|mid) \[(\d+), \+(\d+)\): fd (exact|MISMATCH) \(>= (\d+) moved\)", l)
    if m: W.append((int(m[1]), m[2], int(m[3]), int(m[4]), m[5], int(m[6])))
same_verdict = same_moved = 0
for b, what, s, w, verdict, moved in W:
    wr, mv = sm.window(b, s, w, fault_s=True, fault_c=True)
    pred = "exact" if wr == 0 else "MISMATCH"
    same_verdict += pred == verdict; same_moved += mv == moved
    print(f"b{b} {what:5s} M4 {verdict:8s} moved {moved:5d} | H2 {pred:8s} moved {mv:5d} wrong-n {wr:6d} {'=' if mv == moved else '<-- differs'}", flush=True)
print(f"windows {len(W)}: same verdict {same_verdict}, same moved count {same_moved}")

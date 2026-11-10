import sys; sys.path.insert(0,'.')
import io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    from model import P
for b, R, dT in ((62, 2, 2.56), (64, 8, 1.62)):
    L = 13
    best = None
    for g in (1, 2, 3, 4):
        for k in (2, 4, 6):
            t = L - g - k
            if t < 3: continue
            cT = 2*t - dT
            calls = (b-1)/R * P(b, cT + 2*k) / b**g
            q = max(1 - (cT+2*k)/b, 0.05)
            outs = calls * max((b*q)**g * R/(b-1), 1.0)
            fs = (calls*100e-9 + outs*5e-9)*1e15
            if best is None or fs < best[0]: best = (fs, g, t, k, calls, outs)
    join_surv = P(b, 2*(L-3) - dT + 12)
    print(f"b={b}: best gap+lattice g={best[1]} t={best[2]} k={best[3]}: calls/n={best[4]:.1e} outputs/n={best[5]:.1e} "
          f"-> {best[0]:.0f} fs per admissible n; join survivors/n (f0 3,k 6) model {join_surv:.1e}")

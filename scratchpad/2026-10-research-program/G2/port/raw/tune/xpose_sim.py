"""xpose_sim.py: the shuffle transpose of g2_cubecl.rs simulated on the CPU for W = 8, 16, 32, 64: the u64 form
(9ff100e6) against the 32-bit-half form with rotations (c11), and both against the definition (lane l holds, in
block s, column s*W + l over the plane's rows). Random inputs. Tuning session 2026-11-18."""
import random
M64 = (1 << 64) - 1
def stage_mask(j): return sum(1 << b for b in range(64) if b & j)
def old(xs, W):
    x = list(xs)
    st = 0
    while (W >> (st + 1)) >= 1:
        j = W >> (st + 1); mj = stage_mask(j)
        y = [x[l ^ j] for l in range(W)]
        x = [((x[l] & mj) | ((y[l] >> j) & ~mj & M64)) if l & j else ((x[l] & ~mj & M64) | ((y[l] << j) & mj)) for l in range(W)]
        st += 1
    return x
def rotr(v, s): return ((v >> s) | (v << (32 - s))) & 0xFFFFFFFF
def new(xs, W):
    xl = [v & 0xFFFFFFFF for v in xs]; xh = [v >> 32 for v in xs]
    st = 0
    while (W >> (st + 1)) >= 1:
        j = W >> (st + 1)
        yl = [xl[l ^ j] for l in range(W)]; yh = [xh[l ^ j] for l in range(W)]
        nl, nh = [], []
        for l in range(W):
            hit = (l & j) != 0
            if j == 32:
                nl.append(yh[l] if hit else xl[l]); nh.append(xh[l] if hit else yl[l])
            else:
                mj = stage_mask(j) & 0xFFFFFFFF
                keep = mj if hit else (~mj & 0xFFFFFFFF)
                sr = j if hit else 32 - j
                nl.append((xl[l] & keep) | (rotr(yl[l], sr) & ~keep & 0xFFFFFFFF))
                nh.append((xh[l] & keep) | (rotr(yh[l], sr) & ~keep & 0xFFFFFFFF))
        xl, xh = nl, nh
        st += 1
    return [xl[l] | (xh[l] << 32) for l in range(W)]
def ref(xs, W):
    out = []
    for l in range(W):
        v = 0
        for s in range(64 // W):
            col = s * W + l
            for r in range(W):
                if (xs[r] >> col) & 1: v |= 1 << (s * W + r)
        out.append(v)
    return out
random.seed(1)
for W in (8, 16, 32, 64):
    for t in range(300):
        xs = [random.getrandbits(64) if random.random() < 0.9 else 0 for _ in range(W)]
        a, b, c = old(xs, W), new(xs, W), ref(xs, W)
        assert a == c, ('old != ref', W, t)
        assert b == c, ('new != ref', W, t)
    print(f"W={W}: 300 random planes, old == new == definition")

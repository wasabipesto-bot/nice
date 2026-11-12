"""N13 correction (2026-11-12): the profiled ablation runs on the RX 9070 XT ran at a lower GPU clock.
Per mode: median busy/clock/power from the .gpu samples (first and last sample dropped), the profile's phase
timers summed over the timed fields (size >= 1e16; the 1e14 warm-up skipped), and the join rescaled by the run's
own top phase (same kernel and work in every mode). Usage: python3 clock_check.py ../demoux"""
import re, sys, statistics as st
d = sys.argv[1] if len(sys.argv) > 1 else "../demoux"
def gpu(p):
    b, c, w = [], [], []
    for line in open(p):
        m = re.search(r"busy=(\d+) sclk=\d+:(\d+)Mhz pw=(\d+)", line)
        if m: b.append(int(m[1])); c.append(int(m[2])); w.append(int(m[3]) / 1e6)
    if len(b) > 4: b, c, w = b[1:-1], c[1:-1], w[1:-1]
    return st.median(b), st.median(c), st.median(w)
def prof(p):
    tot = {}
    for line in open(p):
        if not line.startswith("GPU_PROFILE"): continue
        kv = {k: float(v) for k, v in re.findall(r"(\w+)=(-?[\d.]+)", line)}
        if kv.get("size", 0) < 1e16 or kv.get("batches", 0) == 0: continue
        for k in ("device_wall", "top", "bucket", "join", "check", "probe", "upload", "pairs", "checked", "batches"):
            tot[k] = tot.get(k, 0) + kv.get(k, 0)
    return tot
for base in ("b62", "b60"):
    ref = prof(f"{d}/p_c_{base}.log"); field = ref["device_wall"] - ref["probe"]
    print(f"\n{base}: profiled field (mode c, probe excluded) {field:.2f} s, pairs {ref['pairs']:.4e}, batches {ref['batches']:.0f}")
    print("mode  busy   MHz     W |   top  bucket   join  check  wall-probe | scale | join*scale  share  ps/pair | join unscaled share")
    js = {}
    for m in ("c", "c2", "p", "b", "a", "z"):
        t = prof(f"{d}/p_{m}_{base}.log"); b, c, w = gpu(f"{d}/p_{m}_{base}.gpu"); s = ref["top"] / t["top"]; js[m] = (t["join"] * s, t["join"])
        print(f"{m:4s} {b:5.0f} {c:6.0f} {w:5.0f} | {t['top']:6.2f} {t['bucket']:6.2f} {t['join']:7.2f} {t['check']:6.2f} {t['device_wall']-t['probe']:9.2f}  | {s:5.3f} | {t['join']*s:8.2f}  {t['join']*s/field:6.1%} {t['join']*s/ref['pairs']*1e12:7.3f} | {t['join']/field:6.1%}")
    z, a, b_, p, c = (js[k][0] for k in ("z", "a", "b", "p", "c"))
    print(f"rescaled parts: base {z:.2f} ({z/field:.1%})  AND {a-z:.2f} ({(a-z)/field:.1%})  walk {b_-a:.2f} ({(b_-a)/field:.1%})  prefilter {p-b_:.2f} ({(p-b_)/field:.1%})  stage {c-p:.2f} ({(c-p)/field:.1%})  check {ref['check']:.2f} ({ref['check']/field:.1%}, {ref['check']/ref['checked']*1e9:.3f} ns)")
    print(f"bounds without rescaling (each mode's own join timer is an upper bound at a lower clock): base <= {js['z'][1]/field:.1%}; base+AND <= {js['a'][1]/field:.1%}; so walk+prefilter+stage >= {(js['c'][1]-js['a'][1])/field:.1%}")

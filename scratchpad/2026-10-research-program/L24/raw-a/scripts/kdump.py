#!/usr/bin/env python3
"""CubeCL CUBECL_DEBUG_LOG kernel dumps: extract, normalise, diff.

  kdump.py extract LOG OUTDIR   one file per compiled kernel: <Kernel>_b<base>[_<n>].<lang>
  kdump.py diff DIR_A DIR_B [GLOB]  alpha-renamed unified diff of each common file

Normalisation renames the generated SSA names (l_N, l_mut_N, a_N) in order of
first appearance, per family, so a change that adds or moves a few statements
does not renumber the rest of the kernel.
"""
import difflib, glob, os, re, sys

def extract(log, out):
    os.makedirs(out, exist_ok=True)
    text = open(log, errors="replace").read()
    seen = {}
    for blk in re.findall(r"\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]", text, re.S):
        m = re.search(r"type: ([\w:]+)::(\w+)<", blk)
        kname = m.group(2) if m else "unknown"
        base = re.search(r"\bbase: (\d+)", blk)
        info = re.search(r"info: \w+ \{(.*?)\n    \},\n\}", blk, re.S)
        fence = re.search(r"source:\n```(\w*)\n(.*?)```", blk, re.S)
        if not fence:
            continue
        lang, src = fence.group(1) or "txt", fence.group(2)
        key = f"{kname}_b{base.group(1) if base else 'x'}"
        sig = info.group(1) if info else ""
        lst = seen.setdefault(key, [])
        if sig in [s for s, _ in lst]:
            continue  # same kernel compiled again (another context)
        lst.append((sig, src))
        name = key if len(lst) == 1 else f"{key}_{len(lst)}"
        open(os.path.join(out, f"{name}.{lang}"), "w").write(src)
        open(os.path.join(out, f"{name}.info"), "w").write(sig)
    n = sum(len(v) for v in seen.values())
    print(f"{log}: {n} distinct kernels -> {out}")

def normalise(src):
    maps = {}
    def sub(m):
        fam, idx = m.group(1), m.group(2)
        d = maps.setdefault(fam, {})
        if idx not in d:
            d[idx] = str(len(d))
        return f"{fam}_{d[idx]}"
    return re.sub(r"\b(l_mut|l|a)_(\d+)\b", sub, src)

def diff(a, b, pat="*"):
    total = 0
    for fa in sorted(glob.glob(os.path.join(a, pat))):
        if fa.endswith(".info"):
            continue
        fb = os.path.join(b, os.path.basename(fa))
        if not os.path.exists(fb):
            print(f"== {os.path.basename(fa)}: only in {a}")
            continue
        na = normalise(open(fa).read()).splitlines()
        nb = normalise(open(fb).read()).splitlines()
        d = list(difflib.unified_diff(na, nb, os.path.basename(fa) + " (main)",
                                      os.path.basename(fb) + " (branch)", n=2, lineterm=""))
        plus = sum(1 for l in d if l.startswith("+") and not l.startswith("+++"))
        minus = sum(1 for l in d if l.startswith("-") and not l.startswith("---"))
        print(f"== {os.path.basename(fa)}: {len(na)} -> {len(nb)} lines, -{minus} +{plus}")
        total += plus + minus
        for l in d:
            print(l)
    for fb in sorted(glob.glob(os.path.join(b, pat))):
        if not fb.endswith(".info") and not os.path.exists(os.path.join(a, os.path.basename(fb))):
            print(f"== {os.path.basename(fb)}: only in {b}")
    print(f"TOTAL changed lines {total}")

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "extract":
        extract(sys.argv[2], sys.argv[3])
    elif cmd == "diff":
        diff(sys.argv[2], sys.argv[3], *(sys.argv[4:5]))

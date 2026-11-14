#!/usr/bin/env python3
"""Reviewer's own comparison of the author's CubeCL compilation logs (raw/box/ident/{M,M2,F}/cuda.log).

Per kernel: the CUDA source between ```cpp fences. Locals (l_*, l_mut_*, l_arr_*) and shared arrays
(shared_memory_*) are renamed by first use in the body; each shared array's declared element count is
attached to its new name (so a size change is a difference), offsets are reported separately, and
overlapping shared arrays (aliasing) are listed per side. Bodies + per-array sizes must match exactly.
Also compares the KernelId info block (comptime args) verbatim.
"""
import re
import sys


def blocks(p):
    t = open(p).read()
    out = {}
    for x in re.findall(r"\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]", t, re.S):
        name = re.search(r"name: [\w:]*::(\w+)::", x).group(1)
        info = re.search(r"id: KernelId \{(.*?)\n\}\nsource:", x, re.S).group(1)
        src = re.search(r"```cpp\n(.*?)```", x, re.S).group(1)
        out[name] = (info, src)
    return out


def norm(src):
    lines = src.splitlines()
    shm = {}  # name -> (size, offset)
    pend = None
    keep = []
    for l in lines:
        m = re.match(r"^// Shared array size: (\d+), (\d+) bytes$", l)
        if m:
            pend = int(m.group(1))
            continue
        m = re.match(r"^\w+ \*(shared_memory_\d+) = reinterpret_cast<\w+\*>\(&dynamic_shared_mem\[(\d+)\]\);$", l)
        if m:
            shm[m.group(1)] = (pend, int(m.group(2)))
            pend = None
            continue
        keep.append(l)
    decl = [l for l in keep if re.match(r"^(const )?(uint32|uint64|int32|int64|bool|float|uint32_4|uint3|uint8)\*? ?l_\w+(\[\d+\])?;$", l)]
    body = [l for l in keep if l not in decl]
    names = {}
    rx = re.compile(r"\b(?:l_(?:mut_|arr_)?\d+|shared_memory_\d+)\b")

    def ren(m):
        k = m.group(0)
        if k not in names:
            if k.startswith("shared_memory_"):
                names[k] = f"S{len(names)}[{shm[k][0]}]"
            else:
                names[k] = f"v{len(names)}"
        return names[k]

    body = [rx.sub(ren, l) for l in body]
    decl = sorted(rx.sub(lambda m: names.get(m.group(0), "UNUSED"), l) for l in decl)
    unused = [k for k in shm if k not in names]
    offs = {names.get(k, k): shm[k] for k in shm}
    # aliasing: overlapping [off, off + 4*size) among shared arrays (4-byte elements assumed)
    iv = sorted((o, o + 4 * s, n) for n, (s, o) in offs.items())
    over = [(a[2], b[2]) for i, a in enumerate(iv) for b in iv[i + 1:] if b[0] < a[1]]
    return body, decl, unused, offs, over


def main():
    a, b = blocks(sys.argv[1]), blocks(sys.argv[2])
    for k in sorted(set(a) | set(b)):
        if k not in a or k not in b:
            print(k, "only in one log")
            continue
        ia, sa = a[k]
        ib, sb = b[k]
        na, nb = norm(sa), norm(sb)
        same_body = na[0] == nb[0] and na[1] == nb[1]
        same_info = ia == ib
        sizes_a = sorted(n for n in na[3])
        sizes_b = sorted(n for n in nb[3])
        print(f"{k}: body {'SAME' if same_body else 'DIFFERS'}; comptime info {'SAME' if same_info else 'DIFFERS'}; "
              f"shared arrays {len(na[3])}/{len(nb[3])} {'same names+sizes' if sizes_a == sizes_b else 'DIFFER'}; "
              f"unused shared {na[2]}/{nb[2]}; overlaps A {na[4]} B {nb[4]}")
        if not same_body:
            import difflib
            d = list(difflib.unified_diff(na[0], nb[0], lineterm="", n=0))
            print("   body diff lines:", len(d))
            for l in d[:12]:
                print("     ", l)


if __name__ == "__main__":
    main()

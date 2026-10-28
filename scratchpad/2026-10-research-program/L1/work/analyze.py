#!/usr/bin/env python3
"""Parse GPU_PROFILE / JOIN THROUGHPUT lines from the L1 raw logs into tables."""
import re, sys, collections

ROOTS = {57: 6, 58: 4, 60: 2, 62: 2, 64: 8}
NB = {}

def parse(path):
    rows = []
    for line in open(path):
        if not line.startswith("GPU_PROFILE") and "GPU_PROFILE" not in line:
            continue
        line = line[line.index("GPU_PROFILE"):]
        kv = dict(re.findall(r"(\w+)=([0-9.e+-]+)", line))
        r = {k: float(v) for k, v in kv.items()}
        r["start_s"] = re.search(r"start=(\d+)", line).group(1)
        rows.append(r)
    return rows

def tput(path):
    out = []
    for line in open(path):
        if "JOIN THROUGHPUT" in line:
            kv = dict(re.findall(r"(\w+)=([0-9.e+-]+)", line))
            out.append({k: float(v) for k, v in kv.items() if re.match(r"^[0-9.e+-]+$", v)})
    return out

def main():
    path = sys.argv[1]
    size = float(sys.argv[2]) if len(sys.argv) > 2 else 1e16
    rows = [r for r in parse(path) if r["size"] == size]
    phases = ["upload", "inputs", "top", "bucket", "join", "check", "read", "probe", "unattributed"]
    print(f"## {path} (fields of {size:.0e})\n")
    print("| base | field start | device s | setup s | " + " | ".join(phases) + " |")
    print("|---|---|---|---|" + "---|" * len(phases))
    for r in rows:
        print(f"| {int(r['base'])} | {r['start_s']} | {r['device_wall']:.2f} | {r['setup']:.2f} | "
              + " | ".join(f"{r[p]:.2f}" for p in phases) + " |")
    print()
    print("| base | field | share top | bucket | join | check | other (upload+inputs+read+probe+unattr) |")
    print("|---|---|---|---|---|---|---|")
    for r in rows:
        d = r["device_wall"]
        other = sum(r[p] for p in ["upload", "inputs", "read", "probe", "unattributed"])
        print(f"| {int(r['base'])} | {r['start_s']} | {r['top']/d:.1%} | {r['bucket']/d:.1%} | {r['join']/d:.1%} | {r['check']/d:.1%} | {other/d:.1%} |")
    print()
    print("| base | roots | ntlay | partitions | nbp | µs/prefix (device) | µs/prefix (top) | (join) | (bucket) | tops/prefix | listed/partition | pairs/prefix | padded/pairs | AND surv/prefix | prefilter surv/prefix | surv/pair | prefilter keep | hits |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        n = r["ntlay"]; b = int(r["base"])
        print(f"| {b} | {ROOTS.get(b)} | {int(n)} | {int(r['partitions'])} | {int(r['nbp'])} | {r['device_wall']/n*1e6:.2f} | {r['top']/n*1e6:.2f} | {r['join']/n*1e6:.2f} | {r['bucket']/n*1e6:.2f} | "
              f"{r['tops']/n:.0f} | {r['listed']/(r['partitions']*r['slices']):.3g} | {r['pairs']/n:.3g} | {r['padded_pairs']/max(r['pairs'],1):.3f} | {r['survivors']/n:.0f} | {r['checked']/n:.0f} | {r['survivors']/max(r['pairs'],1):.3e} | {r['checked']/max(r['survivors'],1):.3%} | {int(r['hits'])} |")
    print()
    for t in tput(path):
        print({k: t[k] for k in ("base", "secs", "per_field", "rate", "setup", "device", "slots", "plan_mib", "survivors", "checked") if k in t})

main()

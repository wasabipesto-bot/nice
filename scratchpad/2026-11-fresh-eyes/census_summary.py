#!/usr/bin/env python3
"""Summarise census_apple.json: fields whose only qualified nice-only searches are join runs on an
Apple GPU with a build that lacks #222 (7155c49c). Writes census_summary.json (compact)."""
import json, collections, subprocess
REPO = "/home/claude/projects/nice"; FIX = "7155c49c"
_anc = {}
def has_fix(sha):
    if not sha: return None
    if sha not in _anc:
        r = subprocess.run(["git", "-C", REPO, "merge-base", "--is-ancestor", FIX, sha], capture_output=True)
        _anc[sha] = (r.returncode == 0) if r.returncode in (0, 1) else None
    return _anc[sha]
d = json.load(open("census_apple.json"))
fields = {f["id"]: f for f in d["fields"]}
subs = collections.defaultdict(list); seen = set()
for s in d["subs"]:
    if s["id"] in seen: continue
    seen.add(s["id"]); subs[s["field_id"]].append(s)
def klass(s):
    """'bad' = Apple GPU join run on a build without the fix; 'ok' = anything else qualified."""
    if s["disqualified"] or s["search_mode"] != "niceonly": return None
    apple = "Apple" in (s.get("gpu") or "")
    if apple and s.get("route") == "join":
        f = has_fix(s.get("build"))
        if f is False: return "bad"
        if f is None: return "unknown"
    return "ok"
builds = collections.Counter(); users = collections.Counter()
out = collections.defaultdict(lambda: dict(fields=0, size=0, only_bad=0, only_bad_size=0, unknown=0))
bad_ids = []
for fid, f in fields.items():
    ks = [klass(s) for s in subs.get(fid, [])]
    ks = [k for k in ks if k]
    if "bad" not in ks and "unknown" not in ks: continue
    o = out[f["base_id"]]; o["fields"] += 1; o["size"] += int(f["range_size"])
    if "ok" not in ks:
        if "unknown" in ks and "bad" not in ks: o["unknown"] += 1
        o["only_bad"] += 1; o["only_bad_size"] += int(f["range_size"]); bad_ids.append(fid)
for s in d["apple"]:
    if s["search_mode"] == "niceonly" and s.get("route") == "join":
        builds[((s.get("build") or "")[:8], s["client_version"], has_fix(s.get("build")))] += 1
        users[s["username"]] += 1
print("apple nice-only join submissions by (build, version, has #222):")
for k, v in builds.most_common(): print("   ", k, v)
print("users:", dict(users))
NPD_OLD = {57: 4.0e18, 58: 4.14e18, 60: 7.73e18}      # v3.4.6 numbers per dollar (cost model)
SPEED = {57: 2.4, 58: 2.4, 60: 2.5}                  # today's main over v3.4.6 (estimate)
tot_old = tot_new = 0
for b in sorted(out):
    o = out[b]; c_old = o["only_bad_size"] / NPD_OLD.get(b, 4e18); c_new = c_old / SPEED.get(b, 2.4)
    tot_old += c_old; tot_new += c_new
    print(f"base {b}: touched by a pre-fix Apple join run: {o['fields']} fields ({o['size']:.3e}); only such runs: {o['only_bad']} fields ({o['only_bad_size']:.3e} numbers; of which unknown-build only {o['unknown']}); re-search ${c_new:.2f} on today's main (${c_old:.2f} at v3.4.6 prices)")
print(f"total re-search: ${tot_new:.2f} on today's main, ${tot_old:.2f} at v3.4.6 prices; fields {len(bad_ids)}")
json.dump({"by_base": out, "field_ids": sorted(bad_ids)}, open("census_summary.json", "w"))

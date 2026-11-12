#!/usr/bin/env python3
"""Markdown census table per base from sample.json (cells, shares, populations)."""
import json
s = json.load(open("sample.json"))
for b in (58, 60):
    print(f"\n| base {b} cell (GPU family, build, version) | qualified subs | share of base range | non-empty (population) | sample target |\n|---|---|---|---|---|")
    for c in [c for c in s if c["base"] == b]:
        print(f'| {c["family"]}, {c["build"]}, {c["version"]} | {c["subs"]:,} | {100*c["share"]:.2f} % | {c["population"]:,} | {c["n"] if c["checkable"] else "not checkable"} |')

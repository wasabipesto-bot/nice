#!/usr/bin/env python3
"""Fill SCOPING.md's A/B section from ab-analysis.txt (re-runnable)."""
import re, sys
D = "/home/claude/projects/nice/scratchpad/2026-10-research-program/L31"
ab = open(f"{D}/raw/ab-analysis.txt").read()
main = ab.split("### nvidia-smi")[0].strip()
main = main.replace("### ", "#### ")
s = open(f"{D}/SCOPING.md").read()
start = s.index("<!-- AB-BEGIN -->") if "<!-- AB-BEGIN -->" in s else None
block = "<!-- AB-BEGIN -->\n" + main + "\n<!-- AB-END -->"
if start is None:
    s = s.replace("@@ABTABLES@@", block)
else:
    end = s.index("<!-- AB-END -->") + len("<!-- AB-END -->")
    s = s[:start] + block + s[end:]
open(f"{D}/SCOPING.md", "w").write(s)
print("filled")

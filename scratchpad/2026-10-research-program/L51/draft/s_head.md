# L51 RESULTS: d813aea profiled, ablated and retuned (RTX 3080 at 180 W, 2026-11-08; measurement only, no PR)

Measurement session on fork **`pr/top-fd-round2` `d813aea`** (= upstream main `6f060a9` + #241 + #246 + #249 (static
bucket order + the stage once per batch) + FD round 2). Experiment branch **`exp/l51-profile`** on the fork, head
**`14f87cd`** (§0). Box: Vast **59671466** (`nice-research-l51-profile`), machine **m139246**, RTX 3080 at a **180 W
cap**. Raw logs `raw/box/`, scripts `raw/scripts/`, every table below is `python3 raw/scripts/analyze51.py raw/box`
(→ `raw/analysis.txt`).

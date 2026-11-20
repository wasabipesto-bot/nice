# The middle-out join: design document and process maps (2026-11-19)

For the maintainer, before reading the code of the redesigned nice-only GPU join on the fork branch `dev/mo-clean`
(head `10ddbf17` since 2026-11-20, worktree `~/projects/nice/.worktrees/midout-clean`). Nothing here changes any repository.

## Contents

- `DESIGN.md`: read this first. The idea in one page, the pipeline of one field stage by stage (in, out, cost on
  the RX 9070 XT and the RTX 3080, the check that guards it), what a field is and what it commits the project to,
  how the code knows the work ran, the design decisions with the alternatives and their numbers, what is measured
  and where, what is not done or not known, the file map and how to run it. Every claim is labelled measured,
  proven or judged.
- `interactive/midout-map.html`: one self-contained file; open it in a browser. The whole path of one base-64
  field from claim to submit, in the format of the #178 process map: host and coordinator lane, device lane for
  one slice, and a lane for v3.4.8's overlap join beside the stage each corresponds to. Colour = where it runs;
  shape = role; gold REUSED badge = production code used unchanged; frequency badges (PROC, FIELD, /64, SLICE,
  BATCH, GROUP); time-share bars (RX 9070 XT; the 3080 in the panel; the overlap lane's shares are derived and
  hatched). Click a shape for why it exists, how it connects, cost, the check that guards it, file:line (into
  `dev/mo-clean` at `10ddbf17`, or `origin/main` at `974d7194` for the overlap lane), its wide-path counterpart and
  its overlap-join counterpart. Spotlights: by frequency; where each execution check is made and compared (draws
  the account edges); base-64 path against the wide path (teal = has a counterpart, orange dashed = none); what a
  field fixes; what is reused from production.
- `static/midout-overview.svg` and `.png` (2×): the simplified one-screen picture, no line numbers; it heads
  `DESIGN.md`.
- `screenshots/`: renders used to check the map (full page light, each spotlight, 2× panel views light and dark).
- `tools/`: `check_refs.py` (every file:line in the map must contain its named identifier; 87 refs, 0 bad at the
  time of writing), `print_inline_refs.py` (prints the target line of each inline ref in `DESIGN.md` for reading),
  `shot_map.cjs` (clicks every node and checks its panel, tries each spotlight and toggle, checks phone width,
  takes the screenshots), `svgshot.cjs` (SVG → PNG), `../static/make.py` (writes the SVG).

## How it was made

The code is the source: stage table, data layouts and accounts from `common/src/midout/gpu.rs`'s module docs and
from `finish_group` / `check_slice`; every number from the notes and experiment log under
`~/projects/nice/scratchpad/2026-10-research-program/` (each entry names its raw data), re-read against the raw
logs where it mattered (the RX 9070 XT stage profile was recomputed from `G2/build4s/window_1119/s_*.log`). The map
reuses the #178 map's rendering approach (`~/projects/nice/scratchpad/2026-10-process-map/`), rewritten for this
data.

## How to regenerate

```sh
cd ~/projects/nice/scratchpad/2026-11-midout-design
python3 tools/check_refs.py interactive/midout-map.html       # read-only git and file reads
python3 tools/print_inline_refs.py DESIGN.md
(cd static && python3 make.py)
# Chromium lacks system libraries on ivory, so Playwright runs in its container (podman via the docker shim):
docker run --rm --ipc=host -v "$HOME/browser-harness:/w:ro" -v "$PWD:/page" -e NODE_PATH=/w/node_modules \
  -w /page mcr.microsoft.com/playwright:v1.62.0-noble node /page/tools/shot_map.cjs
docker run --rm --ipc=host -v "$HOME/browser-harness:/w:ro" -v "$PWD:/page" -e NODE_PATH=/w/node_modules \
  -w /page mcr.microsoft.com/playwright:v1.62.0-noble \
  node /page/tools/svgshot.cjs /page/static/midout-overview.svg /page/static/midout-overview.png
```

If the branch moves, line numbers move: rerun `check_refs.py` and fix any `BAD` line in the map's `N` array.

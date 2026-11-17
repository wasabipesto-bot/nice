# G2 proposal brief: what exactly would have to change for the redesigned join, at the smallest possible cost (2026-11-17)

You are a systems designer on the nice research program (repo `~/projects/nice` on this machine,
ivory; upstream `wasabipesto/nice`). Nothing in this task is implemented or pushed: the
deliverable is a decision document for the project's maintainer, who owns the server and
has so far not wanted a server rearchitecture ("not interested in a server rearchitecture for
just one mode"; an earlier, weaker design was parked at a bar of ×3 per base).

## Read first

- `G2/RESULTS.md` (the redesigned join: transversal super-units, shape (4, 10)), `G2/REVIEW.md`
  (adversarial review; F5 and F6 on the baseline and on what the server change really is) and
  **`G2/BENCH.md` (measured this morning: ×5.1 against same-session main at base 64 on an RTX
  3080; kept 64-pair word 32 ps; LDS-bound; the production card, an AMD RX 9070 XT, is
  unmeasured)**. `BX/a3-adversary/NOTES.md` "Day 2": the pairing structure cannot be improved by
  more than ×1.14–1.36, so ×5 is about what this structure is worth on NVIDIA.
- The server as it is: `schema.sql` and migrations; `api/src/main.rs` (claim and submit
  handlers), `api/src/field_queue.rs`; `common/src/db_util/` (fields, claims, submissions);
  `jobs/` (consensus, check levels, downsampling); `common/src/lib.rs` types that cross the
  wire (`DataToClient`, `DataToServer`, `FieldRecord`); the client's claim → process → submit
  loop in `client/src/main.rs`; how the public site and the PostgREST views read progress.
- Facts: base 62 is being searched now in 95,430 contiguous fields of 1e17 and ends in late
  December; **base 64's fields are not in the database yet**; the main production client is one
  AMD card (about 86 % of the nice-only output), then a rented NVIDIA fleet, an Apple M4, and
  occasional CPU clients; detailed (distribution) searches use the same fields table at much
  lower bases and need contiguous ranges of n; every nice-only field today ends at
  `check_level` 1 with telemetry counters (`survivors`, `checked`) that audits compare.

## Task

Work out and compare, concretely against the code, the ways base 64 could be searched in G2's
structure, from the least to the most invasive, and say what each really costs:

- **A. A virtual coordinate.** Base 64's "fields" stay rows of the existing table with
  `range_start` / `range_end`, but for that base the range is over a coordinate v(n) that
  orders candidates by their shared middle digits first, so a row is a set of transversal
  super-units. What must know about v (the client only? the API's size checks, the jobs'
  consensus, the site's displays, the "numbers" a submission reports, near-miss statistics,
  anything that assumes `range_start ≤ n < range_end`)? Find every such assumption in the code
  and list it with file and line.
- **B. A separate unit table and endpoints** for transversal units.
- **C. No server change:** one or a few giant contiguous fields for base 64 with the
  transversal iteration and checkpoints on the client (the review says contiguous units only
  work at base 64 if a unit is the whole base). What is lost (other clients' participation,
  restart safety, auditability, public progress), and is there a middle form (a client-side
  coordinator for the user's own machines)?
- For each: the schema and API diff in outline, the client work per backend (CUDA through
  CubeCL, SPIR-V on wgpu for the AMD card, Metal, WGSL, CPU, the browser client) and which
  backends are truly needed for base 64 to proceed (can clients without a G2 implementation
  simply not take base-64 nice-only work?), verification (how a unit's result is audited: the
  survivor count of a unit is a property of the unit and shape, and an independent
  implementation reproduced it), the mid-base and fallback story (if G2 units and ordinary
  fields must coexist), what the maintainer would have to review and deploy, an honest effort
  estimate in files and days of agent work plus maintainer review time, and the risks.
- **A phased plan with decision points:** the first being the measurement on the AMD card
  (needs a port of the benchmark kernel to the CubeCL SPIR-V runtime and under an hour on that
  machine), with the number below which everything stops; then the smallest end-to-end slice
  that proves the path (for example base 64's first units through option A on one backend).
- **A recommendation**, and the strongest argument against it.

Be concrete and brief. The maintainer has little time: the document's first half page must
let them decide whether to read the rest.

## Rules

Reading and writing only: CPU on ivory, one thread, `nice -n 19`; write only
`G2/PROPOSAL.md` (and notes under `G2/proposal/`); no builds needed; no pushes, no pull
requests, no subagents, no rented machines, no contact with the production API or servers
(the schema and code are in the repository). Hard stop **10:45 UTC**. Your final message is at
most 250 words for the program's director: the recommendation, its cost, and the strongest
argument against it.

# G2 benchmark brief: one real base-64 super-unit on a GPU, against today's main (2026-11-16 evening)

Your design study (`G2/RESULTS.md`) was reviewed adversarially: read **`G2/REVIEW.md` in full
before anything else** (and `G2/review/` for its code). Summary of the verdict: soundness,
coverage and your counts hold (confirmed by an independent implementation, including sets you
had only compared by count); the ×10 does not: the 64-pair word was costed below every
measurement of it, the base-64 four-Russians table was amortized over the wrong number of
probes (your own model then gives ×7.2), the bottom side at base 62 was priced at a few
instructions, and the top hierarchy and the shared bottom tree want opposite super-unit orders.
Corrected central: about ×5 at base 64 (band ×2.6–9.6). Base 62 will be finished before
anything of this could ship, so **base 64 is the only base this is for** (about 1.5 years at
today's speed). One measurement decides whether the project pursues it: build it.

## Task

Build and run the benchmark the review specifies (`G2/REVIEW.md`, "The benchmark"), with any
improvement you can justify, on the rented card:

1. **Inputs** from your prototype for one real base-64 super-unit (digits 4–8; all 64 units of
   digit 9): the depth-9 parents sorted per class by the pooled 8-bit key, the tops of every
   unit, per unit the expected survivor set and counts. A second super-unit elsewhere in the
   range if time allows.
2. **The kernel** (throwaway code: raw CUDA through nvcc or NVRTC is fine; say what a port to
   CubeCL and SPIR-V would need, because the production card is an AMD RX 9070 XT on wgpu):
   affine children per unit digit, compaction, 64-chunks transposed with common masks, probes
   by the unit's tops of the compatible classes, common-mask skip, the 64-wide test (bit-sliced
   and, where a chunk has enough probes, four-Russians), survivors appended. Switches: probes
   off (bottom side alone), skip off, full. A second small kernel or a host path for the
   parents of the super-unit from stored roots plus the counting sort, timed per parent.
3. **Exactness first:** every unit's survivor set equals the prototype's (which the reviewer's
   independent code reproduces). No timing counts until the sets match.
4. **Measure** (card idle before each run, no builds while timing, power and clock per run):
   ps per child and per stored bottom; ps per flat incidence and per kept 64-pair word, with
   and without the skip; ps per parent of the preparation; **end-to-end fs per admissible n of
   the super-unit, preparation included**; registers, shared-memory use and occupancy.
5. **Today's main on the same box, same session:** upstream main (`7e0113fc` or its current
   head) with `--features gpu,cubecl-cuda`, the real client against the local stub API exactly
   as `MU260/RESULTS.md` task 2 and `T28/RESULTS.md` §3 did (reuse `T28/raw/stub_api.py`,
   `hosts_block.sh`; block the production hosts first and prove it): base-64 fields of 1e17 at
   five to ten positions spread over 0.05–0.95 of base 64's range, empties counted, to get the
   base mean in fs per admissible n (the B64.1 protocol; `B64/RESULTS.md`).
6. **Verdict against the review's stop numbers** (base 64, same-session main): stop if
   end-to-end is above 1.06 fs per admissible n or under ×5, or if the all-in kept word is above
   25 ps, or a stored bottom above 25 ps; worth a run on the RX 9070 XT at ×6 or better; the ×10
   claim only at ×10. Between ×5 and ×6: stop unless one named component is the culprit and
   you have measured its fix. Report the ratio you measured, not the one you hoped for.

## Rules

Your box is Vast instance **60959320** (RTX 3080 10 GB at a 300 W cap, 24 threads; `python3 vast.py ssh 60959320`
from the program directory; ssh verified by the director; wait for `/root/READY`; it destroys
itself at about 03:25 UTC). Never `vast.py create` or `destroy`. Throwaway code lives under
`G2/bench/` on ivory (and on the box); nothing is pushed anywhere, no pull requests, no
subagents. Production hosts blocked on the box before any client runs; never claim from or
submit to production; nothing on the fleet, the server, demoux or mayalaran. ivory: one
thread, `nice -n 19`, keep 4 GB of disk free. Copy results to ivory early and often (an outage
this morning stopped an agent mid-run). Wait for long runs with one long wait at a time and
hand back once.

## Deliver

`G2/BENCH.md`: the verdict against the stop numbers first; the measured table (every component
and end to end, with rounds, power and clock) beside the model's and the review's predictions;
exactness evidence; what a SPIR-V port needs and what could differ on the RX 9070 XT (LDS,
occupancy, 64-lane planes); what you would change in the design having seen the card. Hard
stop **02:45 UTC** (tonight, 2026-11-17). Your final message is at most 300 words for the
program's director: the measured ratio first.

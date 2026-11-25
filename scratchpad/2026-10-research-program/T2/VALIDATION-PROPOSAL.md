# A known-answer check in validation for nice-only (and later `midout`): proposal, one page (2026-11-25)

For the maintainer. Nothing here is built. It follows your note of 2026-11-25: *"The benchmark and the
validation are two different functions, I'd be more comfortable putting this in validation."*

## What is missing today (upstream main `fdbe07d3`)

- `--validate` exists for detailed mode only. The server hands out a random double-checked field with an id
  between 10,000 and 50,000 (bases 42–43) and its canonical distribution (`common/src/db_util/fields.rs:993`);
  the client searches it and compares the distribution and the numbers (`client/src/main.rs:1313`).
- `niceonly --validate` is refused: "Configuration not supported: Validation && Niceonly"
  (`client/src/main.rs:1791`). A nice-only result is an empty list for every field, so comparing results proves
  nothing; that is why the combination was never offered.
- So **the path that does 100 % of today's search has no check a user or the fleet can run on a device.** A
  device that runs every kernel but rejects too much submits a normal-looking empty field. Two real defects
  were of this kind (the flush race fixed by #222 on Apple M4; the SPIR-V atomic-store loss caught before
  release in #263). Both were visible in two numbers the join already counts and sends in its telemetry:
  `survivors` (pairs that pass the join) and `checked` (of those, the candidates the full check reads)
  (`common/src/overlap_join.rs:288–291`). For a given field and join parameters these two counts are the same
  on every device and layout; the test suite relies on it.

## Proposal

**`nice_client niceonly --validate` stops being refused and runs a known-answer check; no server change.**

1. The client carries a short table of fixed fields, one or two per route and base it can be given today
   (stride at a low base; the join at bases 58, 60, 62), each with the join parameters it was computed under and
   the two counts **as the CPU reference computes them** (`common/src/cpu_join.rs`, the exact form the device is
   tested against in CI). Sizes chosen so that the whole run takes one to two minutes on a mid-range card.
2. `niceonly --validate` (with or without `--gpu`) searches each table field on the route and device a real
   claim would use and compares `survivors`, `checked` and the (empty) list of numbers. Output per field:
   pass, or the two pairs of counts; exit 1 on any difference, like detailed validation today. Nothing is
   claimed or submitted, and no network is needed.
3. A field whose join parameters in the running build differ from the table's is reported as "not comparable"
   and fails a unit test in CI, so a release that changes the join cannot ship a stale table: the table is
   re-computed on a CPU when the join's parameters change (the same occasion on which the benchmark's
   references are re-pinned).
4. `midout`, when it exists, gets the same thing with its own counts. It already compares a sampled part of
   every real field with the CPU, so there the check is a start-up convenience, not the only safeguard.

**Not proposed:** running it automatically at client start (your call; it would cost every start a minute or
two); a server endpoint that hands out real nice-only fields with stored counts (a server change for little
more than the table gives; the related server-side invariant was declined on 2026-11-10); putting the counts in
the benchmark (your note).

## Cost and limits

- One small pull request: the table, the comparison, the unit test, two README lines. About 150 lines.
  Computing the table once: an hour or two of CPU on ivory.
- It catches a device or driver that loses candidates on these fields. It does not prove a device is right on
  every field, and it cannot catch a defect the CPU reference shares (the CI parity tests and the reference's
  own brute-force tests are for that).
- The fleet could run it once per box at provisioning; that is a separate, later choice.

## What I need

A yes or no. On a yes I build it as one pull request under the usual bar. If you do not answer, nothing is
built.

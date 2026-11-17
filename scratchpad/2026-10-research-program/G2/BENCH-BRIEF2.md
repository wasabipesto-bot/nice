# G2 benchmark, second start: run the staged GPU benchmark of the redesigned join (2026-11-17)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice`). The program's rules (`../README.md`) authorise work on rented Vast
boxes that the director creates; **your box for this task is Vast instance 61025183** (RTX 3080
10 GB at a 260 W power cap, 48 threads; from the program directory `python3 vast.py ssh 61025183`
prints the ssh command; the director has logged in to it; wait for `/root/READY`; it destroys
itself at about 11:45 UTC). Using that box over ssh and scp is the task.

## Read first

1. `G2/RESULTS.md`: a clean-slate redesign of the project's "overlap join" (transversal
   super-units, shape (4, 10), bottoms generated from shared parents, top-driven pairing over
   sorted 64-chunks with a common-mask skip). Counts measured by an exact CPU prototype.
2. `G2/REVIEW.md`: the adversarial review. Design and counts hold; the designer's ×10 is
   corrected to about ×5 per base at base 64 (band ×2.6–9.6) because GPU unit costs were
   optimistic. Its last section specifies the benchmark and the stop numbers.
3. `G2/BENCH-BRIEF.md` (the task as given to the designer last night) and **`G2/BENCH.md`** (what
   is staged): the designer prepared everything on ivory and never reached a card. Under
   `G2/bench/`: inputs for one real base-64 super-unit (`su64_712012851/`: tops, the prototype's
   survivor set for all 64 units, per-unit counts), `g2bench.cu` (CUDA kernel plus a CPU
   reference path that already reproduces every unit's survivor set and the counts in
   `cpu_ref.txt`), and box scripts (`drive.sh push | setup | build_main | bench | main | pull`,
   `box/`).
4. `T28/RESULTS.md` §3 and `MU260/RESULTS.md` task 2: how today's main is timed through a local
   stub with the production hosts blocked; `B64/RESULTS.md` for base 64's base-mean protocol.

## Task

1. Push the staged files to the box, compile `g2bench.cu` with nvcc (it has never been compiled
   for a GPU: expect a fix-up pass; keep every change exact), and get **every unit's survivor
   set equal to the staged one** in all three modes that produce survivors. No timing counts
   before that.
2. Measure, card idle before each run, no builds while timing, power and clock sampled per
   run, three rounds: ps per child and per stored bottom (probes off); ps per flat incidence and
   per kept 64-pair word with and without the skip; ps per parent of the per-super-unit
   preparation; **end-to-end fs per admissible n of the super-unit, preparation included**;
   registers, shared memory and occupancy of the kernel. If something obvious is slow, fix it
   and say what you changed (this is a benchmark of the structure, not of a first draft), but
   keep a record of each variant.
3. Today's main on the same box in the same session: upstream main's head with
   `--features gpu,cubecl-cuda`, the real client against the local stub (production hosts
   mapped to 127.0.0.1 and the block proven before any client runs), a warm-up field and ten
   base-64 fields of 1e17 spread over 0.05–0.95 of base 64's range, empties counted: the base
   mean in fs per admissible n. Add the top-certificate and survivor-check costs that the
   kernel does not include, from measurements (say which).
4. **Verdict against the review's stop numbers** (base 64, against the same-session main): stop
   if end-to-end is above 1.06 fs per admissible n (under ×5), or the all-in kept word is above
   25 ps, or a stored bottom above 25 ps; worth a run on the production card (an AMD RX 9070 XT
   on wgpu) at ×6 or better; ×10 only at 0.53 fs or less. Report the ratio you measured.
5. If time remains after a clean verdict: a second super-unit elsewhere in base 64's range
   (the prototype under `G2/proto/` can dump one), and what a port to CubeCL and SPIR-V would
   need (LDS use against the 9070 XT's limits; 64-lane planes; the rule that CubeCL's SPIR-V
   compiler keeps only the first of several atomic stores of one value in a block).

## Rules

Throwaway code: everything stays under `G2/bench/` on ivory and on the box; nothing is pushed
to any git remote; no pull requests; no subagents. Never `vast.py create` or `destroy`.
Production hosts blocked on the box before any client runs; never claim from or submit to
production; nothing on the fleet, the server, `~/fleet-run`, demoux or mayalaran. ivory: one
thread, `nice -n 19`, keep 4 GB of disk free. Copy results to ivory early and often. Wait for
long runs with one long wait at a time, and hand back once. If the harness refuses an action,
do not work around it: report it.

## Deliver

`G2/BENCH.md` rewritten: the verdict against the stop numbers first; the measured table (every
component and end to end, rounds, power, clock) beside the model's and the review's
predictions; exactness evidence; what you changed in the kernel; what could differ on the RX
9070 XT. Hard stop **10:45 UTC**. Your final message is at most 300 words for the program's
director: the measured ratio first.

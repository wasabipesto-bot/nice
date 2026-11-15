# T2.8 brief: an early audit of base 62, and what a release is worth on NVIDIA at base 62 (2026-11-15)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails); **`../T2/AUDIT.md` (all of it: the audit of bases 58 and 60 done
on 2026-11-12, whose method, scripts and rules you reuse; scripts under `../T2/raw/`)**;
`../EXPERIMENTS.md` entry T2.3.

## What happened

Base 60 finished and base 62 started at about 00:00 UTC today (fields of 1e17; field ids
207064110 … 207159539; `range_start` of the first is 62^12). In the first five hours:

- demoux (AMD RX 9070 XT, `wgpu<spirv>`, build `a7a59c1`): 7,789 submissions, of which 7,479
  finished instantly (join `run_secs` 0 or absent) and 310 are real (median join 56 s);
- the fleet (`wp-vast-fleet`, release v3.4.7 build `8bd154b`, RTX 4060 mostly): 1,273
  submissions, 1,223 instant and 50 real (median join 338 s).

My snapshot of those rows is `../../2026-11-fresh-eyes/recent_niceonly_1115.json` (submissions
with id > 294552514; columns id, field_id, submit_time, username, client_version, build, run,
surv, chk, launches, gpu). More have arrived since: extend it yourself.

The instant fields have a simple explanation that I derived and you must check exactly: with
x = n / 62^12, the square's leading base-62 digit is ⌊x²⌋ and the cube's is ⌊x³⌋; both are 1 for
x < 2^(1/3), so no n there can be nice; the boundary falls at field index 8,385 (id ≈ 207072495),
which is where the first real fields appear. Both are 2 for x in [√2, 3^(1/3)), about 900 more
fields near id 207077474. Beyond that, a field is instantly empty when the digits its range
fixes at the top of the square and of the cube collide (about 37 % of the fields just past the
boundary so far).

## Task

1. **Every instant verdict so far, checked by exact arithmetic** (ivory, CPU, big integers; no
   device): for each base-62 field that has a submission with zero survivors and zero checked,
   show from its `range_start` and `range_end` alone that no n in it can be nice, by the
   leading-digit argument or by whatever the client's own field-level certificate uses (read
   it: `common/src/overlap_join.rs` and the client's field processing; say exactly what the
   certificate is and re-implement it independently). Report: how many fields are covered by
   which argument, and **any instant field your independent check cannot show to be empty**
   (that would be a finding: report it at once in your final message). Also the reverse: of the
   fields the clients did run, how many would a stronger field-level argument have rejected.
2. **Sampled exact re-verification of the real fields**, by the method of `T2/AUDIT.md` §2–§4
   (the real client of current upstream main against a local stub API on the rented box,
   production hosts blocked first and the block proven; compare `survivors` and `checked`,
   which are exact and device-independent on builds that include #236, and the reported
   numbers): at least 30 of demoux's real fields (the first five past the boundary, the latest
   five, the rest spread; include the fields with the smallest and largest `run_secs`) and at
   least 15 of the fleet's (v3.4.7 on each GPU model that appears). For v3.4.7 follow
   `AUDIT.md`'s rule for which counters are comparable on that build; say plainly which
   comparisons are exact equalities and which are bounds. A mismatch is a finding: report it at
   once with the field id and both telemetry blobs.
3. **What the release is worth on NVIDIA at base 62:** on the same box, the v3.4.7 release
   build against current upstream main (`54d0aac4`), the same six real base-62 fields each,
   interleaved, two rounds: join `run_secs`, whole-field wall time, counts. The fleet is still
   on v3.4.7; its RTX 4060s take a median 338 s per real base-62 field. Give the ratio on the
   RTX 3080 and what it implies for the fleet's fields per dollar-hour (derived; say so).
4. **Telemetry facts for the record:** for demoux's real fields: join `run_secs` distribution,
   setup, slices and slots, fields per hour; the same for the fleet by GPU model; the frontier
   (highest claimed base-62 field id) against time, the fraction of instant fields beyond the
   boundary so far, and a dated estimate of when base 62 ends at the present rate (state the
   assumptions). Check_level and claim state of base 60's last fields (is base 60 complete?).

## Rules

Production API (`https://data.nicenumbers.net`, PostgREST) **from ivory only**, read-only, light:
primary-key lookups, `field_id=eq.`, or bounded id ranges of at most 100,000 ids, 0.15 s apart,
`User-Agent: nice-audit-census`; never from the box. **Never claim from or submit to
production**; on the box map `api.`, `data.`, `www.nicenumbers.net` and `nicenumbers.net` to
127.0.0.1 and ::1 before any client runs and prove the block as `AUDIT.md` did. Your box is Vast
instance **60746721** (RTX 3080, 20 cores; `python3 vast.py ssh 60746721` from the program
directory; wait for `/root/READY`; it destroys itself at about 10:20 UTC). Never `vast.py create`
or `destroy`. ivory: writes only under `T28/`; `nice -n 19`; keep 5 GB of disk free; no GPU or
release builds on ivory. No pushes are needed; if you must push, only new branch names on the
fork, never force-push. No PR actions; no subagents; nothing on the fleet, the server,
`~/fleet-run`, demoux or mayalaran. Copy results from the box to ivory early and often.

## Deliver

`T28/RESULTS.md` (each task's answer first, then tables with every compared field, commands,
data paths; every number marked measured, derived or assumed), raw data and scripts under
`T28/raw/`. Hard stop **09:55 UTC**. Your final message is a short report for the program's
director: findings first (or "no mismatch in N comparisons"), then the release ratio, then the
base-62 estimate.

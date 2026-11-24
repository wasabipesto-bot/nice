# The middle-out local coordinator under failure (2026-11-24, 05:45–10:30 UTC)

Brief: `COORD/BRIEF.md`. Script under test: `scripts/midout_coordinator.py` on fork branch `dev/mo-clean`
(start `eb9ef776`), worktree `~/projects/nice/.worktrees/midout-clean`. Harness: `COORD/harness/`.

## 0. Where it stands

- **Nine defects in the coordinator as found; four of them could record a field as searched that was not** (a body for another field under a known claim id; a changed work list; two instances on one state
  directory; a claim id reused after a lost unsynced tail). Nine fixes, one commit each, plus the audit tool, on
  `dev/mo-clean` (`eb9ef776..66305ada`, pushed to `fork`; nothing to `origin`, no pull request). §3.
- **The fixed coordinator survived every randomized run** (§2.3: 4,950 runs with the audit: 3,000 + 1,500 ordinary, 300 stress, 150 in the per-commit table; 0 coordinator failures), the byte sweep (881 truncation
  offsets), eight smallest reproductions, and a 262,144-field work list at start (§2.2). Against the same seeds the
  original fails 140 of 150 runs, and each commit removes its own class of failure (§2.3 table).
- **The audit tool** (`scripts/midout_audit.py`) gave the same verdict as the harness's own file checker on every
  randomized run, of the fixed coordinator and of every earlier version (§6).
- **The client side** (read, not built): no case makes an unsearched field recorded; several make a searched field
  unrecorded or stop the client spuriously (a lost reply after acceptance, a reissue race, a coordinator down for
  more than the ~9-minute retry window); four changes proposed (§5).
- Not tested: real power loss, a remote coordinator, the real client, clock jumps, runs longer than seconds (§4).
- `just lint` was not run: it builds Rust (cargo clippy), which this task may not do; the repository has no Python
  lint (justfile and CI checked); both scripts pass `python3 -m py_compile`.

## 1. Invariants (written before any test, 05:50 UTC)

Terms. *Field* = one entry of the work list, identified by its whole entry (base, coordinate, range_start,
range_end, range_size), not by its index. *Acknowledged claim* = a claim body the coordinator sent with 200.
*Acknowledged submission* = a 200 "recorded" reply. *Durable* = on disk after `fsync`, i.e. survives a kill of
the process and a loss of power (the latter modelled, §2).

State files (at every moment, and after a kill at any point):

- **S1 readable.** `claims.jsonl` and `submissions.jsonl` are sequences of complete JSON lines, except possibly
  one torn last line (no final newline or unparsable), which is a record that was never acknowledged. A restart
  must treat it as absent (not refuse, not crash, not count it), and must not append a new record onto it.
  Any other unreadable line is a refusal to start, with its file and line number.
- **S2 acknowledged ⇒ durable.** Every acknowledged claim and every acknowledged submission is durable before
  the reply's first byte is sent (`flush` + `os.fsync` of the file before the reply).
- **S3 memory = disk.** The in-memory state never runs ahead of the disk: a record whose write failed (full
  disk, EFBIG, EIO) changes nothing in memory, leaves no partial line behind, and its request is answered with
  an error the client may retry (5xx), not with 200.
- **S4 restart = acknowledged state.** After a kill and restart, the reconstructed state (claims, last claim
  per field, accepted fields, next claim id) is exactly what the files hold; `/status` agrees with the files.
- **S5 claim ids unique, forever.** No claim id is issued twice, across restarts and across a lost tail.
- **S6 one instance.** A second coordinator on the same state directory refuses to start while the first
  lives (lock file); it does not append a byte.
- **S7 work list is fixed under history.** A restart with a work list in which a field that has a claim or a
  submission on record is changed, moved or missing is refused (no record is reinterpreted as another field).
  Appending new fields at the end is allowed. Duplicate or overlapping fields in one work list are refused.

HTTP behaviour:

- **H1 never twice.** A field is not handed out while a claim on it exists, across restarts, unless
  `--reissue-after S` is given and its latest claim is at least S seconds old; a field with an accepted
  submission is never handed out again.
- **H2 accepted at most once.** At most one accepted submission per field, ever (across restarts and instances).
- **H3 accepted only if legitimate.** A submission is accepted only for a claim id this coordinator issued and
  holds on disk, only with `telemetry.pipeline.route == "midout"`, and only if its body describes the claim's own
  field: `pipeline.coordinate`, `pipeline.field.base`, `v_start`, `v_size`, `range_size` equal the field's
  (a body for another base/range/coordinate is refused); the claim id is an integer, not a string, float or bool.
- **H4 no false "searched".** Nothing an ordinary (non-route) client can send, and no malformed, oversized,
  duplicate, late, reordered or cross-claim submission, makes a field accepted that was not reported searched
  by the holder of its own claim. A refused submission is never later counted as accepted.
- **H5 robust to junk.** Malformed JSON, wrong types, a missing/negative/non-numeric/huge Content-Length, or an
  oversized body get a 4xx with a reason, and the coordinator stays up and keeps serving.
- **H6 late submissions after a reissue.** If a field was reissued and the first holder submits first, that is
  accepted (it is a legitimate search of the field) and the second holder's later submission is refused 409; in
  no order is the field accepted twice.

End of run:

- **E1 nothing lost.** Every field of the work list is accepted exactly once or still open (unclaimed, or
  claimed and stale); none is accepted and none is "neither".
- **E2 coverage.** Once all are accepted, the accepted submissions' fields are exactly the work list.

How these are checked: §2 (harness), the audit tool (§6) checks S1, S4, S7, H2, H3, E1, E2 from the files alone.

## 2. The harness (`COORD/harness/`)

All standard-library Python; everything on 127.0.0.1 (ports picked free); run under `nice -n 19`; state under the
session scratch directory (`.../scratchpad/coord`), deleted per passing run; every coordinator it starts carries
`PR_SET_PDEATHSIG`, so nothing outlives the harness.

| file | what |
|---|---|
| `chaos.py` | the randomized harness (below). `--script PATH --runs N --seed S --jobs J [--audit PATH] [--stress] [--summary F]` |
| `trace_wrap.py` | runs the coordinator unchanged (`runpy`) and records, at each `os.fsync`, the file's size: the power-loss model |
| `repro/repro_*.py` | the smallest reproduction of each defect: `python3 repro_X.py [SCRIPT]`, exit 1 if the defect is present |
| `torn_sweep.py` | truncates each state file at every byte offset of its last record and restarts on it |
| `scale_test.py` | a 262,144-field work list with K accepted fields: start time, peak memory, latencies, the audit |
| `summarize.py` | the table and coverage of §2.3 from `--summary` files |
| `run_all.sh [SCRIPT] [AUDIT]` | all repros, 60 randomized runs and the byte sweep against one script |

### 2.1 One randomized run (seed = everything)

- A random work list: 2–24 base-64 fields `midout:4,8,5` at random t (one quantum, 2^57 v each, as
  `midout_fields` cuts them), sometimes one base-65 `midout:4,9,6` field; `--reissue-after` none (½ of runs) or
  0.15/0.3/0.6 s. `--stress`: 50–200 fields, 16–32 clients, reissue none or 0.01/0.03/0.08 s.
- 1–6 fake clients (threads) speaking the client's wire: `GET /claim/niceonly?coordinate=midout`, `POST /submit`
  with the body `client/src/midout_route.rs:280–306` builds (`DataToServer` with `telemetry.pipeline.{route,
  coordinate, field{base, v_start, v_size, t0, quanta, range_size}, join}`; field values as decimal strings, as
  the client sends them; checked against a real record of `G2/build5l/raw/final/e2e`). Each claim draws a
  behaviour: honest (think 0–30 ms), **die** between claim and submit, **dup** (submit twice), **late** (submit after
  1.2–2.5× the reissue time), **cross** (own field's body under another client's claim id), **wrongbody** (another
  field's body, another base, or another coordinate under its own claim), **route** (overlap/stride/no telemetry),
  **typeid** (claim id as string or float), **unknown** claim id, **junk** (not JSON; a JSON list; telemetry a list;
  pipeline a string; Content-Length −1, `abc`, 10^13, missing; a 2 MB otherwise valid body); then, except for
  *die* and *late*, the honest submission. A client retries a submission with no reply (or a 5xx) up to 60 times,
  as the real client retries (§5). Every request and reply goes into a ledger with a nonce per body.
- A chaos thread, 0–4 events at random moments in 0.6–2.5 s: **kill** (SIGKILL, restart); **power** (SIGKILL, then
  each file cut at a random byte between its last fsynced size and its size: the unsynced tail lost in part or
  whole); **tear** (SIGKILL, then a prefix of 1..all bytes of a record, without newline, appended: a write in
  flight); **fsize** (restart under `RLIMIT_FSIZE` = current size + 0–2.5 kB: a full disk); **diskfull**
  (`prlimit` on the running coordinator, + 0–0.9 kB); **worklist** (restart with fields with history swapped,
  edited, or the list cut short: must be refused; or a field appended: must start); **second** (a second
  coordinator on the same state directory: must refuse; if it starts, two claims and submissions go through it).
- Then the clients stop; the live `/status` is compared with the files; SIGKILL; restart with
  `--reissue-after 0`; `/status` compared again; one honest client drains to 204; SIGKILL.
- The checker (`Run.finish`) tests §1 from the files and the ledger: S1 (every line readable, no torn line left
  after the drain), S2 (every claim a client was told is in `claims.jsonl` with that field; every submission told
  "recorded" is accepted on disk under its claim), S3/S4 (`/status` = files, live and after restart), S5 (no claim
  id told for two fields, none twice on disk), S6, S7, H1 (no field under two claims without reissue; reissues
  ≥ `--reissue-after` apart on the coordinator's clock; no claim requested after a client was told the field's
  submission was recorded), H2, H3/H4 (every accepted record maps by nonce to an honest/dup/late body sent for that
  claim and that field; no other kind ever got 200), H5 (every junk request answered 4xx by a live coordinator; a
  503 only under a full disk; an oversized body may be cut off by the server's close), E1/E2 (after the drain every
  field accepted exactly once, nothing else). With `--audit`, the audit tool's exit status must match the checker's
  own independent file verdict (`file_verdict`). A failing run keeps its state, ledger and log (`fail-SEED/`).

### 2.2 The other tests

- **Byte sweep** (`torn_sweep.py`): 4 fields, 3 claims, 2 accepted; for every cut in [start of last record, end)
  of `claims.jsonl` (223 bytes) and `submissions.jsonl` (658): start, `/status` = the state without that record,
  one more claim, restart, read again; the audit must read it (exit 1, not 2). **881 offsets, all pass**; the
  original fails at the third offset (JSONDecodeError at start).
- **Scale** (`scale_test.py`, 262,144-field work list, 65,536 accepted, 103 MB of submissions): before the last
  fix the start peaked at 693 MB (linear: about 2.3 GB at the full base), now 156 MB (the work list alone); start
  2.1 s; claim ≤ 11 ms (the client's timeout is 5 s), submit ≤ 2 ms; the audit 2.6 s.
- **The recorded real runs**: the audit on every state directory of the client route's end-to-end runs
  (`G2/build4f`, `build4s`, `build5l`): the real client's bodies pass the new body check (OK on all five e2e
  states); the two hand-test states of `coordtest.sh` (bodies without `pipeline.field`) and round 1 (the
  first wire form, `"coordinate": "midout"`, work list without the key) are flagged, as they should be.

### 2.3 Runs and results

**Per commit** (`chaos.py --audit ... --runs 150 --seed 1000 --jobs 3`, the same 150 seeds against the script at
each commit; number of failing runs per invariant class; blank = 0; the AUDIT column, disagreement between the audit
tool and the checker, is 0 everywhere and left out):

| commit | runs | failed | S1 | S1/S4 | S2 | S3/S4 | S5 | S6 | S7 | H1 | H2 | H3 | H3/H4 | H4 | H5 | E1 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `eb9ef776` (as found) | 150 | 140 | 77 | 77 | 45 | 5 | 1 | 24 | 11 | 1 | 2 | 25 | 113 | 31 | 53 | 62 |
| `ccdc000d` torn line | 150 | 138 |  |  | 38 | 9 | 28 | 35 | 15 | 40 | 4 | 34 | 117 | 36 | 58 | 4 |
| `b69a2771` fsync | 150 | 131 |  |  |  | 8 | 1 | 33 | 14 | 1 | 2 | 2 | 118 | 35 | 58 | 2 |
| `d1736d2e` failed write | 150 | 133 |  |  |  | 2 | 1 | 33 | 14 | 1 | 2 | 2 | 120 | 37 | 54 | 2 |
| `249701e2` lock | 150 | 130 |  |  |  | 1 |  |  | 14 |  | 1 | 1 | 120 | 40 | 54 | 1 |
| `9dee6006` body check | 150 | 65 |  |  |  |  |  |  | 15 |  |  |  | 16 | 2 | 54 |  |
| `69112d8c` work list | 150 | 51 |  |  |  |  |  |  |  |  |  |  | 13 | 2 | 51 |  |
| `de863575` junk | 150 | 0 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `9b358676` log | 150 | 0 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `66305ada` streaming start | 150 | 0 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |

Reading it: once a torn line no longer stops the restarts (`ccdc000d`), the runs go further and show what the files
lost (S5/H1: claim ids reused and fields handed out twice after a lost unsynced tail), which `b69a2771` removes; the
remaining S3/S4/S5/H2 after `d1736d2e` are the second-instance runs, gone with the lock; H3/H3/H4 fall from ~120 to
~15 runs with the body check, the rest (an oversized 2 MB body accepted, an honest body read after a negative
Content-Length) go with `de863575`; S7 goes with `69112d8c`. Defect #8 (full log) cannot show here because the
harness pipes the log (it has its own repro); #9 is a measurement.

**The fixed coordinator** (`66305ada`), audit on every run:

| set | seeds | runs | failed | events exercised (runs) |
|---|---|---|---|---|
| ordinary | 100000..102999 | 3000 | 3, all a harness fault (below) | kill 794, power 815, tear 820, fsize 576, diskfull 636, second 620, work list 597 (swap 136, edit 134, shorten 99, append 277); 503 seen in 286, H6 (first holder accepted after a reissue) in 186 |
| ordinary, corrected harness | 110000..111499 | 1500 | 0 | kill 408, power 367, tear 413, fsize 283, diskfull 314, second 303, work list 294 (swap 62, edit 63, shorten 56, append 139); 503 in 141, H6 in 101 |
| stress (16–32 clients, 50–200 fields, reissue 0.01–0.08 s) | 200000..200299 | 300 | 0 | kill 77, power 89, tear 75, fsize 45, diskfull 45, second 66, work list 62; H6 in 216 runs |
| per-commit row above | 1000..1149 | 150 | 0 | |

183,532 + 93,763 (ordinary) and 228,378 (stress) claims, submissions and replies were checked. Every client kind ran in
hundreds of runs (ordinary: cross 1593, wrongbody 1598, dup 1880, late 1024, route 1216, typeid 1220, unknown 743,
each junk variant 244–278). The audit tool and the checker agreed on all 4,950 audited runs of the fixed coordinator
and on the 1,350 audited runs of the earlier versions.

The 3 failures of the first 3000 were the harness's: its *wrongbody* client, holding the base-65 field (already
`midout:4,9,6`), could pick "the same field with coordinate `midout:4,9,6`", i.e. its own field's correct body, and
the coordinator rightly accepted it. Fixed in `chaos.py` (only bodies for another field); the three seeds then pass,
and the 1,500 runs of the second row ran with the fix.

## 3. Defects (each: smallest reproduction, severity, fix commit)

Severity: **critical** = a field can be recorded as searched that was not; **high** = an acknowledged result can be
lost or the state misreported; **medium** = the coordinator stops or a client is told nothing; **low** = robustness.

| # | defect | smallest reproduction (`harness/repro/`) | before → after | severity | commit |
|---|---|---|---|---|---|
| 1 | a torn last line (kill or full disk mid-write) made every later start fail (`JSONDecodeError`); skipping it would have glued the next record onto it | `repro_torn_tail.py`: 1 claim, kill, append `{"claim_id": 1001, "fie`, restart, claim, kill, restart | exit 1 at start → cut off (logged), 3 claims on 3 fields; byte sweep 881/881 | medium (run stops; hand repair of the file is where fields get lost) | `ccdc000d` |
| 2 | no `fsync` before a reply: a power loss after "recorded" loses an accepted submission; a lost claims tail lets the next start reuse a claim id for another field, and the old holder's submission is then accepted for that field | `repro_no_fsync.py` (under `trace_wrap.py`): claim, submit; durable bytes at reply time | claims 0/59, submissions 0/659 durable → all | **critical** (with #5 open: id reuse records the wrong field) | `b69a2771` |
| 3 | a write that fails (full disk) after memory was changed: no reply, `/status` counts the field done, retries refused 409, a partial line left (then #1) | `repro_write_failure.py`: `RLIMIT_FSIZE` 400 B, claim, submit | no reply, done 1, partial line, restart fails → 503, done 0, file unchanged, accepted after restart | high (a searched field's result lost, the status lies) | `d1736d2e` |
| 4 | two coordinators on one state directory both start, hand out the same field under the same claim id, and append to the same files | `repro_two_instances.py` | both up, both claim 1000 on t=1 → second exits ("DIR/lock is held") | **critical** (a field accepted twice; a submission recorded under the other instance's claim) | `249701e2` |
| 5 | a submission was accepted for any known claim id whatever field its body describes; `int()` coerced `"1000"` and `1000.25` | `repro_cross_claim.py`: field 2's body under field 1's claim; string id; other coordinate | 200, 200, 200 → 422, 400, 422 | **critical** (a field never searched recorded as searched) | `9dee6006` |
| 6 | records named fields by index only: a restart with a reordered, edited or shortened work list reinterpreted every record | `repro_worklist_change.py`: 2 fields, field 0 accepted, restart with the list reversed | started, done 1 on the never-searched field, the searched one handed out again → refused, naming the record | **critical** | `69112d8c` |
| 7 | malformed requests: Content-Length −1 read until the client gave up (then an honest body was accepted unseen); `abc`, 10^13, telemetry a list: exception, no reply; any body size recorded | `repro_junk.py` | no reply ×4, 409 → 400, 400, 413, 422, 413; still serving | low (no false record; one silent acceptance) | `de863575` |
| 8 | a full disk under the log (stderr to a file): the log write in `send_response` raised after the record was durable: a recorded claim and an accepted submission both unanswered | `repro_log_full.py`: `prlimit` the running process to the log's size, claim, submit | no reply, no reply (both on disk) → 200, 200 | medium (a stuck claim; a client that stops though its field is recorded) | `9b358676` |
| 9 | the start read each state file whole and kept every claim record | `scale_test.py ... 65536` | 693 MB peak (about 2.3 GB at 262,144 fields) → 156 MB | low (operational) | `66305ada` |

Also on the branch: `6d14c9e6`, the audit tool (§6). Found by the harness only after the first fixes: #8 (the
fsize event failed to start the coordinator because its log hit the limit first; the harness now pipes the log,
and #8 has its own repro). Not changed, noted: `--reissue-after` accepts a negative value (every claim reissued at
once); a work list may mix two coordinates of one base whose fields overlap in n (the coordinator cannot compare
them; `--coordinate ID` prevents it); a refused claim (the client's `field_of`) leaves its field claimed (§5).

What the fixed script does, in one paragraph: the work list is checked for overlaps; an exclusive `flock` on
`DIR/lock`; each state file is read line by line, a torn last line cut off, every record checked to still name
its field at its index (claims now carry the field's value), duplicate claim ids and double acceptances refused;
every record is written with `os.write` + `fsync` before memory changes and before the reply, and a failed write is
cut back and answered 503; a submission needs an integer claim id this coordinator holds, the route marker, and a
`pipeline` that names the claim's field; Content-Length 0..1 MiB. 164 → 295 lines (most of the growth is docstrings and refusal messages), standard library only.

## 4. Not tested, and what still could fail

- **Real power loss.** The model (`trace_wrap.py` + the *power* event) drops unsynced bytes of the two state files
  at any byte; it does not model a disk or filesystem that acknowledges `fsync` without persisting, the loss of a
  directory entry after start (the start fsyncs the directory once), or a torn write *inside* the synced prefix.
  `ext4`/`xfs` behaviour under real power cuts was not tried.
- **A remote coordinator** (only 127.0.0.1; the script binds 127.0.0.1 by design), proxies, TLS, IPv6.
- **The real client**: nothing was built or run; its side is read (§5). The fake clients reproduce its wire bodies
  and its retry behaviour approximately (60 retries without backoff, not 10 with 1–256 s backoff).
- **Clock jumps.** Reissue uses wall-clock `time.time()` stored in `claims.jsonl`; a clock stepped back delays
  reissues, stepped forward makes them early. Not tested.
- **Long runs.** Each randomized run lasts seconds; two months, 262,144 fields and multi-GB files were only
  approximated by the scale test (start, latency) — not a long run with restarts.
- Other I/O errors than EFBIG (EIO, ENOSPC on `fsync`, a read-only remount), NFS (`flock` semantics), SIGSTOP of the
  coordinator, more than 32 concurrent clients, HTTP keep-alive and pipelining (the server speaks HTTP/1.0 and
  closes), the `--legacy-path` test switch, `--coordinate`.
- **What remains by design:** a claim whose reply is lost after it was made durable leaves its field claimed with
  nobody working on it (the client never learns the id); without `--reissue-after` such a field, and the field of
  every client that dies or refuses a claim, stays "claimed" for ever. Nothing is lost (the audit lists them as
  stale) but the base is not finished until the coordinator is restarted with `--reissue-after`. Recommendation:
  run with `--reissue-after` of a few times the field time (base 64: ~31 s per field; e.g. 600). Late submissions
  after a reissue are accepted once (H6 held in every run), so a reissue costs at most a duplicated search.
- The overlap check compares fields of one (base, coordinate) only; two coordinates of one base cover the same n in
  different shapes and cannot be compared without the coordinate's arithmetic.

## 5. The client side (`client/src/midout_route.rs`, read at `66305ada`; nothing built)

How it talks: `claim()` (`midout_route.rs:68–92`) is **one** GET with the shared client's 5 s timeout
(`midout_route.rs:210–214`, `CLIENT_REQUEST_TIMEOUT_SECS = 5`, `common/src/lib.rs:53`): 204 → done; any other
non-2xx, a timeout or a connection error → `Err`, the process exits non-zero. Then `field_of` (`:96–130`) checks the
claim, the search runs, and only an `Ok` search with no recorded panic is submitted (`:259–271`). The body's
`claim_id`, `pipeline.coordinate` and `pipeline.field` all come from the same claim `c` (`:280–306`), so the client
cannot send a body for another field under a claim. `submit_field_to_server_async`
(`common/src/client_api_async.rs:146–171`) retries timeouts, connection and request errors and 5xx up to
`--api-max-retries` (default 10, `client/src/main.rs:251`) with backoff 1, 2, … 256 s (`client_api_async.rs:39–97`:
about 8.5 min plus the timeouts); **any 4xx is an error at once**, and the `?` at `midout_route.rs:307–312` ends the
process non-zero. Nothing of a searched field is kept except the info log line (`:295–298`: survivors, checked,
slices, nice numbers).

| case | what happens | searched field unrecorded? | unsearched field recorded? |
|---|---|---|---|
| submission refused (400/404/409/413/422) | error, exit non-zero, `--repeat` stops | **yes**: the result is only in the log; the field stays claimed (open again only by `--reissue-after`) | no |
| reply lost after the coordinator accepted (timeout > 5 s, connection cut) | retry → 409 "already submitted (claim *own id*)" → error, exit non-zero | no (it is recorded) — but the client stops as if it failed | no |
| reply lost on a claim the coordinator recorded | error at once (no retry on claims), exit | the field is claimed by nobody until `--reissue-after` | no |
| coordinator down at claim time | connection error, exit at once | — | no |
| coordinator down during submit | retries for ~9 min; back in time → accepted (claims are durable since `b69a2771`); not back → exit | **yes** if down longer than the retry window | no |
| coordinator restarts mid-field (state intact) | the submission is accepted after the restart | no | no |
| coordinator restarts after a power loss (before `b69a2771`) | the claim may be gone (404: result lost) or its id reused for another field, and the body then accepted for that field | yes | **yes before `9dee6006`** (now 422) |
| coordinator full disk (now) | submit 503 → retried ~9 min → exit if still full | yes if the disk stays full | no |
| claim reissued under it, it submits first | accepted; the second holder gets 409 and exits non-zero | no | no |
| claim reissued under it, the other submits first | 409 → error, exit non-zero, its search wasted | no (the field is recorded once) | no |
| it refuses a claim (`field_of`: unknown coordinate, base, size) | exit non-zero, the field stays claimed; under a supervisor that restarts it, each restart claims and abandons another field | no (stale, not lost) | no |

No case makes an unsearched field recorded with the fixed coordinator: the client submits only after a passing
search, its body is built from its own claim, and the coordinator now refuses a body that names another field.

Changes I would make (not made):

1. `midout_route.rs:307–312`: submit through a route-local function that reads the status instead of the shared
   `submit_field_to_server_async` (which turns every 4xx into an opaque string, `client_api_async.rs:157–166`): a 409
   naming **this** claim id ("already submitted (claim N)") is success (a lost reply); a 409 naming another claim is
   "done by someone else": log and go on to the next claim instead of exiting.
2. `midout_route.rs:299–306`: before submitting, write the `DataToServer` as JSON to a spool file named by claim id
   (fsynced), remove it on 200 or own-409, and resubmit any spooled file at the start of `drive` (`:221`): a searched
   field is then not lost when the coordinator is down past the retry window, full, or refusing.
3. `midout_route.rs:68–92`: retry a claim on connection errors, timeouts and 5xx with the same backoff as submit
   (`retry_request_async` is private in `client_api_async.rs:39`; a short loop in the route suffices). A lost claim
   reply still cannot be recovered by the client: that needs `--reissue-after` on the coordinator, or a wire change
   (a client-chosen claim key so that a repeated claim returns the same field) — a design decision.
4. `midout_route.rs:227`: when `field_of` refuses a claim, log its claim id and the field as "abandoned (claimed,
   not searched)" so an operator can reissue it; and do not let a supervisor loop turn every restart into another
   abandoned claim (exit with a distinct status for "refused a claim" vs "transient").

## 6. The audit tool

    python3 scripts/midout_audit.py --worklist work.json --state ./mo-state [--stale SECONDS] [--quiet]

Read only; safe beside a running coordinator (a record being written shows as a torn last line and is ignored).
Prints: fields accepted / open (never claimed) / claimed (latest claim younger than `--stale`, default 3600 s) /
stale (with their indices); claims on record and refused submissions by reason; coverage; nice numbers reported in
accepted submissions (and, separately, in refused ones); notes (torn last line, older claim records without the
field's value); then each PROBLEM: a field accepted more than once, an accepted submission whose claim is not on
record or is another field's, whose body is not the route's, has a non-integer claim id or describes another field,
a record whose field is not the work list's at that index, a claim id recorded twice. Exit status 0 only if every
field of the work list is accepted exactly once and there is no problem; 1 otherwise; 2 if a line other than a torn
last one does not read.

It agreed with the harness's own file verdict (`chaos.py:file_verdict`, written separately) on every randomized run
of §2.3 that ran it — for the fixed coordinator and for each earlier version, whose states are full of the defects
above — and read every byte-sweep state (exit 1, never 2). On the recorded end-to-end runs: OK on the five e2e
states of `G2/build4f` (rounds 2, merge), `build4s`, `build5l` (p1b, final).

## 7. Notes on the harness itself

Harness faults found and fixed during the session (none in the coordinator): the coordinator's log went to a file
under the same RLIMIT_FSIZE, so the *fsize* event first only exercised "cannot log at start" (now piped; the
in-operation case became defect #8); the first "claimed after acceptance" check compared `recv` (taken before the
lock) with claim times and was replaced by a causal check on the clients' clock; a 2 MB body refused by its
Content-Length can be cut off by the server's close before the 413 is read (accepted as a refusal); a 503 under a
full disk is the documented answer; the *wrongbody* artefact of §2.3. `run_all.sh` re-ran everything at the end
(07:30 UTC): 8/8 repros ok, 60/60 runs, 882/882 byte offsets.
Run state lived under `/tmp/claude-1000/.../scratchpad/coord` and was removed; nothing is left running.

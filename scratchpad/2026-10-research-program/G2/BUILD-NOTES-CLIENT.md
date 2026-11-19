# The middle-out join, step 4F: a client route against a local coordinator (2026-11-19, 05:46–11:30 UTC)

Brief: `G2/BUILD-BRIEF-4F.md` (rules of `BUILD-BRIEF-1.md`). Branch **`dev/mo-client`** (from the trunk
`dev/middle-out-join` at `4abfab5c`), worktree `~/projects/nice/.worktrees/midout-client`, pushed to the fork only.
Box: Vast 61386517, RTX 3080 10 GB at its host's 240 W cap, 16 threads visible, CUDA 12.8 image; production hosts
mapped to 127.0.0.1 and ::1 before any client binary ran (`build4f/raw/round1/proof_hosts_block.txt`; every run
script re-checks the block and aborts if a production host answers, proof per run in `runs/*/hosts_proof.txt`).
Scripts `G2/build4f/box/`, raw logs `G2/build4f/raw/` (`round1/`: the first wire form; `round2/`: the explicit
coordinate id; `merge/`: after the trunk merge).

## 1. Where it stands

__STATUS__

## 2. How to run it (one machine)

Build (the route needs a CubeCL backend; the test switch is a separate feature, never in a release):

    cargo build --release -p nice_client --features cubecl-cuda            # -> target/release/nice_client
    cargo build --release -p nice_common --example midout_fields           # the work-list cutter (no GPU)

A work list (cut by the library's own coordinate; `--spread N` = N fields evenly over the base, `--t` explicit
first quanta, `--quanta Q` fields of Q quanta):

    target/release/examples/midout_fields --base 64 --spread 24 > w64.json
    target/release/examples/midout_fields --base 65 --t 13731,77777 > w65.json
    python3 -c 'import json,sys; print(json.dumps(sum((json.load(open(f)) for f in sys.argv[1:]), [])))' w64.json w65.json > work.json

The coordinator (standard library only, binds 127.0.0.1; state in a directory, resumable):

    python3 scripts/midout_coordinator.py --worklist work.json --state ./mo-state --port 8471
        [--coordinate midout:4,9,6]   # refuse to start unless every field is in this coordinate
        [--reissue-after SECONDS]     # hand out again a claim this old without an accepted submission (default: never)
        [--legacy-path]               # TEST ONLY: also hand the marked fields to /claim/niceonly and /claim/detailed

The client (runs until the coordinator has no field left with `--repeat`, else one field):

    target/release/nice_client niceonly --midout-coordinator http://127.0.0.1:8471 --repeat --username NAME
        [--gpu-backend cubecl-cuda|cubecl] [--gpu-device N]

The flag is the one switch, and its only place is `Cli::midout_coordinator` (`client/src/main.rs`) and
`client/src/midout_route.rs`. It has no environment variable on purpose (nothing turns it on by accident; the fleet
configures by environment, so this is a decision for the owner). The mode positional is ignored, as are `--api-base`
and `--telemetry` (the route always attaches its telemetry); `--validate` and `--benchmark` are refused with it.
Records: `mo-state/claims.jsonl` (every claim), `mo-state/submissions.jsonl` (every submission, accepted or not:
field, claim time, receive time, whole body); `GET /status` gives counts.

## 3. The wire additions (all named in `common/src/midout/wire.rs`)

| | production | the middle-out route |
|---|---|---|
| claim | `GET /claim/niceonly` | `GET /claim/niceonly?coordinate=midout` |
| claim body | `{claim_id, base, range_start, range_end, range_size}` | the same plus **`"coordinate": "midout:K0,K1,Q0"`**; `range_start`/`range_end` = `v_start`/`v_start + v_size`; `range_size` = the n the field holds (`Coord::n_count`; = v_size at b64, less at b65 by its padding) |
| no work | (server-specific) | `204 No Content` |
| submit | `POST /submit`, `DataToServer` | unchanged; `telemetry.pipeline.route = "midout"` |

That is one query parameter, one claim key and one telemetry value. No type of production's changes (`DataToClient`
is built by the API, so a new field there would have been a server change; the route parses its own `CoordClaim`).

**The coordinate is named explicitly** (changed mid-step after the field-structure review, `G2/fs/REVIEW.md` §1):
the id `midout:K0,K1,Q0` gives the coordinate's digit positions (digits `[K0, K1)` go on top of v, a field fixes
digits `[Q0, K1)`); base 64 today is `midout:4,9,6` (fields fix digits 6–8). The client parses the id, builds its
`Coord` with `Coord::with_digits(base, K0, K1, Q0)` and refuses it unless it equals the coordinate its device path
for that base was built for (`Coord::for_base`); `midout::route::FieldJoin::search` takes that `Coord` and refuses
any other. The coordinator knows nothing of what an id means: each work-list field carries its own coordinate and is
passed through. The review's proposal (digits 5–7, `(4, 8, 5)`) is expressible by `midout::coord`
(`Coord::with_digits(64, 4, 8, 5)` builds, and `midout_fields --digits 4,8,5` cuts such a work list), but the join
does not search it: `Shape::for_coord` returns `(k0, k1 + 1)` = (4, 9) for it, not (4, 10), and the device paths
were never run on it, so today's client refuses `midout:4,8,5` (unit test `claims_are_checked_before_work`, and the
negative run `unknowncoord` below). Adopting it would need `Shape::for_coord` to return (4, 10) for it, `coord_digits`
to name it for base 64, and the parity tests on it; no field or wire change beyond the id.

## 4. The guards and their tests

| guard | where | unit test | negative run on the box (nothing submitted in any) |
|---|---|---|---|
| refuses the production API | `wire::check_coordinator_url` (first thing `midout_route::run` does; the address is the flag's value, there is no default) | `wire::production_hosts_are_refused` (7 production spellings refused incl. upper case, trailing dot, port, user; 5 non-addresses refused; loopback, `[::1]`, `notnicenumbers.net` allowed); client `refuses_the_production_api` (through `run`) | `prod`: `https://api.nicenumbers.net`, `http://API.nicenumbers.net.:8471`, `https://nicenumbers.net/`: rc 1 each, "refusing the production API (api.nicenumbers.net)" |
| every other route refuses a coordinate-space field | `client_api_async::get_field_from_server_async` (the claim of every ordinary route, both modes) calls `wire::refuse_coordinate_space`: any value of the `coordinate` key is refused before the body is parsed | `wire::coordinate_marker`; `client_api_async::ordinary_claims_refuse_a_coordinate_field` (a loopback server; niceonly and detailed refused, a plain claim still parsed) | `legacy` (coordinator `--legacy-path`): `niceonly --gpu` (overlap join/stride), `niceonly --threads 4` (CPU), `detailed --threads 4`, `detailed --gpu`: rc 1 each, "refusing a field of the 'midout:4,9,6' coordinate", 0 submissions. `plain404`: an ordinary client against a normal coordinator gets 404, rc 1 |
| the claim is one this client can search | `midout_route::field_of`: the id parses, the base has a device path, the coordinate built from the id equals `Coord::for_base`, whole quanta (`field_digits`), `range_size` = `n_count` | client `claims_are_checked_before_work` (other coordinate, unknown ids incl. `midout:4,8,5`, misaligned, part of a quantum, wrong `range_size`, past the end, base 65's padded count, base 62) | `misaligned` (range_start + 1), `badsize` (range_size − 1), `unknowncoord` (`midout:4,8,5`): rc 1, 0 submissions |
| a failed account is not submitted | `FieldJoin::search` returns the library's error; the route logs "NOT submitted", exits non-zero | (the library's own fault tests) | `accounts` (`NICE_MIDOUT_FAULT=accounts`, `F_SKIP_MAIN`): rc 1, "main-kernel job instances done: 0, want 8064" |
| a failed sampled CPU check is not submitted | same (sampled check on at base 64) | (library) | `sample` (`F_PF_DROP`, accounts pass): rc 1, "sampled CPU check of slice …: the field run counted … checked 337523, CPU … checked 337802" |
| a runtime-thread panic: nothing more is submitted | `midout_route::install_panic_hook` (process-wide, installed by the route only, after the device context is up; records every panic, then runs the previous hook); checked after each field and before each claim | — (a process-wide hook in a unit test would catch the harness's own panics) | `panic` (a thread named `midout-test-fault` panics during the field; the field itself completes and passes its accounts): rc 1, "a thread of this process panicked (thread 'midout-test-fault' …): nothing more is submitted" |
| memory hog | (the accounts and the hook together) | — | `hog` (`hog 2100`: 7,549 MiB held, card at 7.8 GB before the client; the release binary, no switch): CubeCL's stream thread `DSD-0-0` panics (`server.rs:124`), the hook records it, and the accounts fail first: "expansion ran 0 of 4096 cubes, walked 0 of 0 slabs"; rc 1, 0 submissions |
| the coordinator's own rules | `scripts/midout_coordinator.py` | — | `coordtest.sh` (`runs/r*/coord/out.txt`): plain claim path 404; three claims, a restart, the third field next (never twice); 204 when none left; route `overlap` or no telemetry → 422; one accepted, the same again → 409; unknown claim → 404; `--reissue-after 0` reissues the unsubmitted field |

The test switch `NICE_MIDOUT_FAULT` exists only in a build with the `midout-fault` feature (`nice_mo_fault`); the
release-feature binary (`nice_mo`) carries no such string (`strings` count 0, `logs/b*/bins.txt`), and the `hog`,
`prod`, `legacy`, `misaligned`, `badsize` and `unknowncoord` runs used it. Every negative run ran twice (round 1 with
the first wire form `"coordinate": "midout"`, round 2 with the id) and again after the trunk merge (`merge/`); all
identical in outcome.

## 5. End to end

__E2E__

## 6. The route's cost

__COST__

## 7. Default client unchanged

__DEFAULT__

## 8. What the real server would need to do the coordinator's job (a list, no code)

1. **Hand out middle-out fields only to clients that ask**: the claim path's `?coordinate=midout` (or a separate
   path), a queue of its own for those fields, and **every legacy claim path excluding them** (PROPOSAL §2's
   `BaseFilter`: today any client claiming `/claim/niceonly` would be handed a base-64 v-field and, if released before
   this branch, search it as n). The coordinator's 404 for the plain path is that exclusion.
2. **Store which coordinate a field is in**: a field row needs the coordinate id (`midout:4,9,6`) or a per-base rule
   that says "base 64 is coordinate X"; the claim response then carries it (the one new key). A re-cut of the
   coordinate (the review's 5–7) is a new id, never a reinterpretation of old rows.
3. **Insert the fields**: 262,144 rows of 2^57 at base 64 in v (`range_start` = v_start), `range_size` = n count
   (`Coord::n_count`, the coordinator gets it from `midout_fields`), which keeps every sum of sizes right.
4. **Check the submission's route**: reject a submission for a middle-out field whose telemetry route is not
   `midout` (the coordinator answers 422); accept one submission per field (409).
5. **Claim expiry**: production's 1 h expiry is fine (a field is 31 s at b64, 56 s at b65 on a capped 3080); the
   coordinator never reissues by default, `--reissue-after` is the same rule.
6. **Nice numbers**: submitted as real n (as today); the server's expansion and notable-number caches need no change.
   It could check each n lies in the field (v of n in range), which the library already checks before submitting.
7. **Interval queries** on base 64 (`get_count_checked_by_range` etc.) become wrong for sub-intervals of n (PROPOSAL
   §2); progress is "fraction of fields", and the site's chart caption for b64 says so.
8. **Audit**: the submission carries survivors, checked, slices, the sampled slice and its result, the shape and the
   build; an audit job can recompute random slices with the CPU reference (PROPOSAL §6) keyed on route `midout`.
9. **Backfill** of what a private coordinator searched: each accepted record in `submissions.jsonl` is one field's
   submission (claim id, username, version, nice numbers, telemetry), the same rows option A would have produced.

## 9. What is not done

__NOTDONE__

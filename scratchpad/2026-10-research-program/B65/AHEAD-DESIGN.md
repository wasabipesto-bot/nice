# Keeping the card fed between groups of slices: design note (the director, 2026-11-28)

Not built. A plan, its price, and a cheaper measurement to make first. It extends the engineer's note of
2026-11-26 (`B65/READS-RESULTS.md`, "Step 2"). Sources: the drivers at `dev/mo-mode` `f503a13c` (`run_field_wide`,
`finish_group`, `queue_slice` in `common/src/midout/gpu_wide.rs`; `search_field_groups`, `finish_group`,
`queue_dev` in `gpu.rs`); CubeCL 0.10.0's source (`cubecl-wgpu/src/compute/stream.rs`, `server.rs`;
`cubecl-runtime/src/client.rs`), read today; `B65/RESULTS.md` §3; `G2/window_1125/`.

## What happens today

Both drivers run a field as a loop over groups of 16 slices [read in the code]:

1. queue the group's launches, slice by slice (per slice about 10 small uploads, 9 allocations, 12–15 launches);
2. `sync`: wait until the device has finished everything queued;
3. read the group's small result buffers in one batched read (both paths since 2026-11-26), check the accounts;
4. go to 1 for the next group.

What the runtime does with that through Vulkan and Metal [read in CubeCL's source today]:

- **Launches are submitted to the card every 32 launches** (`CUBECL_WGPU_MAX_TASKS`, default 32; the project
  does not change it for this path), that is about every two slices, and at every read and `sync`. So inside a
  group the card works while the host queues the rest. I had assumed a whole group waits for the `sync`: wrong.
- **The card is idle once per group**, from the end of the group's work until the first 32 launches of the next
  group are submitted: the wake-up after the `sync`, the read and its wake-up, the host's checks, and the
  queueing of about two slices.
- **A read is issued when it is called**, not when it is awaited: `read_async` records the copies, submits, and
  asks for the mapping at once; the future only waits for the mapping. Work queued after the call does not
  delay it. This is the ordering the change below needs. (The engineer found the same for CUDA, where the read
  records a fence.)
- **A throttle:** after every 512 submitted launches the runtime blocks the host until the submission of 512
  launches earlier has finished. Two groups (about 480 launches) fit under it; a deeper look-ahead would not.

## What the idle gap costs

| card, path | host quiet | host busy | source |
|---|---|---|---|
| RTX 3060, Vulkan, base 65 (wide) | at most 0.6 % | at most 3 % (six busy threads) | measured 2026-11-26: the field against a run with no reads |
| RTX 3060, Vulkan, base 64 (narrow) | about 1 % | 4.9 % (six busy threads) | measured (busy); quiet judged from the card reading 97 % busy |
| RTX 3060, CUDA, either base | at most 0.5 % | at most 0.5 % | measured: the card is 99–100 % busy |
| RX 9070 XT, Vulkan, base 64 (narrow) | 1–2 % | **6–10 % slower with the desktop in use** | quiet: arithmetic (one read and two slices of queueing per 69 ms group); in use: measured 2026-11-25, cause not established |
| RX 9070 XT, Vulkan, base 65 (wide) | about 0.6 % | not measured since the read fix | arithmetic |

- **On a quiet host there is nothing to win** (about 1 %).
- **Under a busy host there is 3–5 % on the RTX 3060**, and the mechanism is plausible: with every core busy,
  each hand-off between the client's thread and the runtime's threads waits for a scheduler slice (several
  milliseconds), and there are a few per group.
- **The case that matters is your RX 9070 XT while the desktop is in use** (6–10 % on 2026-11-25; production's
  join, one long launch per batch, did not move). Whether those 6–10 % are the gap between groups is not known.
  The card's clock was lower on the narrow path than on production's join in that session (2.85–2.93 GHz
  against 3.10–3.13); a gap of 1–2 % of the time seems too small to cause that [judged], so I no longer count
  a clock effect as likely.

## A measurement to make before any code

The number of gaps per field is inversely proportional to the group size, and the group size is already an
argument of the benchmark (`--group`). So **a sweep of the group size prices the whole idea without a line of
code:** if the loss under a busy host is the gap, group 64 removes three quarters of it.

- **eventeo, today, after the hooks work is in** (`EXPERIMENTS.md` B65.8): base 64 narrow and base 65 wide
  through Vulkan on the RTX 3060; group 16, 64 (and 256 for base 64 if memory allows); host quiet and with six
  busy threads; one warm-up field then one timed field each.
- **Decision rule, written beforehand.** If group 64 recovers at least half of the loss under load at base 64:
  the gap is the cause; then (a) propose a larger default group for the narrow path if its memory allows (one
  constant), and (b) the look-ahead below is worth building for the wide path, whose group cannot grow
  (a slice's lists are tens of megabytes). If it recovers less than a quarter: the loss is somewhere else (the
  queueing itself, or the uploads), this design is dropped, and the next question is where.
- **demoux, when a window is granted:** the same sweep at base 64 with the desktop in use, with the card's
  clock logged. That is the measurement this design finally stands or falls on.

## The change, if the sweep says yes

Queue group k + 1 before waiting for group k:

```
queue(G1)
for k in 1..:
    r_k = read_async(G_k's buffers)      # issued now: copies recorded and submitted behind G_k's launches
    queue(G_{k+1})                       # the card goes from G_k straight into G_{k+1}
    check(await r_k)                     # the host waits for G_k only
```

- **`finish_group`'s `sync` goes** (it would wait for group k + 1 as well); the batched read does its job.
- **Buffers.** The buffers the host reads (`cnt`; per ticket `scount`, `ran`, `stat`, `tstat`, `est`; per slice
  `acc`, `l5n`) are fresh handles per group or slice already. The device scratch that is reused from slice to
  slice (the records, lists, slab counts, survivor list, histograms) is reused in queue order, as between two
  slices of one group today. The sampled slice's counts come from the same read: unaffected.
- **Memory.** Two groups of per-slice buffers alive at once instead of one. To be measured: base 64 on the 3 GB
  card, base 65 on a 12 GB and a 16 GB card.
- **Failure.** With a group ahead, group k + 1 is already running when group k's check fails. The field fails
  either way and nothing of it is returned or submitted (the client's stop rule), so soundness does not depend
  on what happens next; but the join object is reused for the next field, and group k + 1 still writes the
  shared scratch and the tally of nice numbers. The error path must therefore wait for the device to drain
  before it returns.
- **Unchanged:** the timing stops and the single-slice entry points (`run_slice`, the tests' helpers) keep the
  synchronous form; every group's accounts are checked as now, one group later; a field's result is returned
  only after the last group's checks, as now.
- **Size:** 40–60 lines per path, in the field loop and its error path.

## How to know it worked

1. Counts and every fault message identical; the fault tests with a fault in the first, a middle and the last
   group of a field (the error names the right slice; the join is usable afterwards and the next field's counts
   are right).
2. RTX 3060 through Vulkan, both paths, quiet and with six busy threads: the loss under load gone (within 1 % of
   quiet); nothing lost on a quiet host or through CUDA.
3. The RX 9070 XT, when a window is granted: base 64 and base 65 with the desktop in use, before and after.

**Kill criterion:** less than half of the loss under load recovered on the RTX 3060 through Vulkan → not merged.

## Order of work

The sweep first (today). Then, only on a yes: the narrow path first (base 64 runs first and holds 73 % of the
reachable odds: `EXPERIMENTS.md` YIELD.2), then the wide path with the same shape, one commit each, the tests of
point 1 before any timing.

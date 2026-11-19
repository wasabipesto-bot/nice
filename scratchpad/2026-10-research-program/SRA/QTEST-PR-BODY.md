### The problem

`cubecl_queues_check_every_survivor_on_partly_filled_planes` forces both forms of the stride path's survivor queue, ballot and scan, on every wgpu device. Production chooses per device with `ballot_append(plane_size_max)`: the ballot form only where a plane has at most 32 lanes, because the kernel reads one 32-bit ballot word. On a device with 64-lane planes the test therefore runs a form the client never selects there, and fails.

Seen on an RX 9070 XT (Mesa RADV, 64-lane planes) running the ignored device tests with `--features cubecl-spirv`: of 64 runs, all 32 forced-ballot runs fail the queue's account (`the survivor queues checked -38 fewer survivors than they queued`, and similar), and all 32 scan runs are exact (30449 of 30449 survivors).

### The change

Test only. The test forces the ballot form only where `ballot_append` allows it, the rule the join's wgpu tests already use, and prints a line when it leaves the form out. No production code changes; no changelog entry.

### Tested

- RX 9070 XT (RADV), `cubecl-spirv`: 32 runs, 0 wrong; the test passes, and `cubecl_dropped_launches_fail_the_field` passes beside it.
- LAVAPIPE_LINE
- `just lint` passes.

### What a wgpu device should expect

Nothing changes for the client. On devices with planes of at most 32 lanes the test runs both forms as before; on wider ones it now tests the form the client runs there.

Not included: with the ballot form forced on a 64-lane device, the cube-scoped queue could in principle also leave candidates out without failing its account. The client cannot select that form on such a device (the override exists only in test builds), so this is a property of the forced test configuration, not of a release.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

# Independent review of the base-65 kernel changes before they join the main development branch (brief, 2026-11-27 09:00 UTC)

You are an independent reviewer of GPU kernel and driver code (Rust, CubeCL). You did not write this code. Work
alone (do not start subagents), on this machine (ivory), **reading only: change nothing, build nothing, push
nothing, comment nowhere.** **Hard stop 10:45 UTC.**

## What you review

The "nice" project is a distributed exhaustive search: a result is the statement that a range holds no solution,
so **the one unforgivable failure is a kernel or driver that silently loses a candidate** (a field reported as
searched and empty when part of it was not examined). Its redesigned search join, the middle-out join, has a
"wide" device path for bases 65–70 in `common/src/midout/gpu_wide.rs` (about 5,000 lines; the narrow path it
mirrors is `gpu.rs`; the exact CPU reference is `cpu.rs`; the design, if a term is unclear:
`~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §2, §4, §6.9).

Under review: fork branch **`dev/mo-wide-b65`**, three commits on `0b6e22e1`
(`git -C ~/projects/nice log --oneline 0b6e22e1..a7ea3890`; `git diff 0b6e22e1 a7ea3890`; read by hash, the
worktrees move):
- `8f8ab3c1`: the wide slice test now compares the device's tops with the reference's;
- `19be987c`: the tops stage lists certified tops compactly (`wtops1` appends to a list with a ballot and one
  atomic per plane; `wtops2` places one 32-byte record per top; `wtdigz` unpacks);
- `a7ea3890`: the bottom side's parent lists shared across a slice digit (`wanc_kernel` and the field driver; a
  port of the narrow path's `anc8_kernel`), with a new fault `F_SKIP_ANC` and a new test.
The author's write-up: `~/projects/nice/scratchpad/2026-10-research-program/B65/LEVERS-RESULTS.md` (what was
measured and tested, on an RTX 3060 through CUDA and through Vulkan). Assume nothing from it.

## What to try to break (rank findings: a candidate can be lost silently / a failure is not loud / robustness /
quality)

1. **Plane assumptions in the new compact append.** The author says `wtops1`'s grid-stride loop "runs whole cubes
   per round so every ballot has all lanes active". On Vulkan a plane may have fewer active lanes than the
   reported width, and an earlier defect in this project came from exactly that assumption (a kernel that
   handed out entries by lane position skipped the missing lanes' entries without any counter noticing). Read
   the append (the ballot, the rank, the atomic, what a lane writes where) and decide: on a plane with some
   lanes inactive, or with lanes that finish their loop in different rounds, can a certified top be dropped,
   duplicated or written over another? What in the accounts (`A_*` words, `check_slice`) would notice?
2. **Capacities.** The compact list and the placed records have caps (`caps.tops`); the shared parent lists have
   a capacity of 3/8 of the roots per list. For each: what happens at overflow (a count beyond the cap must fail
   the field loudly, never truncate)? Is every such count read back and checked on every path, including the
   timing-stop and the shared/unshared variants?
3. **Stale data between slices.** The write-up says the old `wtops2` "placed stale flags left over from the
   previous slice" under an injected fault. With the new records and lists: is any buffer reused across slices,
   groups or fields whose stale contents could be read as valid when a kernel does less than expected (a skipped
   launch, a failed allocation, a short list)? Would the accounts catch each case?
4. **The parent sharing.** "Exact by containment (digits 0..k − 3 of r², r³ depend only on r mod b^(k−2))": check
   the claim and the code's use of it (the ancestor's validity test, the list's keying by the slice digits, the
   clipped first and last slices of a range, the padded coordinate at base 65). Is a list built for one field
   ever used for another field or another coordinate? Does `whist`'s account still prove that every listed root
   was examined? Is the new fault `F_SKIP_ANC` loud by an account, or only by the sampled check?
5. **The sampled CPU check's independence:** the write-up says the check's device rerun stays unshared. Confirm
   that the production path's sampled check compares the shared path's result with something that does not go
   through the shared lists.
6. **The tests:** does `wide_field_parent_sharing_is_exact_and_loud` compare shared against unshared slice by
   slice on real data, at base 65 and with the range's clipped ends? Does the slice test's new tops comparison
   really compare contents (not counts)? What changed in the fault tests' expectations (one account dump differs:
   is the explanation in the write-up right)?
7. Anything in the diff that changes behaviour at base 64 through the wide path, or for bases 66–70 (not run
   since), that the author does not mention.

## Deliverable (by 10:45 UTC)

`~/projects/nice/scratchpad/2026-10-research-program/B65/LEVERS-REVIEW.md`: verdict in the first three lines (merge
as is / merge with fixes (list) / hold), then the findings ranked, each with file and line at `a7ea3890`, the
scenario, and the smallest fix or test you would accept; what you read; what you could not judge by reading and
what run would settle it. A final report to me of at most 15 lines. If the tooling denies something, do not work
around it: note it.

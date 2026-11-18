# cubecl-spirv: two `break`s in a `loop`, plus a value live after the loop, give an unstructured `OpBranchConditional`

**Versions:**
- cubecl 0.10.0 (cubecl-core, cubecl-opt, cubecl-spirv and cubecl-wgpu 0.10.0), wgpu 29.0.4, Rust 1.100.0, Linux x86_64.
- **Device:** lavapipe from Mesa 26.0.8 (Ubuntu 26.04 package `mesa-vulkan-drivers 26.0.8-1ubuntu0.3`, LLVM 21.1.8).
- **Validator:** `spirv-val` from the Ubuntu 26.04 `spirv-tools` package.
- **Compilers:** the `spirv` (direct SPIR-V) compiler of `cubecl-wgpu` is affected. The WGSL compiler is not.

## Summary

A `loop` with **two or more `if … { break; }` exits** and **a variable that is updated in the loop and read after
it** compiles to a SPIR-V module in which each `if … { break; }` is an `OpBranchConditional` **without an
`OpSelectionMerge`**. Its "then" target is not the loop's merge block: it is an empty block inserted on the edge to
it. The module is invalid ("Selection must be structured").

wgpu does not report the shader at all. The first sign is a validation error on the **next buffer write**:

```
wgpu error: Validation Error
Caused by:
  In Queue::write_buffer
    Buffer with '' label is invalid
```

## Minimal kernel

```rust
use cubecl::prelude::*;

#[cube(launch_unchecked)]
fn repro(out: &mut Array<u32>, n: u32) {
    let mut rounds = 0u32;
    loop {
        if rounds > n {
            break;
        }
        rounds += 1u32;
        if rounds == 3u32 {
            break;
        }
    }
    out[0usize] = rounds;
}
```

- **Launch:** one cube of one unit on `WgpuRuntime`, `n = 8`, `out` = 8 words of 99.
- **WGSL compiler:** `out[0] = 3`, as expected.
- **`spirv` compiler:** the launch panics in the device thread with the `write_buffer` error above, and the next
  `client.sync()` returns `Err` (`CallError`).

**What triggers it** (each row is a variant of the kernel above, run on lavapipe with both compilers and the `spirv`
module checked with `spirv-val --target-env vulkan1.3 --scalar-block-layout`):

| variant | `spirv` module | runs |
|---|---|---|
| the kernel above: two `if … { break; }`, `rounds` read after the loop | **invalid** | no ("Buffer invalid") |
| one `break` only, `rounds` read after the loop | valid | yes |
| two `break`s, the value stored inside the loop and not read after it | valid | yes |
| two `break`s and a value read after the loop, with an inner `while` before the first `break` | **invalid** | no |
| a larger kernel: inner `while` with `&&`, `min`, a `for` loop, two `break`s, counter read after the loop | **invalid** | no |
| the same with any one of the `for` loop, the `&&` or the `min` removed | **invalid** | no |
| the same with the read after the loop removed | valid | yes |
| the two exits merged into one: `if rounds > n \|\| rounds == 3 { break; }` | valid | yes |
| no `loop`/`break`: `let mut going = true; while going { … going = false; … }` | valid | yes |

WGSL gives the expected result in every row.

## The invalid module

`spirv-val --target-env vulkan1.3 --scalar-block-layout repro.spv`:

```
error: line 52: Selection must be structured
  OpBranchConditional %26 %28 %29
```

Disassembly (`spirv-dis --raw-id`), the loop:

```
               OpLoopMerge %20 %19 None
               OpBranch %18
         %18 = OpLabel
         %26 = OpUGreaterThan %27 %25 %24
               OpBranchConditional %26 %28 %29      ; no OpSelectionMerge
         %28 = OpLabel                               ; empty edge block
               OpBranch %20
         %20 = OpLabel                               ; loop merge
         %30 = OpPhi %1 %34 %33 %25 %28
         %32 = OpAccessChain %31 %5 %21 %21
               OpStore %32 %30
               OpReturn
         %29 = OpLabel
         %34 = OpIAdd %1 %25 %11
         %36 = OpIEqual %27 %34 %35
               OpBranchConditional %36 %33 %37      ; no OpSelectionMerge
         %33 = OpLabel                               ; empty edge block
               OpBranch %20
         %37 = OpLabel
               OpBranch %19
         %19 = OpLabel
               OpBranch %17
```

The optimizer's IR (`CUBECL_DEBUG_SPIRV` with the `cubecl/spirv-dump` feature writes it next to the module) shows
the same thing before SPIR-V emission:

```
bb3 {
    binding(1) = local(0).v2 > scalar<u32>(0) : (u32, u32) -> (bool);
    binding(1) ? bb5 : bb6; merge: None
}
bb4 {
    Uses: [Merge]
    local(0).v4 = phi [bb7: local(0).v3][bb5: local(0).v2];
    output(0)[u32(0)] = local(0).v4 ...
}
bb5 {
    branch bb4;
}
```

**The driver's message.** In a larger kernel with the same shape, lavapipe's `spirv_to_nir` printed this through
wgpu's debug messenger (`RUST_LOG=warn`):

```
SPIR-V parsing FAILED:
    An OpSelectionMerge instruction is required to precede an OpBranchConditional instruction that has different
    True Label and False Label operands where neither are declared merge blocks or Continue Targets.
```

followed by `spirv_to_nir failed (VK_ERROR_UNKNOWN)`. The minimal kernel gave only the `write_buffer` error.

## Cause (as far as I can see)

- **`cubecl-opt/src/control_flow.rs`, `parse_if`:** when the `if` body ends in `Branch::Break`, the `IfElse`
  control flow gets `merge: None`. The body block is linked straight to the loop's break target (`Branch::Break` →
  `add_edge(current_block, loop_break)`).
- **`cubecl-spirv/src/branch.rs`, `compile_if_else`:** with `merge == None` it emits `OpBranchConditional` without
  `OpSelectionMerge`. That is only valid while the "then" target is itself the loop's merge block (or a continue
  target).
- **`cubecl-opt/src/control_flow.rs`, `split_critical_edges`:** this runs afterwards. With two breaks the loop's
  merge block has more than one predecessor, and the block ending in `if … { break; }` has two successors, so the
  edge to the merge block is critical and gets a new empty block. The `IfElse`'s "then" target becomes that block
  (`update_control_flow`), which is not a merge block, and `merge` is still `None`.
- When no value is live after the loop, the merge block needs no `OpPhi`, and the edge blocks apparently do not
  survive into the module, so the module validates. With a value live after the loop, the `OpPhi` in the merge
  block keeps them.

## Possible fixes

Either of these, untested:

- Give a `break`ing `if` a selection merge: its `or_else`/`next` block (exiting the selection to the enclosing
  loop's merge is allowed).
- Do not split edges into a loop's merge block that come from a `merge: None` break branch. The `OpPhi` can name the
  breaking block itself as its predecessor.

## Workarounds

- Merge the exits into one `break`.
- Or write the loop as `while going { … }` with a flag and no `break`.
- Test SPIR-V kernels on lavapipe with `RUST_LOG=warn`, and run `spirv-val` on the modules (`CUBECL_DEBUG_SPIRV`):
  the wgpu error alone does not point at the shader.

---

## Two CUDA code-generation effects seen in a larger kernel (not reduced)

Both were seen on an RTX 3080 (CUDA 12.8, driver JIT through cubecl-cuda / cubecl-cpp 0.10.0), in a 2,000-line
`#[cube]` kernel. Timings are the medians of 200 launches, wall clock around launch and sync. **I have not reduced
either to a small kernel, so this is an observation, not a report.**

**1. A semantically neutral change made the kernel about 45 % slower.**
- **The change:** each cube built a 4-word table in shared memory from a global array of `u64` masks (20 unrolled
  `trailing_zeros` per entry). The new form copies the 4 words from a global `u32` array that a separate kernel
  pre-computed. The table contents are identical (checked word for word, and the kernel's output was identical).
- **Effect:** the kernel's main loop, which only reads that table from shared memory, went from 6.00 ms to 8.80 ms.
  That was reproducible over many processes and two builds of the same source, switched by a comptime flag.
- The phase that writes the table is not the slow one: a mode without the main loop got slightly faster.
- The generated CUDA C++ compiled offline with `nvcc -Xptxas -v` shows the same register count (48) and no spills
  in both forms.

**2. Shared-array placement changed timings between builds by about 25 %.**
- **What changed between builds:** builds that differed only in comptime-dead code or host code placed the kernel's
  `SharedMemory` arrays at different byte offsets in the generated `dynamic_shared_mem`. The placement order is not
  the declaration order. Some arrays of `u32` that are read as 4-word runs lost their 16-byte alignment.
- **Effect:** the kernel's time took one of a few quantized values (5.8 / 7.2 / 8.8 / 10.2 ms) depending on the
  build, and in one build on the process.
- **Padding removed the variance:** padding every shared array to a multiple of 128 bytes (several were 4 or 64
  bytes long) made the timing stable to ±0.1 % over four processes.
- It did not undo effect 1, which is independent of placement.
- A way for users to request alignment of shared arrays, or a placement that keeps every array aligned to its
  natural vector width, would avoid this.
Repro source: `loop_break_repro.rs` (variant 19 is the minimal kernel; 23 and 24 are the workarounds).

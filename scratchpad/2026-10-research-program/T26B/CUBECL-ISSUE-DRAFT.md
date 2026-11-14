# cubecl-opt: `MergeSameExpressions` deletes atomic stores of the same value to different atomics in one block

**Versions:** cubecl 0.10.0 (cubecl-opt 0.10.0, cubecl-spirv 0.10.0, cubecl-wgpu 0.10.0), wgpu 29, Rust 1.100.0.
Seen with the `spirv` (direct SPIR-V) compiler of `cubecl-wgpu` on lavapipe (Mesa 26.0.8 and 25.2.8). The WGSL and
CUDA compilers, which do not run cubecl-opt, are not affected.

## Summary

Within one basic block, `atomic.store(v)` instructions after the first that store the **same value operand** `v`
(the same constant or the same SSA value) are dropped, whatever atomic they target: other indices of the same
array, another shared array, or a global array. Only the first store reaches the module.

## Minimal kernel

```rust
use cubecl::prelude::*;

#[cube(launch_unchecked)]
fn repro(out: &mut Array<u32>) {
    let s = SharedMemory::<Atomic<u32>>::new(4usize);
    if UNIT_POS_X == 0u32 {
        // Distinct values: all four stores are kept.
        s[0].store(1u32);
        s[1].store(2u32);
        s[2].store(3u32);
        s[3].store(4u32);
    }
    sync_cube();
    if UNIT_POS_X == 0u32 {
        // The same value: only the first store is kept.
        s[0].store(7u32);
        s[1].store(7u32);
        s[2].store(7u32);
        s[3].store(7u32);
    }
    sync_cube();
    if UNIT_POS_X == 0u32 {
        out[0] = s[0].load();
        out[1] = s[1].load();
        out[2] = s[2].load();
        out[3] = s[3].load();
    }
}
```

Launched with one cube of 64 units on `WgpuRuntime` with the `spirv` compiler: **`out = [7, 2, 3, 4]`**. Expected
`[7, 7, 7, 7]`, which the WGSL compiler gives.

Module (cubecl-spirv), the second block, abridged: one store instead of four.

```
%c7 = OpConstant %u32 7
...
%p0 = OpInBoundsAccessChain %ptr_wg_u32 %shared0 %c0 %c0
OpAtomicStore %p0 %scope_wg %semantics %c7
OpBranch %merge
```

WGSL compiler, same kernel: four `atomicStore(&shared_0[i], 7u)`, i = 0..3.

Variants measured on the device (same harness, words pre-set to distinct values in an earlier block):

| second block | `spirv` result | WGSL result |
|---|---|---|
| `s[0..4].store(7)` | only `s[0]` written | all four |
| `s[0].store(7); t[0].store(7)` (two shared arrays) | `t[0]` not written | both |
| `let v = val + UNIT_POS_X; s[0].store(v); s[1].store(v)` (runtime value) | `s[1]` not written | both |
| `s[0].store(7); g[0].store(7)` (`g: &mut Array<Atomic<u32>>`, global) | `g[0]` not written | both |
| `g[0].store(7); g[1].store(7)` (global) | `g[1]` not written | both |
| `#[unroll] for k in 0..4 { s[k].store(7) }` | only `s[0]` | all four |
| the two stores in separate `if` blocks | both | both |
| plain `p[0] = 7; p[1] = 7` on `SharedMemory<u32>` | both | both |
| `s[0].fetch_add(1); s[1].fetch_add(1)`, `s[0].swap(7); s[1].swap(7)`, `s[0].fetch_add(1)` twice | all kept | all kept |

## Cause

`MergeSameExpressions` (`cubecl-opt/src/passes/expression_merge.rs`, `check_op`) replaces a later instruction in the
same block by `Operation::Copy(earlier.out)` when `op.operation == later.operation` and the outputs have the same
type, provided every operand and the output are immutable (`Variable::is_immutable`).

`Atomic::store` (`cubecl-core/src/frontend/element/atomic.rs`) is registered as
`Instruction::new(AtomicOp::Store(UnaryOperator { input: value }), ptr)`: its **target is the instruction's `out`**,
and the `operation` holds only the value. The target pointer is the result of an `Index` instruction, a
`Versioned`/`LocalConst` local, so it is immutable, and two stores of one value to different atomics compare equal.
The later store becomes `ptr_b = Copy(ptr_a)`, which `EliminateUnusedVariables` then removes. (The other atomic
operations carry the pointer inside `operation` (`BinaryOperator { lhs: ptr, .. }`), and each source-level index
produces a fresh local, so they are not merged in practice.)

The pass is in the post-SSA pipeline that `cubecl-spirv` runs (`Optimizer::apply_post_ssa_passes`); it does not run
for the WGSL or C++ compilers, which is why only the SPIR-V path is affected.

## Suggested fix

Exclude instructions whose `out` is a destination rather than a result from the merge, e.g. in `check_op`:

```rust
if matches!(op.operation, Operation::Atomic(_)) {
    return None;
}
```

(or at least `AtomicOp::Store`; merging other atomics is unsound anyway, since each one is a memory operation, not
a pure expression).

## Impact

Silent: the kernel compiles and runs, and the dropped atomics keep whatever the memory held (uninitialised
workgroup memory in the common "clear a few counters" pattern). Workaround: store at a non-constant index from
different units, or put the stores in different blocks.

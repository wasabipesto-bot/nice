# Metal shader compiler miscompiles unsigned division/modulo by a non‑power‑of‑two constant when the dividend is a half‑word right shift or a 64‑bit multiply‑high

**Area:** Metal / shader compiler (the Metal GPUCompiler that backs `MTLDevice.makeLibrary(source:)`)

**Device:** Apple M4 (integrated GPU)

**OS:** macOS 26.3, Build 25D125

**Toolchain:** System Metal compiler, no Xcode project — MSL is compiled at runtime via `MTLDevice.makeLibrary(source:options:)`, exactly as in the attached reproducer. A related run on the same OS build reported Metal GPUCompiler version `32023.864` in a compiler diagnostic; no other toolchain version was pinned.

## Description

For a 32‑bit unsigned value `x`, computing `(x >> 16u) / K` or `(x >> 16u) % K` for a compile‑time, non‑power‑of‑two constant `K` returns the wrong result on the GPU. The same happens when the dividend is instead the high 32 bits of a 64‑bit product, `uint(ulong(a) * ulong(b) >> 32) / K`. The wrong value is usually the quotient of the *low* 16 bits of `x` by `K` (`(x & 0xFFFFu) / K`), but not always: for `K = 12167`, dividend `0` incorrectly returns `4` — neither the correct quotient nor the low‑16 one (both `0`).

The bug reproduces for a bare `(x >> 16u) % K`, and for `(x >> 16u) / K` wrapped in the divide‑by‑zero guard that WGSL‑to‑MSL translators emit for every division, called `naga_div` below:

```metal
uint naga_div(uint lhs, uint rhs) { return lhs / metal::select(rhs, 1u, rhs == 0u); }
```

It does **not** reproduce for a bare, unguarded `(x >> 16u) / K` applied to a value loaded directly from a buffer; it does reproduce again once that same shifted value is instead produced by a 64‑bit multiply‑high, or once the division goes through the guard above. Shifts by other amounts (1, 8, 15, 17, 24), a mask (`x & 0xFFFFu`), an OR of two shifts, a power‑of‑two divisor (32768), and a run‑time divisor are all correct in every form tried.

Trace of the first wrong value in a long‑division routine that hit this pattern (chunk 0, top limb, quotient `q1 = (0 << 16 | top >> 16) / K`):

| base | K | dividend | quotient returned | correct quotient |
|---|---|---|---|---|
| 23 | 12167 | 0 | 4 | 0 |
| 27 | 19683 | 0 | 2 | 0 |
| 28 | 21952 | 9 | 2 | 0 |
| 50 | 2500 | 0 | 3 | 0 |

Counts from the standalone reproducer below, over 4,096 lanes (0–1023 plus 3,072 xorshift‑generated words), `K = 3` unless noted:

| expression | wrong lanes |
|---|---|
| `naga_div(x >> 16u, 3u)` (the guarded form above) | 4093 / 4096 |
| `(x >> 16u) % 3u` | 4093 / 4096 |
| `naga_div(x >> 16u, 12167u)` | 2542 / 4096 |
| `uint(ulong(x) * ulong(x ^ 0x9E3779B9u) >> 32) / 3u` (multiply‑high, no shift) | 4095 / 4096 |
| `(x >> 16u) / 3u` (bare, unguarded, loaded value) | 0 / 4096 |
| `(x >> 15u) / 3u`, `(x >> 8u) / 3u`, `(x >> 24u) / 3u` | 0 / 4096 |
| `(x & 0xFFFFu) / 3u`, OR form, power‑of‑two divisor, run‑time divisor | 0 / 4096 |

## Steps to Reproduce

Run the Swift program below on an Apple Silicon Mac (original filename `shr_div_repro.swift`):

```
swift shr_div_repro.swift
```

It builds a small Metal library at runtime from hand‑written MSL (no Xcode, no WebGPU/wgpu, no shader translator of any kind), dispatches one compute kernel per test expression over 4,096 unsigned‑integer lanes, and compares the GPU's output against the same arithmetic computed on the CPU.

```swift
// Apple Metal miscompile: an unsigned division by a constant of a value that
// is a logical right shift, `(x >> s) / K`, gives wrong quotients.
//
// Run: swift shr_div_repro.swift   (or swiftc -O shr_div_repro.swift && ./shr_div_repro)
//
// Each kernel computes one expression per input word; the GPU result is
// checked against the same arithmetic on the CPU.
import Foundation
import Metal

// (name, MSL expression in x (uint) and k (runtime uint), CPU model)
let cases: [(String, String, (UInt32, UInt32) -> UInt32)] = [
    ("shr16_div3",        "(x >> 16u) / 3u",                         { x, _ in (x >> 16) / 3 }),
    ("shr16_div1000",     "(x >> 16u) / 1000u",                      { x, _ in (x >> 16) / 1000 }),
    ("shr16_div2500",     "(x >> 16u) / 2500u",                      { x, _ in (x >> 16) / 2500 }),
    ("shr16_div12167",    "(x >> 16u) / 12167u",                     { x, _ in (x >> 16) / 12167 }),
    ("shr1_div3",         "(x >> 1u) / 3u",                          { x, _ in (x >> 1) / 3 }),
    ("shr8_div3",         "(x >> 8u) / 3u",                          { x, _ in (x >> 8) / 3 }),
    ("shr24_div3",        "(x >> 24u) / 3u",                         { x, _ in (x >> 24) / 3 }),
    ("shr16_mod3",        "(x >> 16u) % 3u",                         { x, _ in (x >> 16) % 3 }),
    ("naga_guard_div3",   "naga_div(x >> 16u, 3u)",                  { x, _ in (x >> 16) / 3 }),
    ("hi_mul_div3",       "uint(ulong(x) * ulong(x ^ 0x9E3779B9u) >> 32) / 3u",
                          { x, _ in UInt32((UInt64(x) * UInt64(x ^ 0x9E37_79B9)) >> 32) / 3 }),
    ("naga_guard_hi_mul", "naga_div(uint(ulong(x) * ulong(x ^ 0x9E3779B9u) >> 32), 3u)",
                          { x, _ in UInt32((UInt64(x) * UInt64(x ^ 0x9E37_79B9)) >> 32) / 3 }),
    ("inline_select_div3", "(x >> 16u) / select(3u, 1u, 3u == 0u)",  { x, _ in (x >> 16) / 3 }),
    ("naga_guard_shr8",   "naga_div(x >> 8u, 3u)",                   { x, _ in (x >> 8) / 3 }),
    ("naga_guard_shr15",  "naga_div(x >> 15u, 3u)",                  { x, _ in (x >> 15) / 3 }),
    ("naga_guard_shr17",  "naga_div(x >> 17u, 3u)",                  { x, _ in (x >> 17) / 3 }),
    ("naga_guard_shr24",  "naga_div(x >> 24u, 3u)",                  { x, _ in (x >> 24) / 3 }),
    ("naga_guard_shr16_12167", "naga_div(x >> 16u, 12167u)",         { x, _ in (x >> 16) / 12167 }),
    ("naga_guard_or",     "naga_div((x >> 16u) | (x << 20u), 3u)",   { x, _ in ((x >> 16) | (x << 20)) / 3 }),
    ("naga_guard_and",    "naga_div(x & 0xFFFFu, 3u)",               { x, _ in (x & 0xFFFF) / 3 }),
    ("naga_guard_pow2",   "naga_div(x >> 16u, 4u)",                  { x, _ in (x >> 16) / 4 }),
    ("hi_mul_shr16_div3", "(uint(ulong(x) * ulong(x ^ 0x9E3779B9u) >> 32) >> 16u) / 3u",
                          { x, _ in (UInt32((UInt64(x) * UInt64(x ^ 0x9E37_79B9)) >> 32) >> 16) / 3 }),
    ("ushort_hi_div3",    "uint(ushort(x >> 16u) / ushort(3))",      { x, _ in (x >> 16) / 3 }),
    // controls
    ("ctl_and_div3",      "(x & 0xFFFFu) / 3u",                      { x, _ in (x & 0xFFFF) / 3 }),
    ("ctl_plain_div3",    "x / 3u",                                  { x, _ in x / 3 }),
    ("ctl_shr16_div4",    "(x >> 16u) / 4u",                         { x, _ in (x >> 16) / 4 }),
    ("ctl_shr16_divrt",   "(x >> 16u) / k",                          { x, k in (x >> 16) / k }),
    ("ctl_or_div3",       "((x >> 16u) | (x << 20u)) / 3u",          { x, _ in ((x >> 16) | (x << 20)) / 3 }),
]

var source = """
#include <metal_stdlib>
using namespace metal;
uint naga_div(uint lhs, uint rhs) { return lhs / metal::select(rhs, 1u, rhs == 0u); }

"""
for (name, expr, _) in cases {
    source += """
    kernel void \(name)(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                        constant uint& k [[buffer(2)]], uint gid [[thread_position_in_grid]]) {
        uint x = in[gid];
        out[gid] = \(expr);
    }

    """
}

let device = MTLCreateSystemDefaultDevice()!
let queue = device.makeCommandQueue()!
let library = try! device.makeLibrary(source: source, options: MTLCompileOptions())
print("\(device.name), macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")

// Inputs: 0..1023, then xorshift words.
var input = [UInt32](0..<1024)
var z: UInt32 = 0x1234_5678
for _ in 0..<3072 { z ^= z << 13; z ^= z >> 17; z ^= z << 5; input.append(z) }
let n = input.count
let inBuf = device.makeBuffer(bytes: input, length: n * 4, options: .storageModeShared)!
var k: UInt32 = 3

for (name, _, want) in cases {
    let pso = try! device.makeComputePipelineState(function: library.makeFunction(name: name)!)
    let outBuf = device.makeBuffer(length: n * 4, options: .storageModeShared)!
    let cb = queue.makeCommandBuffer()!
    let enc = cb.makeComputeCommandEncoder()!
    enc.setComputePipelineState(pso)
    enc.setBuffer(inBuf, offset: 0, index: 0)
    enc.setBuffer(outBuf, offset: 0, index: 1)
    enc.setBytes(&k, length: 4, index: 2)
    enc.dispatchThreads(MTLSize(width: n, height: 1, depth: 1),
                        threadsPerThreadgroup: MTLSize(width: 64, height: 1, depth: 1))
    enc.endEncoding()
    cb.commit()
    cb.waitUntilCompleted()
    let out = outBuf.contents().bindMemory(to: UInt32.self, capacity: n)
    var wrong = 0
    var examples: [String] = []
    for i in 0..<n {
        let w = want(input[i], k)
        if out[i] != w {
            wrong += 1
            if examples.count < 3 { examples.append("x=\(input[i]): got \(out[i]), want \(w)") }
        }
    }
    let note = wrong > 0 ? "  e.g. " + examples.joined(separator: "; ") : ""
    print("\(name.padding(toLength: 23, withPad: " ", startingAt: 0)) \(wrong) of \(n) wrong\(note)")
}
```

**Expected:** every line prints `0 of 4096 wrong`.

**Actual**, on the device/OS above:

```
Apple M4, macOS Version 26.3 (Build 25D125)
shr16_div3              0 of 4096 wrong
shr16_div1000           0 of 4096 wrong
shr16_div2500           0 of 4096 wrong
shr16_div12167          0 of 4096 wrong
shr1_div3               0 of 4096 wrong
shr8_div3               0 of 4096 wrong
shr24_div3              0 of 4096 wrong
shr16_mod3              4093 of 4096 wrong  e.g. x=3: got 65533, want 0
naga_guard_div3         4093 of 4096 wrong  e.g. x=3: got 1, want 0
hi_mul_div3             4095 of 4096 wrong  e.g. x=1: got 884811922, want 0
naga_guard_hi_mul       4095 of 4096 wrong  e.g. x=1: got 884811922, want 0
inline_select_div3      0 of 4096 wrong
naga_guard_shr8         0 of 4096 wrong
naga_guard_shr15        0 of 4096 wrong
naga_guard_shr17        0 of 4096 wrong
naga_guard_shr24        0 of 4096 wrong
naga_guard_shr16_12167  2542 of 4096 wrong  e.g. x=3: got 4, want 0
naga_guard_or           0 of 4096 wrong
naga_guard_and          0 of 4096 wrong
naga_guard_pow2         0 of 4096 wrong
hi_mul_shr16_div3       4091 of 4096 wrong  e.g. x=5: got 1, want 0
ushort_hi_div3          0 of 4096 wrong
ctl_and_div3            0 of 4096 wrong
ctl_plain_div3          0 of 4096 wrong
ctl_shr16_div4          0 of 4096 wrong
ctl_shr16_divrt         0 of 4096 wrong
ctl_or_div3             0 of 4096 wrong
```

## Impact

Found through an open‑source distributed‑computing project searching for square‑cube pandigital ("nice") numbers, whose GPU kernels are written once in WGSL and run on Apple GPUs both through WebGPU (`wgpu`, translating WGSL to MSL via `naga`) and through a native Metal backend. A kernel converting a 64‑bit product to base‑`b` digits by schoolbook long division hit this pattern at its first step: each chunk's first division has remainder exactly 0, so its dividend is a bare `top_limb >> 16`. On an Apple M4 this gave the wrong unique‑digit count for most inputs at several bases (up to 77% of candidates at the start of one base's range, 87% at another), with no obvious signature: the wrong counts are close to uniformly distributed, so histograms over 100,000+‑candidate windows drifted only a few percent and largely passed. Per‑candidate verification against a reference CPU implementation caught it.

**Workaround.** The project rewrote the affected routine to operate entirely in 16‑bit limbs, so every division's dividend is built as `remainder << 16 | next_limb` rather than a bare shift of a wider product or sum — removing the triggering shape at no runtime cost.

**Not Apple‑specific logic bug.** The identical WGSL source, and the identical native‑MSL kernel, are correct on NVIDIA GPUs (CUDA), on `lavapipe` (software Vulkan), and on a macOS CI runner's paravirtual Metal GPU (macOS 26.6.2) — only real Apple‑silicon GPU hardware on macOS 26.3 (and whatever range of OS/driver builds share this compiler path) was observed to mis‑execute it.

## Notes

`naga`'s WGSL‑to‑MSL translation was checked by hand and is correct: `naga` always emits the guarded form `lhs / metal::select(rhs, 1u, rhs == 0u)` shown above for a WGSL `a / b`, exactly matching the WGSL source. Feeding that same hand‑written MSL straight to `MTLDevice.makeLibrary(source:)` — bypassing WebGPU, `wgpu` and `naga` entirely — reproduces the identical wrong results, placing the defect in Apple's Metal shader compiler itself, not in any translator.

The triggering shape — take the high half of a wider value via a right shift (or a 64‑bit multiply‑high), then divide or take the remainder of that half by a run‑time, non‑power‑of‑two constant — is exactly the first step of a classic chunked/schoolbook long‑division routine, a common idiom in big‑integer, hashing, and bit‑packing compute shaders. This is likely to affect other Metal compute code beyond the one project that found it.

// H2 check for the FD seed's Metal failure (2026-10-30): does Apple's Metal
// compiler divide the LOW 16 bits of x when asked for (x >> 16) / K, with x the
// high word of a 64-bit product? (The 2026-10-06 finding, mulhi_div_repro.swift,
// is the 32-bit analogue: uint(p >> 32) / K divides the low word.)
//
// Run on the Mac: swift h2_repro.swift      (not compiled on Linux; written
// from the 10-06 harness, same structure)
//
// Each kernel writes q = (its dividend) / K. The CPU checks q and says whether
// a wrong q equals the same division of the low 16 bits ("low16").
import Foundation
import Metal

let source = """
#include <metal_stdlib>
using namespace metal;

// naga's MSL guard, exactly as naga 29 emits it for WGSL `a / b` on u32.
uint naga_div(uint lhs, uint rhs) { return lhs / metal::select(rhs, 1u, rhs == 0u); }

// 1. The FD seed's case at one limb (bases 27-30): x = hi(n*n), q1 = (x >> 16) / K.
kernel void prod_hi16_div(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                          uint gid [[thread_position_in_grid]]) {
    uint a = in[4 * gid];
    ulong p = ulong(a) * ulong(a);
    uint x = uint(p >> 32);
    out[gid] = (x >> 16) / 21952u;
}

// 2. As 1, through naga's guard (what the WGSL path compiles).
kernel void prod_hi16_div_guarded(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                                  uint gid [[thread_position_in_grid]]) {
    uint a = in[4 * gid];
    ulong p = ulong(a) * ulong(a);
    uint x = uint(p >> 32);
    uint rem = 0u;
    out[gid] = naga_div((rem << 16u) | (x >> 16u), 21952u);
}

// 3. The two-limb case (bases 49-55): x = hi(a*b + c + d), the square's top word.
kernel void sum_hi16_div(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                         uint gid [[thread_position_in_grid]]) {
    uint a = in[4 * gid], c = in[4 * gid + 2], d = in[4 * gid + 3];
    ulong p = ulong(a) * ulong(a) + ulong(c) + ulong(d);
    uint x = uint(p >> 32);
    out[gid] = naga_div((0u << 16u) | (x >> 16u), 2500u);
}

// 4. Control: x loaded from memory, no product.
kernel void loaded_hi16_div(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                            uint gid [[thread_position_in_grid]]) {
    uint x = in[4 * gid + 1];
    out[gid] = naga_div(x >> 16u, 21952u);
}

// 5. Control: a power-of-two divisor (base 32's 32768).
kernel void prod_hi16_div_pow2(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                               uint gid [[thread_position_in_grid]]) {
    uint a = in[4 * gid];
    ulong p = ulong(a) * ulong(a);
    uint x = uint(p >> 32);
    out[gid] = (x >> 16) / 32768u;
}

// 6. Control: the divisor at run time.
kernel void prod_hi16_div_runtime(device const uint* in [[buffer(0)]], device uint* out [[buffer(1)]],
                                  constant uint& k [[buffer(2)]], uint gid [[thread_position_in_grid]]) {
    uint a = in[4 * gid];
    ulong p = ulong(a) * ulong(a);
    uint x = uint(p >> 32);
    out[gid] = (x >> 16) / k;
}
"""

func sq_hi(_ a: UInt32) -> UInt32 { UInt32((UInt64(a) * UInt64(a)) >> 32) }
func sum_hi(_ a: UInt32, _ c: UInt32, _ d: UInt32) -> UInt32 {
    UInt32((UInt64(a) * UInt64(a) + UInt64(c) + UInt64(d)) >> 32)
}
let device = MTLCreateSystemDefaultDevice()!
let queue = device.makeCommandQueue()!
let library = try! device.makeLibrary(source: source, options: MTLCompileOptions())
print("\(device.name), macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")

var rng = SystemRandomNumberGenerator()
let n = 4096
var input = [UInt32]()
for _ in 0..<n {
    input.append(UInt32.random(in: 1 << 24 ... UInt32.max, using: &rng))  // a: hi(a*a) >= 2^16
    input.append(UInt32.random(in: 0 ... UInt32.max, using: &rng))        // loaded x
    input.append(UInt32.random(in: 0 ... UInt32.max, using: &rng))        // c
    input.append(UInt32.random(in: 0 ... UInt32.max, using: &rng))        // d
}
let inBuf = device.makeBuffer(bytes: input, length: input.count * 4, options: .storageModeShared)!
var k: UInt32 = 21952

// (name, the dividend's 32-bit word x, K)
let checks: [(String, (Int) -> UInt32, UInt32)] = [
    ("prod_hi16_div", { sq_hi(input[4 * $0]) }, 21952),
    ("prod_hi16_div_guarded", { sq_hi(input[4 * $0]) }, 21952),
    ("sum_hi16_div", { sum_hi(input[4 * $0], input[4 * $0 + 2], input[4 * $0 + 3]) }, 2500),
    ("loaded_hi16_div", { input[4 * $0 + 1] }, 21952),
    ("prod_hi16_div_pow2", { sq_hi(input[4 * $0]) }, 32768),
    ("prod_hi16_div_runtime", { sq_hi(input[4 * $0]) }, 21952),
]


for (name, word, kk) in checks {
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
    var wrong = 0, low16 = 0
    var example = ""
    for i in 0..<n {
        let x = word(i)
        let want = (x >> 16) / kk
        if out[i] != want {
            wrong += 1
            if out[i] == (x & 0xFFFF) / kk { low16 += 1 }
            if example.isEmpty { example = "x=\(x): got \(out[i]), want \(want), low16 \((x & 0xFFFF) / kk)" }
        }
    }
    let note = wrong > 0 ? "  (\(low16) equal the low 16 bits' quotient; e.g. \(example))" : ""
    print("\(name.padding(toLength: 22, withPad: " ", startingAt: 0)) \(wrong) of \(n) wrong\(note)")
}

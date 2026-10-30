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

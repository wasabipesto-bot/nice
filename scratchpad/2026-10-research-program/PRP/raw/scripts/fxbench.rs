// fxbench.rs: the CPU join's prefilter digits (cpu_join::Fx::digits) at b = 64 with the base a runtime value, as
// the CPU join holds it, against the same digits by shifts (s = 6 a runtime value as well). Two independent pairs of
// digits per "pair" (n² and n³), summed so nothing is optimised out. rustc -O fxbench.rs && ./fxbench
use std::hint::black_box;
use std::time::Instant;
#[inline(never)]
fn mul(fs: &[u32], b: u64) -> u64 {
    let mut acc = 0u64;
    for &f in fs {
        let fb = u64::from(f) * b;
        acc = acc.wrapping_add((fb >> 32) ^ ((u64::from(fb as u32) * b) >> 32));
    }
    acc
}
#[inline(never)]
fn shf(fs: &[u32], s: u32) -> u64 {
    let up = 32 - s;
    let mut acc = 0u64;
    for &f in fs {
        acc = acc.wrapping_add(u64::from(f >> up) ^ u64::from((f << s) >> up));
    }
    acc
}
fn main() {
    let mut x = 0x9E37_79B9_7F4A_7C15u64;
    let fs: Vec<u32> = (0..1 << 20).map(|_| { x ^= x << 13; x ^= x >> 7; x ^= x << 17; (x >> 32) as u32 }).collect();
    let (b, s) = (black_box(64u64), black_box(6u32));
    assert_eq!(mul(&fs, b), shf(&fs, s));
    for round in 0..3 {
        let t = Instant::now(); let mut a = 0; for _ in 0..200 { a ^= mul(black_box(&fs), b); } let tm = t.elapsed().as_secs_f64();
        let t = Instant::now(); let mut c = 0; for _ in 0..200 { c ^= shf(black_box(&fs), s); } let ts = t.elapsed().as_secs_f64();
        let n = 200.0 * fs.len() as f64;
        println!("round {round}: multiply {:.3} ns/fraction, shift {:.3} ns/fraction ({a:x} {c:x})", 1e9 * tm / n, 1e9 * ts / n);
    }
}

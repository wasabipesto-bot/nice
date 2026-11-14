//! CPU2 scratch: contiguous partitions on one thread, one scratch, each
//! partition timed. usage: cpu2_abv <base> <start> <size> <slice> <v0> <count>
use nice_common::FieldSize;
use nice_common::cpu_join::{CpuJoin, Scratch, slices_for};
use std::time::Instant;
fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let start: u128 = a[2].parse().unwrap();
    let size: u128 = a[3].parse::<f64>().unwrap() as u128;
    let si: usize = a[4].parse().unwrap();
    let v0: u32 = a[5].parse().unwrap();
    let n: u32 = a[6].parse().unwrap();
    let (jp, slices) = slices_for(base, &FieldSize::new(start, start + size)).unwrap();
    let join = CpuJoin::new(base, &slices[si], jp).unwrap();
    let mut sc = Scratch::default();
    let mut tot = 0.0;
    let mut line = String::new();
    for v in v0..v0 + n {
        let t = Instant::now();
        let out = join.run_partition(v, &mut sc);
        let s = t.elapsed().as_secs_f64();
        tot += s;
        line += &format!(" {s:.3}");
        std::hint::black_box(out);
    }
    println!("ABV b{base} v {v0}..{} total {tot:.3} per:{line}", v0 + n);
}

//! CPU2 scratch: per partition, the real top phase with runs carried, and
//! the whole partition (separate scratches, both ascending).
//! usage: cpu2_carried <base> <start> <size> <slice> <v0> <count>
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
    let (mut s1, mut s2) = (Scratch::default(), Scratch::default());
    for v in v0..v0 + n {
        let p = join.prof_tops_carried(v, &mut s1);
        let t = Instant::now();
        let out = join.run_partition(v, &mut s2);
        println!("V {v} tops_ns {} tops {} partition_ns {} survivors {}", p.ns, p.tops, t.elapsed().as_nanos(), out.survivors);
    }
}

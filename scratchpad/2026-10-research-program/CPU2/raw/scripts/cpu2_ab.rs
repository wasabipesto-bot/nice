//! CPU2 scratch (not for the PR): contiguous partitions of one slice on one
//! thread, as the client's pool runs them. usage:
//! cpu2_ab <base> <start|fFRAC> <size> <slice> <v0> <count> [counts]
use nice_common::FieldSize;
use nice_common::base_range::get_base_range_u128;
use nice_common::cpu_join::{CpuJoin, PartitionResult, Scratch, slices_for};
use std::time::Instant;

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let size: u128 = a[3].parse::<f64>().unwrap() as u128;
    let start: u128 = if let Some(f) = a[2].strip_prefix('f') {
        let band = get_base_range_u128(base).unwrap().unwrap();
        let f: f64 = f.parse().unwrap();
        let off = (band.size() as f64 * f) as u128;
        let s = band.start() + off / size * size;
        s.min(band.end() - size)
    } else {
        a[2].parse().unwrap()
    };
    let si: usize = a[4].parse().unwrap();
    let v0: u32 = a[5].parse().unwrap();
    let count: u32 = a[6].parse().unwrap();
    let range = FieldSize::new(start, start + size);
    let (jp, slices) = slices_for(base, &range).expect("a join field");
    let t = Instant::now();
    let join = CpuJoin::new(base, &slices[si], jp).expect("setup");
    let setup = t.elapsed().as_secs_f64();
    let v1 = (v0 + count).min(join.partitions());
    let mut sc = Scratch::default();
    let mut out = PartitionResult::default();
    let wall = Instant::now();
    for v in v0..v1 {
        out.add(join.run_partition(v, &mut sc));
    }
    let secs = wall.elapsed().as_secs_f64();
    out.hits.sort_unstable();
    println!(
        "AB b{base} start {start} size {size:e} slice {si}/{} v {v0}..{v1} setup {setup:.3} secs {secs:.4} survivors {} checked {} hits {:?}",
        slices.len(),
        out.survivors,
        out.checked,
        out.hits
    );
}

//! CPU2 scratch: the skip walk's counts over contiguous partitions.
//! usage: cpu2_skipcount <base> <start|fFRAC> <size> <slice> <v0> <count>
use nice_common::FieldSize;
use nice_common::base_range::get_base_range_u128;
use nice_common::cpu_join::{CpuJoin, Scratch, slices_for};

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
    let join = CpuJoin::new(base, &slices[si], jp).expect("setup");
    let v1 = (v0 + count).min(join.partitions());
    let mut sc = Scratch::default();
    let (mut un, mut te, mut se, mut stp, mut to, mut ns) = (0u64, 0u64, 0u64, 0u64, 0u64, 0u64);
    for v in v0..v1 {
        let p = join.prof_skip(v, &mut sc);
        println!(
            "V {v} unclipped {} tests {} seeds {} steps {} tops {} ns {}",
            p.unclipped, p.tests, p.seeds, p.steps, p.tops, p.ns
        );
        un += p.unclipped;
        te += p.tests;
        se += p.seeds;
        stp += p.steps;
        to += p.tops;
        ns += p.ns;
    }
    println!(
        "SUM b{base} start {start} slice {si} v {v0}..{v1}: unclipped {un} tests {te} ({:.4}) seeds {se} ({:.4}/test) steps {stp} ({:.3}/test) tops {to} ({:.4}) ns/unclipped {:.1}",
        te as f64 / un as f64,
        se as f64 / te as f64,
        stp as f64 / te as f64,
        to as f64 / un as f64,
        ns as f64 / un as f64
    );
}

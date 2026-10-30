//! L3 cross-tree window timer (dropped into common/examples/ on the box only;
//! never committed). Times the production entry point
//! `process_range_detailed_cubecl` -- the call nice_client makes per field --
//! on fixed windows at the base's range start, like the exp branch's
//! `fd_timing` (one warm-up/JIT call, then REPS timed calls, rate =
//! window*reps/elapsed). Prints a digest of the results so trees can be
//! compared for exactness.
use nice_common::base_range::get_base_range_u128;
use nice_common::cubecl_backend::{CubeclContext, process_range_detailed_cubecl};
use nice_common::{FieldResults, FieldSize};
use std::time::Instant;

fn env_u128(k: &str, d: u128) -> u128 {
    std::env::var(k).ok().map_or(d, |v| v.trim().parse::<f64>().map(|f| f as u128).unwrap_or_else(|_| v.trim().parse().unwrap()))
}

fn digest(r: &FieldResults) -> String {
    let mut h: u64 = 0xcbf29ce484222325;
    let mut eat = |x: u128| {
        for b in x.to_le_bytes() {
            h ^= u64::from(b);
            h = h.wrapping_mul(0x100000001b3);
        }
    };
    let mut total = 0u128;
    for d in &r.distribution {
        eat(u128::from(d.num_uniques));
        eat(d.count);
        total += d.count;
    }
    for n in &r.nice_numbers {
        eat(n.number);
        eat(u128::from(n.num_uniques));
    }
    format!("total={total} near_misses={} fnv={h:016x}", r.nice_numbers.len())
}

fn main() {
    let bases: Vec<u32> = std::env::var("L3_BASES").unwrap_or_else(|_| "40,50".into())
        .split(',').map(|x| x.trim().parse().unwrap()).collect();
    let window = env_u128("L3_WINDOW", 2_000_000_000);
    let reps = env_u128("L3_REPS", 3);
    let offset = env_u128("L3_OFFSET", 0);
    let tag = std::env::var("L3_TAG").unwrap_or_default();
    let t0 = Instant::now();
    let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
    println!("L3WIN {tag} init {:.2}s device {} backend {}", t0.elapsed().as_secs_f64(), ctx.device_name(), ctx.backend_name());
    for &base in &bases {
        let rs = get_base_range_u128(base).unwrap().unwrap().start() + offset;
        let range = FieldSize::new(rs, rs + window);
        let t = Instant::now();
        let warm = process_range_detailed_cubecl(&ctx, &range, base).unwrap();
        println!("L3WIN {tag} b{base} start {rs} window {window:.3e} warmup {:.3}s {}", t.elapsed().as_secs_f64(), digest(&warm));
        let mut secs = Vec::new();
        let t = Instant::now();
        for _ in 0..reps {
            let ti = Instant::now();
            let r = process_range_detailed_cubecl(&ctx, &range, base).unwrap();
            secs.push(ti.elapsed().as_secs_f64());
            assert_eq!(r.distribution, warm.distribution, "b{base} rep mismatch");
            assert_eq!(r.nice_numbers, warm.nice_numbers, "b{base} rep mismatch");
        }
        let el = t.elapsed().as_secs_f64();
        let s: Vec<String> = secs.iter().map(|x| format!("{x:.4}")).collect();
        #[allow(clippy::cast_precision_loss)]
        let rate = (window * reps) as f64 / el;
        println!("L3WIN {tag} b{base} reps {reps} secs [{}] rate {rate:.4e} n/s", s.join(" "));
        if std::env::var("L3_DUMP").is_ok() {
            println!("L3DUMP {tag} b{base} {}", serde_json::to_string(&warm).unwrap());
        }
    }
}

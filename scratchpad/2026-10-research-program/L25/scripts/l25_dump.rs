
// ---- L25 audit (box-local, not committed): drive each kernel once per base so
// CUBECL_DEBUG_LOG records the WGSL CubeCL generates for it.
#[cfg(test)]
mod l25_dump {
    use super::*;
    use crate::gpu_route::process_niceonly;

    fn base() -> u32 {
        std::env::var("L25_BASE").expect("L25_BASE").parse().expect("base")
    }
    fn start(b: u32) -> u128 {
        std::env::var("L25_START").ok().map_or_else(
            || crate::base_range::get_base_range_u128(b).unwrap().unwrap().range_start,
            |v| v.parse().unwrap(),
        )
    }
    fn parts() -> Vec<u32> {
        std::env::var("L25_PARTS").map_or(vec![0], |v| v.split(',').map(|x| x.parse().unwrap()).collect())
    }
    fn size(default: f64) -> u128 {
        std::env::var("L25_SIZE").ok().map_or(default, |v| v.parse::<f64>().unwrap()) as u128
    }

    #[test]
    #[ignore = "L25 dump driver"]
    fn l25_stride() {
        let ctx = CubeclContext::new_default().unwrap();
        let b = base();
        let s = start(b);
        let r = FieldSize::new(s, s + size(1e9));
        let res = process_niceonly(&ctx, &r, b).unwrap();
        println!("L25 stride b{b} [{s}, +{}): {} nice", r.size(), res.nice_numbers.len());
    }

    #[test]
    #[ignore = "L25 dump driver"]
    fn l25_join() {
        let ctx = CubeclContext::new_default().unwrap();
        let b = base();
        let s = start(b);
        let r = FieldSize::new(s, s + size(1e13));
        match ctx.join_sample(b, &r, &parts()).unwrap() {
            Ok(sm) => println!(
                "L25 join b{b} [{s}, +{}): survivors {} checked {} hits {:?}",
                r.size(),
                sm.survivors,
                sm.checked,
                sm.hits
            ),
            Err(e) => println!("L25 join b{b}: not joined: {e:?}"),
        }
    }

    #[test]
    #[ignore = "L25 dump driver"]
    fn l25_detailed() {
        let ctx = CubeclContext::new_default().unwrap();
        let b = base();
        let s = start(b);
        let r = FieldSize::new(s, s + size(1e6));
        let res = process_range_detailed_cubecl(&ctx, &r, b).unwrap();
        println!("L25 detailed b{b}: {} near misses", res.nice_numbers.len());
    }

    #[test]
    #[ignore = "L25 dump driver"]
    fn l25_web() {
        let ctx = CubeclContext::new_default().unwrap();
        let b = base();
        let s = start(b);
        let r = FieldSize::new(s, s + size(1e6));
        let res = crate::cubecl_web::process_range_detailed_web(&ctx, &r, b).unwrap();
        println!("L25 web b{b}: {} near misses", res.nice_numbers.len());
    }
}

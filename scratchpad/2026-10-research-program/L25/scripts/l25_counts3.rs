
// ---- L25 audit (box-local): b49-55 windows that have join survivors.
#[cfg(test)]
mod l25_counts3 {
    use crate::overlap_join::test_fields::{live_partitions, mid_mirror};
    use crate::overlap_join::{FieldSetup, JoinParams, join_range};

    #[test]
    #[ignore = "L25 window search"]
    fn l25_window_search3() {
        let mut seed = 0x9E37_79B9_7F4A_7C15u64;
        for b in [50u32, 54] {
            let r = crate::base_range::get_base_range_u128(b).unwrap().unwrap();
            let (lo, hi) = (r.range_start, r.range_end);
            let mut starts: Vec<u128> = if b == 50 { vec![62_082_117_268_529_817] } else { vec![] };
            for _ in 0..60 {
                seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17;
                starts.push(lo + (u128::from(seed) % (hi - lo - 10_000_000)));
            }
            let mut found = 0;
            for s in starts {
                for &w in &[300_000u128, 3_000_000] {
                    for &(t, k, p) in &[(7u32, 4u32, 1u32), (8, 4, 1), (7, 5, 2), (8, 3, 1), (9, 3, 1), (8, 4, 2)] {
                        let jp = JoinParams { t, k, p };
                        let e = s + w;
                        let Ok(fs) = FieldSetup::new(b, s, e, jp) else { continue };
                        let live = live_partitions(&fs);
                        if live.is_empty() { continue; }
                        let parts: Vec<u128> = live.iter().map(|&v| u128::from(v)).collect();
                        let mut rec = Vec::new();
                        let t0 = std::time::Instant::now();
                        let st = join_range(&fs.base, s, e, jp, Some(&parts), Some(&mut rec));
                        let checked = rec.iter().filter(|&&n| mid_mirror(&fs, n)).count();
                        if st.survivors > 0 {
                            found += 1;
                            println!(
                                "L25 b{b} [{s}, {e}) ({t},{k},{p}): live {} survivors {} checked {checked} hits {} in {:.2}s",
                                live.len(), st.survivors, st.hits.len(), t0.elapsed().as_secs_f64()
                            );
                        }
                    }
                }
                if found >= 12 { break; }
            }
            println!("L25 b{b}: {found} windows with survivors");
        }
    }
}


// ---- L25 audit (box-local): find b50/b54 windows with join survivors.
#[cfg(test)]
mod l25_counts2 {
    use crate::overlap_join::test_fields::{live_partitions, mid_mirror};
    use crate::overlap_join::{FieldSetup, JoinParams, join_range};

    #[test]
    #[ignore = "L25 window search"]
    fn l25_window_search() {
        let starts: &[(u32, u128)] = &[(50, 50_000_000_000_000_017), (54, 2_200_000_000_000_000_011)];
        let shapes: &[(u32, u32, u32)] = &[(7, 4, 1), (6, 5, 1), (7, 4, 2), (6, 5, 2), (8, 3, 1), (8, 4, 1), (7, 5, 1), (7, 5, 2), (9, 3, 1)];
        for &(b, s) in starts {
            for &w in &[300_000u128, 3_000_000, 30_000_000] {
                for &(t, k, p) in shapes {
                    let jp = JoinParams { t, k, p };
                    let e = s + w;
                    let Ok(fs) = FieldSetup::new(b, s, e, jp) else { continue };
                    let live = live_partitions(&fs);
                    if live.is_empty() { continue; }
                    let t0 = std::time::Instant::now();
                    let parts: Vec<u128> = live.iter().map(|&v| u128::from(v)).collect();
                    let mut rec = Vec::new();
                    let st = join_range(&fs.base, s, e, jp, Some(&parts), Some(&mut rec));
                    let checked = rec.iter().filter(|&&n| mid_mirror(&fs, n)).count();
                    println!(
                        "L25 b{b} w={w} ({t},{k},{p}): live {} survivors {} checked {checked} hits {} in {:.2}s",
                        live.len(), st.survivors, st.hits.len(), t0.elapsed().as_secs_f64()
                    );
                }
            }
        }
    }
}

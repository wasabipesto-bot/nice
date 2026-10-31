
// ---- L25 audit (box-local): are the new b50/b54 test windows non-vacuous?
#[cfg(test)]
mod l25_counts {
    use crate::overlap_join::test_fields::{live_partitions, mid_mirror};
    use crate::overlap_join::{FieldSetup, JoinParams, join_range};

    #[test]
    #[ignore = "L25 window counts"]
    fn l25_window_counts() {
        let w: &[(u32, u128, u128, u32, u32, u32)] = &[
            (50, 50_000_000_000_000_017, 50_000_000_000_300_017, 7, 4, 1),
            (54, 2_200_000_000_000_000_011, 2_200_000_000_000_300_011, 8, 4, 1),
        ];
        for &(b, s, e, t, k, p) in w {
            let jp = JoinParams { t, k, p };
            let fs = FieldSetup::new(b, s, e, jp).expect("setup");
            let live = live_partitions(&fs);
            let parts: Vec<u128> = live.iter().map(|&v| u128::from(v)).collect();
            let mut rec = Vec::new();
            let st = join_range(&fs.base, s, e, jp, Some(&parts), Some(&mut rec));
            let checked = rec.iter().filter(|&&n| mid_mirror(&fs, n)).count();
            println!(
                "L25 b{b} [{s}, {e}) {jp:?}: {} live partitions, join survivors {}, prefilter survivors {checked}, hits {:?}",
                live.len(),
                st.survivors,
                st.hits
            );
        }
    }
}

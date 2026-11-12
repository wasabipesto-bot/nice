#!/usr/bin/env python3
"""Throwaway (never committed): count the pairs the join kernel writes past a full shared stage, and optionally shrink
the stage. python3 patch_cnt.py TREE CAP FLUSH. The kernel adds 1 to and_count[1] on the direct path; the batch's
survivor-count buffer gets a second word; run_batches adds it into a process-wide counter that the dense-field test
prints as PAST_FULL_STAGE (with the stage size, so the binary says which build it is)."""
import sys
tree, cap, flush = sys.argv[1], sys.argv[2], sys.argv[3]
p = tree + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(old, new, n=1):
    global s
    assert s.count(old) == n, (old, s.count(old))
    s = s.replace(old, new)
rep('pub const SURV_SH_CAP: u32 = 512;', f'pub const SURV_SH_CAP: u32 = {cap};')
rep('pub const SURV_FLUSH: u32 = 256;', f'pub const SURV_FLUSH: u32 = {flush};')
rep("""                                        } else {
                                            let g = surv_count[0].fetch_add(1u32);""",
"""                                        } else {
                                            and_count[1].fetch_add(1u32);
                                            let g = surv_count[0].fetch_add(1u32);""")
rep("let survivors = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));",
    "let survivors = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 2]));")
rep("""        let surv = u32::from_bytes(&counts[3 * i])[0];
        let checked = u32::from_bytes(&counts[3 * i + 1])[0];""",
"""        let surv = u32::from_bytes(&counts[3 * i])[0];
        PAST_FULL_STAGE.fetch_add(
            u64::from(u32::from_bytes(&counts[3 * i])[1]),
            std::sync::atomic::Ordering::Relaxed,
        );
        let checked = u32::from_bytes(&counts[3 * i + 1])[0];""")
rep("/// Threads per cube for every kernel here (the client's `WORKGROUP_SIZE`).",
    "pub static PAST_FULL_STAGE: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);\n/// Threads per cube for every kernel here (the client's `WORKGROUP_SIZE`).")
rep("""        assert_eq!(got, want.hits, "hits differ");
        assert_eq!(
            (st.survivors, st.checked),""",
"""        println!(
            "PAST_FULL_STAGE stage={} flush={} pairs={} (checked {})",
            SURV_SH_CAP,
            SURV_FLUSH,
            super::PAST_FULL_STAGE.load(std::sync::atomic::Ordering::Relaxed),
            st.checked
        );
        assert_eq!(got, want.hits, "hits differ");
        assert_eq!(
            (st.survivors, st.checked),""")
open(p, 'w').write(s)
print('patched', p, cap, flush)

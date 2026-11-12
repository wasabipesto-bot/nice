#!/usr/bin/env python3
"""N16: split HOSTACC's launch_batch time into buffer creation (the batch's small inputs and counters), kernel
launches (encode/dispatch) and the flush (submit), since on wgpu the host blocks inside launch_batch rather than on
the fence (lavapipe: every fence pending, encode = the whole field). python3 patch_n16_hostacc2.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (s.count(a), a[:80])
    s = s.replace(a, b)
rep("""    pub static READ_NS: AtomicU64 = AtomicU64::new(0);""", """    pub static READ_NS: AtomicU64 = AtomicU64::new(0);
    /// `launch_batch` split: buffer creation, kernel launches, flush.
    pub static CREATE_NS: AtomicU64 = AtomicU64::new(0);
    pub static LAUNCH_NS: AtomicU64 = AtomicU64::new(0);
    pub static FLUSH_NS: AtomicU64 = AtomicU64::new(0);""")
rep("""        for c in [&BATCHES, &LAUNCHES, &FENCES, &READS, &ENC_NS, &FENCE_NS, &WAIT_NS, &READ_NS] {""",
    """        for c in [
            &BATCHES, &LAUNCHES, &FENCES, &READS, &ENC_NS, &FENCE_NS, &WAIT_NS, &READ_NS, &CREATE_NS,
            &LAUNCH_NS, &FLUSH_NS,
        ] {""")
rep("""             wait_s={:.3} read_s={:.3}",""", """             wait_s={:.3} read_s={:.3} (encode: create_s={:.3} launch_s={:.3} flush_s={:.3})",""")
rep("""            s(&WAIT_NS),
            s(&READ_NS)
        )""", """            s(&WAIT_NS),
            s(&READ_NS),
            s(&CREATE_NS),
            s(&LAUNCH_NS),
            s(&FLUSH_NS)
        )""")
rep("""        let mut pt = if self.profile {
            profile_sync(c)?;
            Some(Instant::now())
        } else {
            None
        };
        let vs_h = c.create""", """        let mut pt = if self.profile {
            profile_sync(c)?;
            Some(Instant::now())
        } else {
            None
        };
        let ha_t0 = Instant::now();
        let vs_h = c.create""")
rep("""        let ran = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; expect.len()]));
        let nran = expect.len();""", """        let ran = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; expect.len()]));
        let nran = expect.len();
        let ha_t1 = Instant::now();
        if hostacc::on() {
            hostacc::add(&hostacc::CREATE_NS, (ha_t1 - ha_t0).as_nanos() as u64);
        }""")
rep("""        c.flush().map_err(|e| anyhow!("flush failed: {e:?}"))?;
        if let Some(t) = pt {
            self.prof_mark(t, |p, s| p.check_secs += s)?;
        }""", """        let ha_t2 = Instant::now();
        c.flush().map_err(|e| anyhow!("flush failed: {e:?}"))?;
        if hostacc::on() {
            hostacc::add(&hostacc::LAUNCH_NS, (ha_t2 - ha_t1).as_nanos() as u64);
            hostacc::add(&hostacc::FLUSH_NS, ha_t2.elapsed().as_nanos() as u64);
        }
        if let Some(t) = pt {
            self.prof_mark(t, |p, s| p.check_secs += s)?;
        }""")
open(p, 'w').write(s)
print('patched hostacc split', p)

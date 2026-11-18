import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


# ---- kernels
rep("""    /// Thread i = d·2^15 + (h − 2^15): certificate, then a count in segc[d·63 + h mod 63].
    #[cube(launch_unchecked)]
    pub fn tops1_kernel(
        tm: &mut Array<u64>,
        thm: &mut Array<u64>,
        tv: &mut Array<u32>,
        segc: &mut Array<Atomic<u32>>,
        tstat: &mut Array<Atomic<u32>>,
        pip: u32,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < 2_097_152u32 {
            let d = i >> 15u32;
            let h = 32768u32 + (i & 32767u32);""", """    /// The top hierarchy's coarser level, once per 64 slices (digits 5-8 =
    /// `q`): thread i = d·2^15 + (h − 2^15) certifies the prefix n div 2^30
    /// = h·2^30 + d·2^24 + q over its 2^30 n; the valid ones are appended to
    /// `l5` (h | d << 16), their count in `l5n[0]`. A slice's top (digit 4
    /// added) can only be valid under a valid parent: its interval is inside
    /// the parent's, so its certificate holds the parent's digits.
    #[cube(launch_unchecked)]
    pub fn tops5_kernel(l5: &mut Array<u32>, l5n: &mut Array<Atomic<u32>>, q: u32) {
        let i = ABSOLUTE_POS_X;
        if i < 2_097_152u32 {
            let d = i >> 15u32;
            let h = 32768u32 + (i & 32767u32);
            // p = h·2^30 + d·2^24 + q, a = p·2^30, c = a + 2^30 − 1, in 32-bit limbs
            let p = (u64::cast_from(h) << 30u64) | (u64::cast_from(d) << 24u64) | u64::cast_from(q);
            let mut a = Array::<u32>::new(3usize);
            let mut c = Array::<u32>::new(3usize);
            a[0] = u32::cast_from((p & 3u64) << 30u64);
            a[1] = u32::cast_from((p >> 2u64) & 0xFFFF_FFFFu64);
            a[2] = u32::cast_from(p >> 34u64);
            c[0] = a[0] | 0x3FFF_FFFFu32;
            c[1] = a[1];
            c[2] = a[2];
            let mut a2 = Array::<u32>::new(6usize);
            let mut c2 = Array::<u32>::new(6usize);
            mul(&a, &a, &mut a2, 3u32, 3u32);
            mul(&c, &c, &mut c2, 3u32, 3u32);
            let mut a3 = Array::<u32>::new(9usize);
            let mut c3 = Array::<u32>::new(9usize);
            mul(&a2, &a, &mut a3, 6u32, 3u32);
            mul(&c2, &c, &mut c3, 6u32, 3u32);
            let (m1, h1, bad1) = cert_pow(&a2, &c2, 0u64, 0u64, 25u32);
            let (_m2, _h2, bad2) = cert_pow(&a3, &c3, m1, h1, 37u32);
            if !bad1 && !bad2 {
                let slot = l5n[0usize].fetch_add(1u32);
                l5[slot as usize] = h | (d << 16u32);
            }
        }
    }

    /// Thread i < l5n: the slice's top under the i-th valid parent of `l5`
    /// (the parent's lead h and unit d, the slice's digit 4): certificate,
    /// then a count in segc[d·63 + h mod 63].
    #[cube(launch_unchecked)]
    pub fn tops1_kernel(
        tm: &mut Array<u64>,
        thm: &mut Array<u64>,
        tv: &mut Array<u32>,
        segc: &mut Array<Atomic<u32>>,
        tstat: &mut Array<Atomic<u32>>,
        l5: &Array<u32>,
        l5n: &Array<u32>,
        pip: u32,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < l5n[0usize] {
            let hd = l5[i as usize];
            let d = hd >> 16u32;
            let h = hd & 0xFFFFu32;""")
rep("""    /// One cube of 1,024: segment starts (tseg pairs), cursors, and the top count in tstat[0].
    #[cube(launch_unchecked)]
    pub fn tscan_kernel(
        segc: &Array<u32>,
        tseg: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tstat: &mut Array<u32>,
    ) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;""", """    /// One cube of 1,024: segment starts (tseg pairs), cursors, the top count
    /// in tstat[0] and the prefixes certified (the valid parents) in tstat[2].
    #[cube(launch_unchecked)]
    pub fn tscan_kernel(
        segc: &Array<u32>,
        tseg: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tstat: &mut Array<u32>,
        l5n: &Array<u32>,
    ) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        if t == 0u32 {
            tstat[2usize] = l5n[0usize];
        }""")
rep("""    pub fn tops2_kernel(
        tm: &Array<u64>,
        thm: &Array<u64>,
        tv: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmask: &mut Array<u64>,
        thd: &mut Array<u32>,
        tmhi: &mut Array<u64>,
        cap: u32,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < 2_097_152u32 {
            if tv[i as usize] == 1u32 {
                let d = i >> 15u32;
                let h = 32768u32 + (i & 32767u32);""", """    pub fn tops2_kernel(
        tm: &Array<u64>,
        thm: &Array<u64>,
        tv: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmask: &mut Array<u64>,
        thd: &mut Array<u32>,
        tmhi: &mut Array<u64>,
        l5: &Array<u32>,
        l5n: &Array<u32>,
        cap: u32,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < l5n[0usize] {
            if tv[i as usize] == 1u32 {
                let hd = l5[i as usize];
                let d = hd >> 16u32;
                let h = hd & 0xFFFFu32;""")
# ---- driver
rep("""    /// Device tops: every prefix's mask, prefilter mask and validity.
    tm: Handle,
    thm: Handle,
    tv: Handle,""", """    /// Device tops: every prefix's mask, prefilter mask and validity.
    tm: Handle,
    thm: Handle,
    tv: Handle,
    /// The top hierarchy: the valid parents (digits 5-12 fixed) of the
    /// current 64 slices, and (digits 5-8, their count) once queued.
    l5: Handle,
    l5cur: Mutex<Option<(u32, Handle)>>,""")
rep("""            tm: e(8 << 21),
            thm: e(8 << 21),
            tv: e(4 << 21),""", """            tm: e(8 << 21),
            thm: e(8 << 21),
            tv: e(4 << 21),
            l5: e(4 << 21),
            l5cur: Mutex::new(None),""")
rep("""use std::sync::mpsc;""", """use std::sync::{Mutex, mpsc};""")
rep("""        let segc = self.mk(vec![0u32; 4032]);
        let tstat = self.mk(vec![0u32; 2]);""", """        let segc = self.mk(vec![0u32; 4032]);
        let tstat = self.mk(vec![0u32; 3]);
        let full = 1u32 << 21;
        // the slice's 64-slice group's valid parents, made once per group (the stream orders their reuse)
        let q = (pip >> 6) as u32;
        let l5n = {
            let mut cur = self.l5cur.lock().expect("l5cur");
            match &*cur {
                Some((cq, h)) if *cq == q => h.clone(),
                _ => {
                    let h = self.mk(vec![0u32; 1]);
                    if self.stop < 10 || self.stop - 10 >= 1 {
                        unsafe {
                            dtops::tops5_kernel::launch_unchecked::<R>(
                                &self.client,
                                CubeCount::Static(full / NT, 1, 1),
                                CubeDim::new_1d(NT),
                                ArrayArg::from_raw_parts(self.l5.clone(), full as usize),
                                ArrayArg::from_raw_parts(h.clone(), 1),
                                q,
                            );
                        }
                    }
                    *cur = Some((q, h.clone()));
                    h
                }
            }
        };""")
rep("""        let cur = self.client.empty(4032 * 4);
        let full = 1u32 << 21;""", """        let cur = self.client.empty(4032 * 4);""")
rep("""                    a(&self.tv, full as usize),
                    a(&segc, 4032),
                    a(&tstat, 2),
                    pip as u32,""", """                    a(&self.tv, full as usize),
                    a(&segc, 4032),
                    a(&tstat, 3),
                    a(&self.l5, full as usize),
                    a(&l5n, 1),
                    pip as u32,""")
rep("""                    a(&cur, 4032),
                    a(&tstat, 2),
                );""", """                    a(&cur, 4032),
                    a(&tstat, 3),
                    a(&l5n, 1),
                );""")
rep("""                    a(&thdh, nt),
                    a(&tmhih, nt),
                    nt as u32,""", """                    a(&thdh, nt),
                    a(&tmhih, nt),
                    a(&self.l5, full as usize),
                    a(&l5n, 1),
                    nt as u32,""")
rep("""                    a(&self.lcnt, 1),
                    a(&tstat, 2),
                    nt as u32,""", """                    a(&self.lcnt, 1),
                    a(&tstat, 3),
                    nt as u32,""")
rep("""                    a(&self.top_rec, nt * 8),
                    a(&tstat, 2),""", """                    a(&self.top_rec, nt * 8),
                    a(&tstat, 3),""")
rep("""                dc.tops += u64::from(v[0]);
                dc.tested += 1 << 21;""", """                dc.tops += u64::from(v[0]);
                dc.tested += u64::from(v[2]);""")
open(p, 'w').write(s)

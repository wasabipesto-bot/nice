import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1, after=None):
    global s
    if after is not None:
        i = s.index(after)
        head, tail = s[:i], s[i:]
        assert tail.count(old) >= 1, (old[:80], 0)
        s = head + tail.replace(old, new, 1)
        return
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


# tops2: the mask into its own per-top array
rep("""    /// Each certified prefix into its segment: tmask and thd = h | d << 16,
    /// and the prefilter's mask (digits at positions >= 12) into words 2-3
    /// of its top record (the check reads words 0, 1 and 6 only).""",
    """    /// Each certified prefix into its segment: tmask and thd = h | d << 16,
    /// and tmhi, the prefilter's mask (its digits at positions >= 12).""")
rep("""        thd: &mut Array<u32>,
        top_rec: &mut Array<u32>,
        cap: u32,
    ) {""", """        thd: &mut Array<u32>,
        tmhi: &mut Array<u64>,
        cap: u32,
    ) {""")
rep("""                    let mh = thm[i as usize];
                    top_rec[(8u32 * slot + 2u32) as usize] = u32::cast_from(mh & 0xFFFF_FFFFu64);
                    top_rec[(8u32 * slot + 3u32) as usize] = u32::cast_from(mh >> 32u64);""",
    """                    tmhi[slot as usize] = thm[i as usize];""")
# top records back to production's (words 2-5 zero)
rep("""            top_rec[(o + 1u32) as usize] = h >> 2u32;
            // words 2-3: the prefilter's mask, written by tops2""", """            top_rec[(o + 1u32) as usize] = h >> 2u32;
            top_rec[(o + 2u32) as usize] = 0u32;
            top_rec[(o + 3u32) as usize] = 0u32;""")
rep("""    pub fn toprec_kernel(
        thd: &Array<u32>,
        tmhi: &Array<u32>,
        top_rec: &mut Array<u32>,
        pip_hi: u32,
        ntops: u32,
    ) {""", """    pub fn toprec_kernel(thd: &Array<u32>, top_rec: &mut Array<u32>, pip_hi: u32, ntops: u32) {""")
rep("""            top_rec[(o + 2u32) as usize] = tmhi[(2u32 * i) as usize];
            top_rec[(o + 3u32) as usize] = tmhi[(2u32 * i + 1u32) as usize];""", """            top_rec[(o + 2u32) as usize] = 0u32;
            top_rec[(o + 3u32) as usize] = 0u32;""")
# prefilter: P from thd and the slice, the mask from tmhi
rep("""    /// 10): n mod 2^72 from `r0` and its top record's P (bits 30-93 of n);""",
    """    /// 10): n mod 2^72 from `r0` and its top's P (bits 30-93 of n);""")
rep("""    /// digits at positions >= 12 (`mlo`, `mhi`, words 2-3 of its record).
    #[cube]
    fn pf(r0: u32, plo: u32, phi: u32, mlo: u32, mhi: u32) -> bool {""", """    /// digits at positions >= 12 (`top`).
    #[cube]
    fn pf(r0: u32, plo: u32, phi: u32, top: u64) -> bool {""")
rep("""        let top = u64::cast_from(mlo) | (u64::cast_from(mhi) << 32u64);
""", "")
rep("""        lcnt: &Array<u32>,
        top_rec: &Array<u32>,
        surv: &mut Array<u32>,""", """        lcnt: &Array<u32>,
        thd: &Array<u32>,
        tmhi: &Array<u64>,
        surv: &mut Array<u32>,""")
rep("""        scap: u32,
        r0hi: u32,
    ) {
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize].store(lcnt[0usize]);""", """        scap: u32,
        r0hi: u32,
        pip_hi: u32,
    ) {
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize].store(lcnt[0usize]);""")
rep("""                    let rb = 8u32 * ti;
                    let plo = top_rec[rb as usize];
                    let phi = top_rec[(rb + 1u32) as usize];
                    let mlo = top_rec[(rb + 2u32) as usize];
                    let mhi = top_rec[(rb + 3u32) as usize];""", """                    // P = n div 2^30 = h·2^30 + d·2^24 + digits 5-8 (the top record's words 0-1)
                    let hd = thd[ti as usize];
                    let h = hd & 0xFFFFu32;
                    let plo = ((h & 3u32) << 30u32) | ((hd >> 16u32) << 24u32) | pip_hi;
                    let phi = h >> 2u32;
                    let top = tmhi[ti as usize];""")
rep("""plo, phi, mlo, mhi)""", """plo, phi, top)""", cnt=2)
# driver
rep("""                    a(&thdh, nt),
                    a(&self.top_rec, nt * 8),
                    nt as u32,""", """                    a(&thdh, nt),
                    a(&tmhih, nt),
                    nt as u32,""")
rep("""        let thdh = self.client.empty(nt * 4);
        let cur = self.client.empty(4032 * 4);""", """        let thdh = self.client.empty(nt * 4);
        let tmhih = self.client.empty(nt * 8);
        let cur = self.client.empty(4032 * 4);""")
rep("""        (SliceBufs { tmh, tsegh, thdh }, tstat)""", """        (
            SliceBufs {
                tmh,
                tsegh,
                thdh,
                tmhih,
            },
            tstat,
        )""")
rep("""struct SliceBufs {
    tmh: Handle,
    tsegh: Handle,
    #[allow(dead_code)]
    thdh: Handle,
}""", """struct SliceBufs {
    tmh: Handle,
    tsegh: Handle,
    thdh: Handle,
    /// The tops' prefilter masks.
    tmhih: Handle,
}""")
rep("""        Ok(SliceBufs {
            tmh,
            tsegh,
            thdh: thdh.clone(),
        })""", """        Ok(SliceBufs {
            tmh,
            tsegh,
            thdh: thdh.clone(),
            tmhih,
        })""")
rep("""        let mut mh: Vec<u32> = st
            .tmhi
            .iter()
            .flat_map(|&x| [x as u32, (x >> 32) as u32])
            .collect();
        if mh.is_empty() {
            mh = vec![0, 0];
        }
        let tmhih = self.mk(mh);""", """        let mh: &[u64] = if st.tmhi.is_empty() { &[0] } else { &st.tmhi };
        let tmhih = self
            .client
            .create_from_slice(unsafe { std::slice::from_raw_parts(mh.as_ptr().cast::<u8>(), mh.len() * 8) });""")
rep("""                a(&thdh, nt),
                a(&tmhih, 2 * nt),
                a(&self.top_rec, nt * 8),""", """                a(&thdh, nt),
                a(&self.top_rec, nt * 8),""")
rep("""                        a(&self.lcnt, 1),
                        a(&self.top_rec, nt * 8),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 3),
                        self.nslab_cap,
                        self.scap,
                        ((pip & 63) as u32) << 24,""", """                        a(&self.lcnt, 1),
                        a(&sb.thdh, nt),
                        a(&sb.tmhih, nt),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 3),
                        self.nslab_cap,
                        self.scap,
                        ((pip & 63) as u32) << 24,
                        (pip >> 6) as u32,""")
open(p, 'w').write(s)

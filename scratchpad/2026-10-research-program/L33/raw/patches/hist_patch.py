#!/usr/bin/env python3
"""Throwaway instrumentation of the top kernel (NICE_EXP_TOP_HIST=1): failure-stage histograms."""
import sys
p = sys.argv[1]
s = open(p).read()

def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, (n, old[:200])
    s = s.replace(old, new)

# ---- cert_power: signature
rep("""        out_dom: &mut Array<u32>,
        #[comptime] nl: u32,
        #[comptime] nl3: u32,
        #[comptime] sp: u32,
        #[comptime] cap: u32,
        #[comptime] base: u32,
        #[comptime] chunk_digits: u32,
        #[comptime] chunk_div: u32,
    ) -> u64 {
        let nh = comptime!(2 * nl);""",
"""        out_dom: &mut Array<u32>,
        prev: u64,
        info: &mut Array<u32>,
        #[comptime] nl: u32,
        #[comptime] nl3: u32,
        #[comptime] sp: u32,
        #[comptime] cap: u32,
        #[comptime] base: u32,
        #[comptime] chunk_digits: u32,
        #[comptime] chunk_div: u32,
        #[comptime] hist: bool,
    ) -> u64 {
        let nh = comptime!(2 * nl);""")

rep("""        let passes = comptime!(sp.div_ceil(chunk_digits));
        #[unroll]
        for pass in 0..passes {
            // The top two limbs as one u32 (see above), then one limb a step.""",
"""        let passes = comptime!(sp.div_ceil(chunk_digits));
        let mut dg = Array::<u32>::new(comptime!(if hist { sp } else { 1 }) as usize);
        let mut p_dupc = 0xFFFFu32;
        let mut p_cross = 0xFFFFu32;
        let mut dlo_pos = 0u32;
        #[unroll]
        for pass in 0..passes {
            // The top two limbs as one u32 (see above), then one limb a step.""")

rep("""                        let ends = above && in_run && dx != comptime!(base - 1);
                        dlo = select(ends, dx, dlo);""",
"""                        let ends = above && in_run && dx != comptime!(base - 1);
                        if comptime!(hist) {
                            dg[pos as usize] = dx;
                            dlo_pos = select(ends, comptime!(pos).runtime(), dlo_pos);
                            let pn = comptime!(pass + 1).runtime();
                            p_dupc = select(dupc != 0u32 && p_dupc == 0xFFFFu32, pn, p_dupc);
                            p_cross = select(
                                (cbit & prev) != 0u64 && p_cross == 0xFFFFu32,
                                pn,
                                p_cross,
                            );
                        }
                        dlo = select(ends, dx, dlo);""")

rep("""        out_c0[0] = c0;
        out_dup[0] = dup;
        out_dom[0] = dom_lo;
        out_dom[1] = dom_hi;
        run
    }""",
"""        if comptime!(hist) {
            let mut lo = c0;
            if one_more {
                lo = dlo_pos + 1u32;
            }
            let mut seen = 0u64;
            let mut idx = 0xFFFFu32;
            let mut cnt = 0u32;
            #[unroll]
            for jj in 0..sp {
                let pos = comptime!(sp - 1 - jj);
                if comptime!(pos).runtime() >= lo {
                    let bit = 1u64 << u64::cast_from(dg[pos as usize]);
                    if (seen & bit) != 0u64 && idx == 0xFFFFu32 {
                        idx = cnt;
                    }
                    seen |= bit;
                    cnt += 1u32;
                }
            }
            info[0] = p_dupc;
            info[1] = p_cross;
            info[2] = idx;
            info[3] = cnt;
            info[4] = lo;
        }
        out_c0[0] = c0;
        out_dup[0] = dup;
        out_dom[0] = dom_lo;
        out_dom[1] = dom_hi;
        run
    }""")

# ---- top_cert
rep("""        pw: &Array<u32>,
        res: &mut Array<u32>,
        #[comptime] base: u32,
        #[comptime] limbs: u32,
        #[comptime] cap: u32,
        #[comptime] s2: u32,
        #[comptime] s3: u32,
        #[comptime] chunk_digits: u32,
        #[comptime] chunk_div: u32,
    ) -> u64 {
        let nl2 = comptime!(2 * limbs);""",
"""        pw: &Array<u32>,
        res: &mut Array<u32>,
        pcube: u64,
        info: &mut Array<u32>,
        #[comptime] base: u32,
        #[comptime] limbs: u32,
        #[comptime] cap: u32,
        #[comptime] s2: u32,
        #[comptime] s3: u32,
        #[comptime] chunk_digits: u32,
        #[comptime] chunk_div: u32,
        #[comptime] hist: bool,
    ) -> u64 {
        let nl2 = comptime!(2 * limbs);""")

rep("""        let mut domb = Array::<u32>::new(2usize);
        let msq = cert_power(
            &mut a2,
            &e2,
            pw,
            &mut c0a,
            &mut dupa,
            &mut doma,
            nl2,
            nl3,
            s2,
            cap,
            base,
            chunk_digits,
            chunk_div,
        );
        let mcu = cert_power(
            &mut a3,
            &e3,
            pw,
            &mut c0b,
            &mut dupb,
            &mut domb,
            nl3,
            nl3,
            s3,
            cap,
            base,
            chunk_digits,
            chunk_div,
        );""",
"""        let mut domb = Array::<u32>::new(2usize);
        let mut isq = Array::<u32>::new(8usize);
        let mut icu = Array::<u32>::new(8usize);
        let msq = cert_power(
            &mut a2,
            &e2,
            pw,
            &mut c0a,
            &mut dupa,
            &mut doma,
            pcube,
            &mut isq,
            nl2,
            nl3,
            s2,
            cap,
            base,
            chunk_digits,
            chunk_div,
            hist,
        );
        let mcu = cert_power(
            &mut a3,
            &e3,
            pw,
            &mut c0b,
            &mut dupb,
            &mut domb,
            msq,
            &mut icu,
            nl3,
            nl3,
            s3,
            cap,
            base,
            chunk_digits,
            chunk_div,
            hist,
        );""")

rep("""        let mut kept = 0u32;
        if keep {
            kept = 1u32;
        }
        res[0] = kept;""",
"""        let mut kept = 0u32;
        if keep {
            kept = 1u32;
        }
        if comptime!(hist) {
            let p2 = comptime!(s2.div_ceil(chunk_digits));
            let p3 = comptime!(s3.div_ceil(chunk_digits));
            let ca = dupa[0] != 0u32;
            let cb = dupb[0] != 0u32;
            let cc = (msq & mcu) != 0u64;
            let cd = !ca && !cb && !cc && !keep;
            let cat = select(ca, 1u32, 0u32)
                | select(cb, 2u32, 0u32)
                | select(cc, 4u32, 0u32)
                | select(cd, 8u32, 0u32);
            let cu = Min::min(icu[0], icu[1]);
            // Without the parent: earliest sound detection, in passes done.
            let mut g = comptime!(p2 + p3 + 1).runtime();
            let mut gp = comptime!(p2 + p3 + 1).runtime();
            let sqd = ca;
            let sqdp = ca || (msq & pcube) != 0u64;
            if !keep {
                g = comptime!(p2 + p3).runtime();
                if cu != 0xFFFFu32 {
                    g = comptime!(p2).runtime() + cu;
                }
                gp = g;
                if sqd {
                    g = comptime!(p2).runtime();
                }
                if sqdp {
                    gp = comptime!(p2).runtime();
                }
                if isq[0] != 0xFFFFu32 {
                    g = isq[0];
                }
                let sm = Min::min(isq[0], isq[1]);
                if sm != 0xFFFFu32 {
                    gp = sm;
                }
            }
            info[0] = cat;
            info[1] = g;
            info[2] = gp;
            info[3] = isq[2];
            info[4] = icu[2];
            info[5] = isq[3];
            info[6] = icu[3];
            info[7] = select(sqd, 1u32, 0u32);
            info[8] = select(sqdp, 1u32, 0u32);
            info[9] = isq[4];
            info[10] = icu[4];
        }
        res[0] = kept;""")

# ---- top_kernel
rep("""        #[comptime] key_level: bool,
        #[comptime] nb: u32,
    ) {
        let m1 = comptime!(base - 1);
        let i = ABSOLUTE_POS_X;
        let slot = CUBE_POS_Y;
        if i < ntlay {""",
"""        #[comptime] key_level: bool,
        #[comptime] nb: u32,
        #[comptime] hist: bool,
    ) {
        let m1 = comptime!(base - 1);
        let i = ABSOLUTE_POS_X;
        let slot = CUBE_POS_Y;
        let mut h_act = 0u32;
        let mut h_cat = 0xFFFFu32;
        let mut h_g = 0xFFFFu32;
        let mut h_gp = 0xFFFFu32;
        let mut h_td2 = 0xFFFFu32;
        let mut h_td3 = 0xFFFFu32;
        let mut h_n2 = 0xFFFFu32;
        let mut h_n3 = 0xFFFFu32;
        let mut h_sqd = 0u32;
        let mut h_sqdp = 0u32;
        let mut h_kept = 0u32;
        if i < ntlay {""")

rep("""                let mut res = Array::<u32>::new(3usize);
                let mask = top_cert(
                    &a,
                    &e,
                    pw,
                    &mut res,
                    base,
                    limbs,
                    cap,
                    s2,
                    s3,
                    chunk_digits,
                    chunk_div,
                );
                if res[0] != 0u32 {""",
"""                let mut res = Array::<u32>::new(3usize);
                let mut info = Array::<u32>::new(16usize);
                let mut pcube = 0u64;
                if comptime!(hist) {
                    pcube = (u64::cast_from(tlay[(5u32 * ntlay + 2u32 * i + 1u32) as usize])
                        << 32u64)
                        | u64::cast_from(tlay[(5u32 * ntlay + 2u32 * i) as usize]);
                }
                let mask = top_cert(
                    &a,
                    &e,
                    pw,
                    &mut res,
                    pcube,
                    &mut info,
                    base,
                    limbs,
                    cap,
                    s2,
                    s3,
                    chunk_digits,
                    chunk_div,
                    hist,
                );
                if comptime!(hist) {
                    h_act = 1u32;
                    h_cat = info[0];
                    h_g = info[1];
                    h_gp = info[2];
                    h_td2 = select((info[0] & 1u32) != 0u32, info[3], 0xFFFFu32);
                    h_td3 = select((info[0] & 2u32) != 0u32, info[4], 0xFFFFu32);
                    h_n2 = info[5];
                    h_n3 = info[6];
                    h_sqd = info[7];
                    h_sqdp = info[8];
                    h_kept = res[0];
                }
                if res[0] != 0u32 {""")

rep("""            }
        }
        cube_done(ran, 0u32);
    }

    /// Stage 0b""",
"""            }
        }
        if comptime!(hist) {
            let o = comptime!(STAGES as u32);
            hist_add(ran, h_cat, o, 16u32);
            hist_add(ran, h_g, comptime!(o + 16), 40u32);
            hist_add(ran, h_gp, comptime!(o + 56), 40u32);
            let any = plane_max(h_act);
            let wg = plane_max(select(h_act != 0u32, h_g, 0u32));
            let wgp = plane_max(select(h_act != 0u32, h_gp, 0u32));
            let lead = UNIT_POS_PLANE == 0u32 && any != 0u32;
            hist_add(ran, select(lead, wg, 0xFFFFu32), comptime!(o + 96), 40u32);
            hist_add(ran, select(lead, wgp, 0xFFFFu32), comptime!(o + 136), 40u32);
            hist_add(ran, h_td2, comptime!(o + 176), 40u32);
            hist_add(ran, h_td3, comptime!(o + 216), 40u32);
            hist_add(ran, h_n2, comptime!(o + 256), 40u32);
            hist_add(ran, h_n3, comptime!(o + 296), 40u32);
            // misc: 0 active pairs, 1 square dead, 2 square dead with the
            // parent, 3 violations (dead with the parent but kept), 4 warps
            // with an active lane, 5 warps all square-dead, 6 warps all
            // square-dead with the parent, 7 active lanes in active warps.
            let alive = plane_max(select(h_act != 0u32 && h_sqd == 0u32, 1u32, 0u32));
            let alivep = plane_max(select(h_act != 0u32 && h_sqdp == 0u32, 1u32, 0u32));
            let viol = plane_sum(select(h_sqdp != 0u32 && h_kept != 0u32, 1u32, 0u32));
            let na = plane_sum(h_act);
            let nsq = plane_sum(h_sqd);
            let nsqp = plane_sum(h_sqdp);
            if lead {
                let m = comptime!(o + 336);
                ran[m as usize].fetch_add(na);
                ran[comptime!(m + 1) as usize].fetch_add(nsq);
                ran[comptime!(m + 2) as usize].fetch_add(nsqp);
                ran[comptime!(m + 3) as usize].fetch_add(viol);
                ran[comptime!(m + 4) as usize].fetch_add(1u32);
                ran[comptime!(m + 5) as usize].fetch_add(select(alive == 0u32, 1u32, 0u32));
                ran[comptime!(m + 6) as usize].fetch_add(select(alivep == 0u32, 1u32, 0u32));
                ran[comptime!(m + 7) as usize].fetch_add(na);
            }
        }
        cube_done(ran, 0u32);
    }

    /// Plane-aggregated histogram add: bins `off..off + n` of `ran` (after
    /// the stage counters), lane value `v` (0xFFFF: none).
    #[cube]
    fn hist_add(ran: &mut Array<Atomic<u32>>, v: u32, #[comptime] off: u32, #[comptime] n: u32) {
        #[unroll]
        for bin in 0..n {
            let c = plane_sum(select(v == comptime!(bin).runtime(), 1u32, 0u32));
            if UNIT_POS_PLANE == 0u32 && c > 0u32 {
                ran[comptime!(off + bin) as usize].fetch_add(c);
            }
        }
    }

    /// Stage 0b""")

# ---- host: JoinDevice field + tlay extension
rep("""    fc: [u32; 2],
    max_slots: usize,""",
"""    fc: [u32; 2],
    hist: bool,
    max_slots: usize,""")

rep("""        // n < 2^96 (`FieldSetup::new`) and the prefix blocks below 2^64.
        let (s_w, e_w) = (u32_words(fs.s), u32_words(fs.e - 1));""",
"""        let hist = std::env::var("NICE_EXP_TOP_HIST").is_ok_and(|v| v == "1");
        if hist {
            // The parent's pure cube digits (no closure), 2 words per entry.
            let big_w = fs.w * u128::from(fs.nparts);
            let (s, ei) = (fs.s, fs.e - 1);
            let n = fs.tlay.len();
            let mut pcm = vec![0u64; n];
            let nt = 8usize;
            let chunk = n.div_ceil(nt).max(1);
            std::thread::scope(|sc| {
                for (ci, out) in pcm.chunks_mut(chunk).enumerate() {
                    let base = &fs.base;
                    let tlay = &fs.tlay;
                    sc.spawn(move || {
                        for (j, o) in out.iter_mut().enumerate() {
                            let p0 = tlay[ci * chunk + j].0;
                            let a = (p0 * big_w).max(s);
                            let e = (p0 * big_w + big_w - 1).min(ei);
                            *o = base.cert_cube_digits(a, e, fs.jp.k);
                        }
                    });
                }
            });
            for m in pcm {
                tl.push(m as u32);
                tl.push((m >> 32) as u32);
            }
        }
        // n < 2^96 (`FieldSetup::new`) and the prefix blocks below 2^64.
        let (s_w, e_w) = (u32_words(fs.s), u32_words(fs.e - 1));""")

rep("""                let w = u32_words(u128::from(fs.fc));
                [w[0], w[1]]
            },
            max_slots,""",
"""                let w = u32_words(u128::from(fs.fc));
                [w[0], w[1]]
            },
            hist,
            max_slots,""")

rep("""        let ran = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; expect.len()]));
        let nran = expect.len();""",
"""        let nran = expect.len();
        let nran_top = nran + if self.hist { HIST_N } else { 0 };
        let ran = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; nran_top]));""")

rep("""                ArrayArg::from_raw_parts(self.tlay.clone(), 5 * ntl),""",
"""                ArrayArg::from_raw_parts(self.tlay.clone(), if self.hist { 7 } else { 5 } * ntl),""")

rep("""                ArrayArg::from_raw_parts(ran.clone(), nran),
                self.ntlay,
                self.nroots,
                self.w_f0,""",
"""                ArrayArg::from_raw_parts(ran.clone(), nran_top),
                self.ntlay,
                self.nroots,
                self.w_f0,""")

rep("""                cd16,
                cdiv16,
                self.key_level,
                self.nb,
            );""",
"""                cd16,
                cdiv16,
                self.key_level,
                self.nb,
                self.hist,
            );""")

rep("""    fn ensure_ran(&self, ran: &[u32], expect: &[u32; STAGES]) -> Result<(), NotRun> {
        if ran == expect.as_slice() {
            return Ok(());
        }""",
"""    fn ensure_ran(&self, ran: &[u32], expect: &[u32; STAGES]) -> Result<(), NotRun> {
        if ran.len() > STAGES {
            let mut h = TOP_HIST.lock().expect("hist lock");
            if h.len() < ran.len() - STAGES {
                h.resize(ran.len() - STAGES, 0);
            }
            for (x, &r) in h.iter_mut().zip(&ran[STAGES..]) {
                *x += u64::from(r);
            }
        }
        let ran = &ran[..STAGES.min(ran.len())];
        if ran == expect.as_slice() {
            return Ok(());
        }""")

rep("""const STAGES: usize = 6;""",
"""const STAGES: usize = 6;
/// Histogram words after the stage counters (`NICE_EXP_TOP_HIST=1`).
const HIST_N: usize = 352;
/// The top kernel's histograms, summed over batches (`NICE_EXP_TOP_HIST=1`).
pub static TOP_HIST: std::sync::Mutex<Vec<u64>> = std::sync::Mutex::new(Vec::new());
/// Takes (and clears) the summed histograms.
pub fn take_top_hist() -> Vec<u64> {
    std::mem::take(&mut *TOP_HIST.lock().expect("hist lock"))
}""")

# ---- harness: reset after warm-up, print after
rep("""            let warm = FieldSize::new(start - warm_size, start);
            run_routed(ctx, base, &warm);""",
"""            let warm = FieldSize::new(start - warm_size, start);
            run_routed(ctx, base, &warm);
            let _ = super::take_top_hist();""")

rep("""            if compare {
                let t = std::time::Instant::now();
                let mut stride = Vec::new();""",
"""            let h = super::take_top_hist();
            if !h.is_empty() {
                let v: Vec<String> = h.iter().map(u64::to_string).collect();
                eprintln!("TOP_HIST base={base} size={size} n={n} {}", v.join(","));
            }
            if compare {
                let t = std::time::Instant::now();
                let mut stride = Vec::new();""")

# ---- test kernel call sites
rep("""                    let mut res = Array::<u32>::new(3usize);
                    let mask = top_cert(
                        &a,
                        &e,
                        pw,
                        &mut res,
                        base,
                        limbs,
                        cap,
                        s2,
                        s3,
                        chunk_digits,
                        chunk_div,
                    );""",
"""                    let mut res = Array::<u32>::new(3usize);
                    let mut info = Array::<u32>::new(16usize);
                    let mask = top_cert(
                        &a,
                        &e,
                        pw,
                        &mut res,
                        0u64,
                        &mut info,
                        base,
                        limbs,
                        cap,
                        s2,
                        s3,
                        chunk_digits,
                        chunk_div,
                        false,
                    );""")

rep("""                    if comptime!(part == 0) {
                        let m = cert_power(
                            &mut a2,
                            &e2,
                            pw,
                            &mut c0,
                            &mut dup,
                            &mut dom,
                            nl2,
                            nl3,
                            s2,
                            cap,
                            base,
                            chunk_digits,
                            chunk_div,
                        );""",
"""                    if comptime!(part == 0) {
                        let mut info = Array::<u32>::new(8usize);
                        let m = cert_power(
                            &mut a2,
                            &e2,
                            pw,
                            &mut c0,
                            &mut dup,
                            &mut dom,
                            0u64,
                            &mut info,
                            nl2,
                            nl3,
                            s2,
                            cap,
                            base,
                            chunk_digits,
                            chunk_div,
                            false,
                        );""")
rep("""                        let m = cert_power(
                            &mut a3,
                            &e3,
                            pw,
                            &mut c0,
                            &mut dup,
                            &mut dom,
                            nl3,
                            nl3,
                            s3,
                            cap,
                            base,
                            chunk_digits,
                            chunk_div,
                        );""",
"""                        let m = cert_power(
                            &mut a3,
                            &e3,
                            pw,
                            &mut c0,
                            &mut dup,
                            &mut dom,
                            0u64,
                            &mut info,
                            nl3,
                            nl3,
                            s3,
                            cap,
                            base,
                            chunk_digits,
                            chunk_div,
                            false,
                        );""")
open(p, "w").write(s)
print("patched", p)

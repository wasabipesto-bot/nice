//! mo_ceiling: a counting study of the middle-out join's pairing (scratch branch `exp/mo-ceiling`, not for
//! merging). For one slice it rebuilds the CPU reference's own objects (parents, tops, key, classes, probes,
//! children: the preamble of `cpu::slice_join`, copied) and counts, per job, what each chunk order and each
//! extra test would do: kept (probe, chunk) visits, ORs, records, survivors, lane slots. Every variant is
//! exact or checked: discarded survivors are verified by brute force on the full digits of n² and n³.
//!
//! Usage: mo_ceiling <base> <pip> <threads> [greedy]
//! Prints one `VAR <name> key=value ...` line per variant and a `Q0REF` line with `slice_join`'s own counts.

#![allow(clippy::many_single_char_names, clippy::too_many_lines, clippy::cast_possible_truncation)]

use nice_common::midout::arith::{U384, unique_digits};
use nice_common::midout::coord::Coord;
use nice_common::midout::cpu::{
    self, Base, Parent, Shape, Top, child_mask, key_digits, parents, prefilter, unit_tops,
};
use nice_common::midout::mask::Mask;
use std::cmp::Reverse;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};

const NH: usize = 32;

#[derive(Clone, Default, Debug)]
struct St {
    jobs: u64,
    children: u64,
    chunks: u64,
    flat: u64,
    dead_plain: u64, // common & top mask (today's skip) under this order
    dead_a: u64,     // self-collision of the extended certificate
    dead_b: u64,     // common & (top ∪ ext)
    dead_c: u64,     // a or b
    dead_clip: u64,  // chunk interval outside the top's (range ends)
    kept: u64,
    ors: u64, // Σ over kept visits of digits ORed
    records: u64,
    surv: u64,
    checked: u64,
    hist: [u64; NH], // extended digit count per visit (all visits)
    hist_kept: [u64; NH],
    // lane model: groups of G consecutive chunks of a job; a probe is listed if any chunk of the group keeps it
    listed16: u64,
    lane16: u64,
    wpop16: u64, // Σ listed × nch × (max over kept lanes of digits ORed)
    wext16: u64, // Σ listed × nch × (max extra ext digits over kept lanes)
    listed64: u64,
    lane64: u64,
    wpop64: u64,
    wext64: u64,
    // the oracle skip: a probe listed for a group only if some chunk of it gives a nonzero word
    listed16_or: u64,
    lane16_or: u64,
    lane64_or: u64,
    // exactness of discarded survivors (relative to today's word, same order)
    disc_surv: u64,
    disc_checked: u64, // discarded ones that pass the prefilter
    disc_nice: u64,    // must be 0
    disc_claim_ok: u64,
    disc_claim_bad: u64, // must be 0: the extended digits differ from n's own, or no repeat found
    // Q3 (code order only)
    q3_pairs: u64,
    q3_dead_pairs: u64,
    q3_records: u64,
    q3_surv: u64,
    q3_skip: u64,
    q3_viol: u64, // a survivor the dead word removes that passes the prefilter: must be 0
    // Q4 (code order only)
    q4_plain: u64,
    q4_trie_h: u64,
    q4_trie_mask: u64,
    q4_trie_mask_kept: u64,
    // Q4 under the lane model: per round, the listed probes; slot ORs = digits, or digits − LCP with the
    // previous listed probe (probes in mask order), × the round's chunks
    q4l_plain: u64,
    q4l_trie: u64,
    // Q4 in lockstep: the round's listed probes (mask order) cut into 16 contiguous stream segments; a wave of
    // 4 streams (64 lanes) or 2 streams (32 lanes) pays, per step, the largest ORs among its streams
    q4w4_17: u64,
    q4w4_len: u64,
    q4w4_trie: u64,
    q4w2_17: u64,
    q4w2_len: u64,
    q4w2_trie: u64,
}

impl St {
    fn add(&mut self, o: &St) {
        macro_rules! a { ($($f:ident),*) => { $( self.$f += o.$f; )* } }
        a!(jobs, children, chunks, flat, dead_plain, dead_a, dead_b, dead_c, dead_clip, kept, ors, records, surv,
           checked, listed16, lane16, wpop16, wext16, listed64, lane64, wpop64, wext64, listed16_or, lane16_or, lane64_or, disc_surv, disc_checked,
           disc_nice, disc_claim_ok, disc_claim_bad, q3_pairs, q3_dead_pairs, q3_records, q3_surv, q3_skip, q3_viol,
           q4_plain, q4_trie_h, q4_trie_mask, q4_trie_mask_kept, q4l_plain, q4l_trie,
           q4w4_17, q4w4_len, q4w4_trie, q4w2_17, q4w2_len, q4w2_trie);
        for i in 0..NH {
            self.hist[i] += o.hist[i];
            self.hist_kept[i] += o.hist_kept[i];
        }
    }
    fn line(&self, name: &str) -> String {
        let mut s = format!("VAR {name}");
        macro_rules! p { ($($f:ident),*) => { $( s += &format!(" {}={}", stringify!($f), self.$f); )* } }
        p!(jobs, children, chunks, flat, dead_plain, dead_a, dead_b, dead_c, dead_clip, kept, ors, records, surv,
           checked, listed16, lane16, wpop16, wext16, listed64, lane64, wpop64, wext64, listed16_or, lane16_or, lane64_or, disc_surv, disc_checked,
           disc_nice, disc_claim_ok, disc_claim_bad, q3_pairs, q3_dead_pairs, q3_records, q3_surv, q3_skip, q3_viol,
           q4_plain, q4_trie_h, q4_trie_mask, q4_trie_mask_kept, q4l_plain, q4l_trie,
           q4w4_17, q4w4_len, q4w4_trie, q4w2_17, q4w2_len, q4w2_trie);
        let last = self.hist.iter().rposition(|&x| x > 0).map_or(0, |i| i + 1);
        s += &format!(" hist={:?}", &self.hist[..last]);
        let last = self.hist_kept.iter().rposition(|&x| x > 0).map_or(0, |i| i + 1);
        s += &format!(" hist_kept={:?}", &self.hist_kept[..last]);
        s
    }
}

/// The certificate of `[a, c]` at positions `>= kpos`, without stopping at a repeat: the union of the
/// constant digits, whether two of them repeat, the number of constant positions, and per power the
/// constant positions `[lo, len)` (lo = len when none). Same walk as `cpu::top_cert_split`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Cert<M> {
    mask: M,
    rep: bool,
    npos: u32,
    pos: [(u32, u32); 2],
    dig: [[u8; 48]; 2], // digits at the constant positions (by position)
}

fn cert_generic<M: Mask>(b: u32, a: u128, c: u128, kpos: u32) -> Cert<M> {
    let (xa, xc) = (U384::from_u128(a), U384::from_u128(c));
    let (sa, sc) = (xa.mul(&xa), xc.mul(&xc));
    let (ca, cc) = (sa.mul(&xa), sc.mul(&xc));
    let mut out = Cert { mask: M::default(), rep: false, npos: 0, pos: [(0, 0); 2], dig: [[0; 48]; 2] };
    for (w, (p, q)) in [(sa, sc), (ca, cc)].into_iter().enumerate() {
        let (dp, dq) = (p.digits(u64::from(b)), q.digits(u64::from(b)));
        let len = dp.len() as u32;
        out.pos[w] = (len, len);
        if dp.len() != dq.len() {
            continue;
        }
        let mut j = dp.len();
        while j > kpos as usize {
            j -= 1;
            if dp[j] != dq[j] {
                break;
            }
            let bit = M::bit(u32::from(dp[j]));
            if !(out.mask & bit).is_zero() {
                out.rep = true;
            }
            out.mask |= bit;
            out.npos += 1;
            out.pos[w].0 = j as u32;
            out.dig[w][j] = dp[j];
        }
    }
    out
}

#[inline]
fn bits_u384(x: &U384, lo: u32) -> u32 {
    // 6 bits at bit offset lo
    let l = (lo / 64) as usize;
    let o = lo % 64;
    let mut v = x.0[l] >> o;
    if o > 58 && l + 1 < 6 {
        v |= x.0[l + 1] << (64 - o);
    }
    (v & 63) as u32
}

fn bitlen(x: &U384) -> u32 {
    for i in (0..6).rev() {
        if x.0[i] != 0 {
            return 64 * i as u32 + 64 - x.0[i].leading_zeros();
        }
    }
    0
}

/// [`cert_generic`] for base 64 by bit fields (cross-checked against it at start).
fn cert_b64<M: Mask>(a: u128, c: u128, kpos: u32) -> Cert<M> {
    let (xa, xc) = (U384::from_u128(a), U384::from_u128(c));
    let (sa, sc) = (xa.mul(&xa), xc.mul(&xc));
    let (ca, cc) = (sa.mul(&xa), sc.mul(&xc));
    let mut out = Cert { mask: M::default(), rep: false, npos: 0, pos: [(0, 0); 2], dig: [[0; 48]; 2] };
    for (w, (p, q)) in [(sa, sc), (ca, cc)].into_iter().enumerate() {
        let (lp, lq) = (bitlen(&p).div_ceil(6), bitlen(&q).div_ceil(6));
        out.pos[w] = (lp, lp);
        if lp != lq {
            continue;
        }
        let mut hb: i64 = -1;
        for i in (0..6).rev() {
            let x = p.0[i] ^ q.0[i];
            if x != 0 {
                hb = 64 * i as i64 + 63 - i64::from(x.leading_zeros());
                break;
            }
        }
        let lo = if hb < 0 { kpos } else { kpos.max((hb / 6) as u32 + 1) };
        if lo >= lp {
            continue;
        }
        out.pos[w].0 = lo;
        for j in (lo..lp).rev() {
            let d = bits_u384(&p, 6 * j);
            let bit = M::bit(d);
            if !(out.mask & bit).is_zero() {
                out.rep = true;
            }
            out.mask |= bit;
            out.npos += 1;
            out.dig[w][j as usize] = d as u8;
        }
    }
    out
}

#[derive(Clone, Copy)]
struct Ch<M> {
    m: M,
    pm: M,
    l: u64,
    pi: u32,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Ivl {
    None,
    Tight,
    Cell(u32),
}

struct Ctx<'a, M: Mask> {
    base: &'a Base,
    sh: Shape,
    b: u32,
    ps: &'a [Parent<M>],
    bkk: u128,
    bk1: u128,
    pw4: u128,
    fast: bool,
}

impl<M: Mask> Ctx<'_, M> {
    fn cert(&self, a: u128, c: u128) -> Cert<M> {
        if self.fast { cert_b64(a, c, self.sh.k) } else { cert_generic(self.b, a, c, self.sh.k) }
    }
}

struct Chunk<M> {
    common: M,
    valid: u64,
    l1: u64,
    l2: u64,
    idx: Vec<u32>, // into the job's children
}

fn build_chunks<M: Mask>(ch: &[Ch<M>], order: &[u32], csz: usize) -> (Vec<Chunk<M>>, Vec<Vec<u64>>) {
    let mut out = Vec::new();
    let mut slabs = Vec::new();
    for g in order.chunks(csz) {
        let mut common = !M::default();
        let mut sl = vec![0u64; 128 * csz.div_ceil(64)];
        let (mut l1, mut l2) = (u64::MAX, 0);
        for (i, &ci) in g.iter().enumerate() {
            let c = &ch[ci as usize];
            common &= c.m;
            l1 = l1.min(c.l);
            l2 = l2.max(c.l);
            let mut y = c.m;
            while !y.is_zero() {
                sl[(y.trailing_zeros() as usize) * csz.div_ceil(64) + i / 64] |= 1u64 << (i % 64);
                y = y.clear_lowest();
            }
        }
        let n = g.len();
        out.push(Chunk {
            common,
            valid: if n >= 64 { !0 } else { (1u64 << n) - 1 },
            l1,
            l2,
            idx: g.to_vec(),
        });
        slabs.push(sl);
    }
    (out, slabs)
}

/// One job under one order and one interval kind: the counts, with the exactness check of every survivor
/// that the extended certificate removes relative to today's top-only word.
#[allow(clippy::too_many_arguments)]
fn eval<M: Mask>(
    cx: &Ctx<M>,
    d: u32,
    ch: &[Ch<M>],
    probes: &[&Top<M>],
    tcert: &[Cert<M>],
    order: &[u32],
    csz: usize,
    ivl: Ivl,
    extras: bool,
    st: &mut St,
) {
    let (chunks, slabs) = build_chunks(ch, order, csz);
    let wpc = csz.div_ceil(64);
    st.jobs += 1;
    st.children += ch.len() as u64;
    st.chunks += chunks.len() as u64;
    st.flat += (chunks.len() * probes.len()) as u64;
    let dterm = u128::from(d) * cx.bk1;
    // per-chunk interval of L
    let ivs: Vec<(u128, u128)> = chunks
        .iter()
        .map(|q| match ivl {
            Ivl::None => (0, cx.pw4 - 1),
            Ivl::Tight => (u128::from(q.l1), u128::from(q.l2)),
            Ivl::Cell(j) => {
                let cell = |l: u64| u128::from(l) * (1u128 << j) / cx.pw4;
                let lo_of = |x: u128| (x * cx.pw4).div_ceil(1u128 << j);
                (lo_of(cell(q.l1)), lo_of(cell(q.l2) + 1) - 1)
            }
        })
        .collect();
    // Q3 dead words (code order only)
    let mut dead3: Vec<Vec<u64>> = Vec::new();
    if extras && csz == 64 {
        let b = u128::from(cx.b);
        let b11 = cx.base.pw[(cx.sh.k + 1) as usize];
        for q in &chunks {
            let mut dw = vec![0u64; cx.b as usize];
            for (i, &ci) in q.idx.iter().enumerate() {
                let c = &ch[ci as usize];
                let r = cx.ps[c.pi as usize].r + dterm;
                let r2 = (r % b11) * (r % b11) % b11; // r < b^10 < 2^61, r² < 2^122
                let r3 = mm(r2, r % b11, b11);
                let d2 = ((r2 / cx.bkk) % b) as u32;
                let d3 = ((r3 / cx.bkk) % b) as u32;
                let r0 = (r % b) as u32;
                for a0 in 0..cx.b {
                    let e2 = (d2 + 2 * r0 * a0) % cx.b;
                    let e3 = ((u64::from(d3) + 3 * u64::from(r0) * u64::from(r0) * u64::from(a0)) % u64::from(cx.b)) as u32;
                    let add = M::bit(e2) | M::bit(e3);
                    st.q3_pairs += 1;
                    if e2 == e3 || !(c.m & add).is_zero() {
                        dw[a0 as usize] |= 1u64 << i;
                        st.q3_dead_pairs += 1;
                    }
                }
            }
            dead3.push(dw);
        }
    }
    // a round is 1,024 children (the kernel's fill): 16 chunks of 64, 32 of 32, 8 of 128 ("16" in the names)
    let rnd = (1024 / csz).max(1);
    let ngr16 = chunks.len().div_ceil(rnd);
    let ngr64 = chunks.len().div_ceil(64);
    let mut kept_flags = vec![false; chunks.len()];
    let mut rec_flags = vec![false; chunks.len()];
    let mut round_lists: Vec<Vec<u32>> = vec![Vec::new(); ngr16];
    let mut extra_of = vec![0u32; chunks.len()];
    let mut pop_of = vec![0u32; chunks.len()];
    // Q4 per chunk: the kept probes (indices), in probe order
    let mut keptlist: Vec<Vec<u32>> = if extras { vec![Vec::new(); chunks.len()] } else { Vec::new() };
    for (pi, tp) in probes.iter().enumerate() {
        let tc = &tcert[pi];
        let tpop = tp.mask.count_ones();
        let (p0, p1) = (tp.lo / cx.pw4, tp.hi);
        let base_n = p0 * cx.pw4; // = h·b^k + uval·b^f0
        for (qi, q) in chunks.iter().enumerate() {
            kept_flags[qi] = false;
            rec_flags[qi] = false;
            let plain_dead = !(q.common & tp.mask).is_zero();
            st.dead_plain += u64::from(plain_dead);
            let (mut un, mut rep, mut extra, mut cert) = (tp.mask, false, 0u32, None);
            if ivl != Ivl::None {
                let a = (base_n + ivs[qi].0).max(tp.lo);
                let c = (base_n + ivs[qi].1).min(p1);
                if a > c {
                    st.dead_clip += 1;
                    st.dead_c += 1;
                    st.hist[0] += 1;
                    continue;
                }
                let ce = cx.cert(a, c);
                un = ce.mask;
                rep = ce.rep;
                extra = ce.npos - tc.npos;
                cert = Some(ce);
            }
            st.hist[(extra as usize).min(NH - 1)] += 1;
            let bdead = !(q.common & un).is_zero();
            st.dead_a += u64::from(rep);
            st.dead_b += u64::from(bdead);
            let dead = rep || bdead;
            // the word, today's (top only) and the extended one
            let sl = &slabs[qi];
            let or_of = |mk: M, wi: usize| -> u64 {
                let mut acc = 0u64;
                let mut y = mk;
                while !y.is_zero() {
                    acc |= sl[(y.trailing_zeros() as usize) * wpc + wi];
                    y = y.clear_lowest();
                }
                acc
            };
            let nq = q.idx.len();
            let vw = |wi: usize| -> u64 {
                let lo = 64 * wi;
                let hi = (lo + 64).min(nq);
                if hi <= lo {
                    0
                } else if hi - lo == 64 {
                    !0
                } else {
                    (1u64 << (hi - lo)) - 1
                }
            };
            let w_ext_of = |wi: usize| -> u64 { if dead { 0 } else { !or_of(un, wi) & vw(wi) } };
            // survivors, and the discarded ones
            if ivl != Ivl::None {
              for wi in 0..wpc {
                let w_plain = if plain_dead { 0 } else { !or_of(tp.mask, wi) & vw(wi) };
                let mut disc = w_plain & !w_ext_of(wi);
                while disc != 0 {
                    let i = disc.trailing_zeros() as usize;
                    disc &= disc - 1;
                    let c = &ch[q.idx[64 * wi + i] as usize];
                    let nn = base_n + u128::from(c.l);
                    let nn2 = tp.h * cx.bkk + dterm + cx.ps[c.pi as usize].r;
                    assert_eq!(nn, nn2);
                    if nn < tp.lo || nn > tp.hi {
                        continue;
                    }
                    st.disc_surv += 1;
                    let pass = prefilter(cx.base, cx.sh.k, nn, tp.mhi);
                    st.disc_checked += u64::from(pass);
                    if unique_digits(nn, cx.b).1 {
                        st.disc_nice += 1;
                    }
                    // the claim, per n: n's own digits at the extended certificate's positions are its digits, and
                    // those digits with the bottom's 2k (positions 0..k) contain a repeat
                    let ce = cert.as_ref().unwrap();
                    let x = U384::from_u128(nn);
                    let s2 = x.mul(&x);
                    let s3 = s2.mul(&x);
                    let mut ok = true;
                    let mut seen = [0u8; 256];
                    let mut repeat = false;
                    for (w, v) in [s2, s3].iter().enumerate() {
                        let dg = v.digits(u64::from(cx.b));
                        for j in 0..cx.sh.k as usize {
                            let dj = dg.get(j).copied().unwrap_or(0);
                            seen[dj as usize] += 1;
                        }
                        let (lo, len) = ce.pos[w];
                        if dg.len() as u32 != len && lo < len {
                            ok = false;
                        }
                        for j in lo..len {
                            let dj = dg[j as usize];
                            if dj != ce.dig[w][j as usize] {
                                ok = false;
                            }
                            seen[dj as usize] += 1;
                        }
                    }
                    if seen.iter().any(|&s| s > 1) {
                        repeat = true;
                    }
                    if ok && repeat {
                        st.disc_claim_ok += 1;
                    } else {
                        st.disc_claim_bad += 1;
                    }
                }
              }
            }
            if dead {
                st.dead_c += 1;
                continue;
            }
            st.kept += 1;
            st.hist_kept[(extra as usize).min(NH - 1)] += 1;
            let pop = un.count_ones();
            st.ors += u64::from(pop);
            kept_flags[qi] = true;
            extra_of[qi] = extra;
            pop_of[qi] = pop;
            if extras {
                keptlist[qi].push(pi as u32);
            }
            for wi in 0..wpc {
            let w_ext = w_ext_of(wi);
            if w_ext != 0 {
                st.records += 1;
                rec_flags[qi] = true;
            }
            let mut w = w_ext;
            let w3 = if extras && csz == 64 { w_ext & !dead3[qi][(tp.h % u128::from(cx.b)) as usize] } else { 0 };
            if extras && csz == 64 {
                if w3 != 0 {
                    st.q3_records += 1;
                }
                if (vw(0) & !dead3[qi][(tp.h % u128::from(cx.b)) as usize]) == 0 {
                    st.q3_skip += 1;
                }
            }
            while w != 0 {
                let i = w.trailing_zeros() as usize;
                w &= w - 1;
                let c = &ch[q.idx[64 * wi + i] as usize];
                let nn = base_n + u128::from(c.l);
                if nn >= tp.lo && nn <= tp.hi {
                    st.surv += 1;
                    let pass = prefilter(cx.base, cx.sh.k, nn, tp.mhi);
                    st.checked += u64::from(pass);
                    if extras && csz == 64 {
                        if w3 & (1u64 << i) != 0 {
                            st.q3_surv += 1;
                        } else if pass {
                            st.q3_viol += 1;
                        }
                    }
                }
            }
            }
        }
        // lane model for this probe
        for (g, ngr, listed, lane, wpop, wext) in [
            (rnd, ngr16, &mut st.listed16, &mut st.lane16, &mut st.wpop16, &mut st.wext16),
            (64usize, ngr64, &mut st.listed64, &mut st.lane64, &mut st.wpop64, &mut st.wext64),
        ] {
            for gi in 0..ngr {
                let r = gi * g..((gi + 1) * g).min(chunks.len());
                let nch = r.len() as u64;
                let mut any = false;
                let (mut mp, mut me) = (0u32, 0u32);
                for qi in r {
                    if kept_flags[qi] {
                        any = true;
                        mp = mp.max(pop_of[qi]);
                        me = me.max(extra_of[qi]);
                    }
                }
                if any {
                    if g == rnd && extras {
                        round_lists[gi].push(pi as u32);
                    }
                    *listed += 1;
                    *lane += nch;
                    *wpop += nch * u64::from(mp);
                    *wext += nch * u64::from(me);
                }
            }
        }
        for (g, ngr, listed, lane) in [
            (rnd, ngr16, Some(&mut st.listed16_or), &mut st.lane16_or),
            (64usize, ngr64, None, &mut st.lane64_or),
        ] {
            let mut listed = listed;
            for gi in 0..ngr {
                let r = gi * g..((gi + 1) * g).min(chunks.len());
                let nch = r.len() as u64;
                if r.into_iter().any(|qi| rec_flags[qi]) {
                    if let Some(l) = listed.as_deref_mut() {
                        *l += 1;
                    }
                    *lane += nch;
                }
            }
        }
        let _ = tpop;
    }
    // Q4: ORs with sharing between consecutive kept probes of a chunk (digit lists in descending frequency)
    if extras {
        let mut freq = vec![0u64; 128];
        for tp in probes {
            let mut y = tp.mask;
            while !y.is_zero() {
                freq[y.trailing_zeros() as usize] += 1;
                y = y.clear_lowest();
            }
        }
        let mut rank: Vec<u32> = (0..cx.b).collect();
        rank.sort_by_key(|&x| (Reverse(freq[x as usize]), x));
        let seqs: Vec<Vec<u32>> = probes
            .iter()
            .map(|tp| rank.iter().copied().filter(|&v| !(tp.mask & M::bit(v)).is_zero()).collect())
            .collect();
        let lcp = |x: &[u32], y: &[u32]| x.iter().zip(y).take_while(|(a, b)| a == b).count() as u64;
        let mut by_h: Vec<u32> = (0..probes.len() as u32).collect();
        by_h.sort_by_key(|&i| probes[i as usize].h);
        let mut pos_h = vec![0u32; probes.len()];
        for (r, &i) in by_h.iter().enumerate() {
            pos_h[i as usize] = r as u32;
        }
        for kl in &keptlist {
            let total: u64 = kl.iter().map(|&i| seqs[i as usize].len() as u64).sum();
            st.q4_plain += total;
            let mut v: Vec<u32> = kl.clone();
            v.sort_by_key(|&i| pos_h[i as usize]);
            let mut prev: Option<&[u32]> = None;
            for &i in &v {
                let s = &seqs[i as usize];
                st.q4_trie_h += s.len() as u64 - prev.map_or(0, |p| lcp(p, s));
                prev = Some(s);
            }
            v.sort_by(|&x, &y| seqs[x as usize].cmp(&seqs[y as usize]));
            let mut prev: Option<&[u32]> = None;
            for &i in &v {
                let s = &seqs[i as usize];
                st.q4_trie_mask_kept += s.len() as u64 - prev.map_or(0, |p| lcp(p, s));
                prev = Some(s);
            }
        }
        // the same trie over all of the job's probes (if every probe were run on every chunk), per chunk
        let mut v: Vec<u32> = (0..probes.len() as u32).collect();
        v.sort_by(|&x, &y| seqs[x as usize].cmp(&seqs[y as usize]));
        let mut prev: Option<&[u32]> = None;
        let mut nodes = 0u64;
        for &i in &v {
            let s = &seqs[i as usize];
            nodes += s.len() as u64 - prev.map_or(0, |p| lcp(p, s));
            prev = Some(s);
        }
        st.q4_trie_mask += nodes * chunks.len() as u64;
        for (gi, rl) in round_lists.iter_mut().enumerate() {
            let nch = ((gi + 1) * rnd).min(chunks.len()) as u64 - (gi * rnd) as u64;
            rl.sort_by(|&x, &y| seqs[x as usize].cmp(&seqs[y as usize]));
            let mut prev: Option<&[u32]> = None;
            for &i in rl.iter() {
                let sq = &seqs[i as usize];
                st.q4l_plain += nch * sq.len() as u64;
                st.q4l_trie += nch * (sq.len() as u64 - prev.map_or(0, |p| lcp(p, sq)));
                prev = Some(sq);
            }
            let n = rl.len();
            let seg = n.div_ceil(16).max(1);
            // per stream: (17, digits, digits − LCP with the previous probe of the same stream)
            let streams: Vec<Vec<(u64, u64, u64)>> = (0..16)
                .map(|sx| {
                    let part = &rl[(sx * seg).min(n)..((sx + 1) * seg).min(n)];
                    let mut pv: Option<&[u32]> = None;
                    part.iter()
                        .map(|&i| {
                            let sq = &seqs[i as usize];
                            let l = sq.len() as u64;
                            let t = l - pv.map_or(0, |p| lcp(p, sq));
                            pv = Some(sq);
                            (17u64, l, t)
                        })
                        .collect()
                })
                .collect();
            for (nsw, a17, alen, atrie) in [
                (4usize, &mut st.q4w4_17, &mut st.q4w4_len, &mut st.q4w4_trie),
                (2usize, &mut st.q4w2_17, &mut st.q4w2_len, &mut st.q4w2_trie),
            ] {
                for w in 0..16 / nsw {
                    let ss = &streams[w * nsw..(w + 1) * nsw];
                    let steps = ss.iter().map(Vec::len).max().unwrap_or(0);
                    for t in 0..steps {
                        let (mut m17, mut ml, mut mt) = (0u64, 0u64, 0u64);
                        for sv in ss {
                            if let Some(&(x, y, z)) = sv.get(t) {
                                m17 = m17.max(x);
                                ml = ml.max(y);
                                mt = mt.max(z);
                            }
                        }
                        let lanes = nsw as u64 * nch;
                        *a17 += lanes * m17;
                        *alen += lanes * ml;
                        *atrie += lanes * mt;
                    }
                }
            }
        }
    }
}

fn mm(a: u128, c: u128, m: u128) -> u128 {
    if m < (1u128 << 63) {
        return (a * c) % m;
    }
    let mut acc: u128 = 0;
    for sh in [64u32, 32, 0] {
        let piece = (c >> sh) & 0xffff_ffff;
        acc = ((acc << 32) % m + (a * piece) % m) % m;
    }
    acc
}

#[derive(Clone, Debug)]
enum Ord_ {
    Code,
    Key(u32),
    Lex,
    LOrder,
    Hybrid(u32),
    Greedy,
}

#[derive(Clone, Debug)]
struct Var {
    name: String,
    ord: Ord_,
    csz: usize,
    ivl: Ivl,
    extras: bool,
}

fn run<M: Mask>(b: u32, pip: u128, threads: usize, greedy: bool, wide: bool, q6: bool) {
    let coord = Coord::for_base(b).unwrap();
    let sh = Shape::for_coord(&coord);
    let base = Base::new(&coord);
    let t0 = std::time::Instant::now();
    // Q0's reference: the code's own slice_join, on its own thread, while the study runs
    let q0 = std::thread::scope(|s| {
        let h = s.spawn(|| {
            let t = std::time::Instant::now();
            let c = cpu::slice_join::<M>(&base, sh, pip, |_, _, _| {});
            (c, t.elapsed().as_secs_f64())
        });
        study::<M>(&base, sh, b, pip, threads, greedy, wide, q6, t0);
        h.join().unwrap()
    });
    println!("Q0REF secs={:.1} {:?}", q0.1, q0.0);
}

#[allow(clippy::too_many_arguments)]
fn study<M: Mask>(
    base: &Base,
    sh: Shape,
    b: u32,
    pip: u128,
    threads: usize,
    greedy: bool,
    wide: bool,
    q6: bool,
    t0: std::time::Instant,
) {
    let bu = b as usize;
    let m = bu - 1;
    // --- the preamble of cpu::slice_join, copied (same objects, same order) ---
    let ps = parents::<M>(base, sh, pip);
    let step = base.pw[(sh.k - 1 - sh.f0) as usize];
    let next = AtomicUsize::new(0);
    let out: Mutex<Vec<Option<Vec<Top<M>>>>> = Mutex::new(vec![None; bu]);
    let tops_by_d: Vec<Vec<Top<M>>> = std::thread::scope(|s| {
        let hs: Vec<_> = (0..threads).map(|_| {
            s.spawn(|| {
                loop {
                    let d = next.fetch_add(1, Ordering::Relaxed);
                    if d >= bu {
                        break;
                    }
                    let mut tt = 0;
                    let t = unit_tops::<M>(base, sh, pip + d as u128 * step, &mut tt);
                    out.lock().unwrap()[d] = Some(t);
                }
            })
        }).collect();
        for h in hs {
            h.join().unwrap();
        }
        let v = std::mem::take(&mut *out.lock().unwrap());
        v
    })
    .into_iter()
    .map(Option::unwrap)
    .collect();
    let ntops: usize = tops_by_d.iter().map(Vec::len).sum();
    let digit_count = |it: &mut dyn Iterator<Item = M>| -> Vec<u64> {
        let mut f = vec![0u64; bu];
        for mut x in it {
            while !x.is_zero() {
                f[x.trailing_zeros() as usize] += 1;
                x = x.clear_lowest();
            }
        }
        f
    };
    let fp = digit_count(&mut ps.iter().map(|p| p.mask));
    let ft = digit_count(&mut tops_by_d.iter().flatten().map(|t| t.mask));
    let rank8 = key_digits(b, &fp, &ft);
    // the same rule over every digit (the key extended)
    let mut rank_all: Vec<u32> = (0..b).collect();
    rank_all.sort_by(|&x, &y| {
        let (x, y) = (x as usize, y as usize);
        (fp[y] as f64 * ft[y] as f64).partial_cmp(&(fp[x] as f64 * ft[x] as f64)).unwrap().then(x.cmp(&y))
    });
    assert_eq!(&rank_all[..8], &rank8[..], "extended key rule disagrees with key_digits");
    let keyk = |mk: M, k: u32| -> u128 {
        let mut kk = 0u128;
        for (i, &v) in rank_all.iter().take(k as usize).enumerate() {
            kk |= u128::from(!(mk & M::bit(v)).is_zero()) << (k as usize - 1 - i);
        }
        kk
    };
    let mut ps = ps;
    ps.sort_by_key(|p| (u64::from(p.cls) << 8) + (255 - keyk(p.mask, 8) as u64));
    let mut pseg = vec![0usize; m + 1];
    {
        let mut i = 0;
        for (c, seg) in pseg.iter_mut().enumerate().take(m) {
            *seg = i;
            while i < ps.len() && ps[i].cls as usize == c {
                i += 1;
            }
        }
        pseg[m] = ps.len();
    }
    let mut tseg: Vec<Vec<Vec<usize>>> = vec![vec![Vec::new(); m]; bu];
    for (d, tv) in tops_by_d.iter().enumerate() {
        for (i, t) in tv.iter().enumerate() {
            tseg[d][(t.h % m as u128) as usize].push(i);
        }
    }
    let pw4 = base.pw[sh.f0 as usize];
    let cx = Ctx {
        base,
        sh,
        b,
        ps: &ps,
        bkk: base.pw[sh.k as usize],
        bk1: base.pw[(sh.k - 1) as usize],
        pw4,
        fast: b == 64,
    };
    // the fast certificate against the generic one and against cpu::top_cert_split, on real tops and sub-intervals
    let mut nchk = 0u64;
    let mut x = 0x9E37_79B9_7F4A_7C15_u64 ^ (pip as u64);
    let mut rnd = || {
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        x
    };
    let mut top_npos: Vec<Vec<u32>> = Vec::with_capacity(bu);
    for tv in &tops_by_d {
        let mut v = Vec::with_capacity(tv.len());
        for t in tv {
            let ce = cx.cert(t.lo, t.hi);
            assert!(!ce.rep && ce.mask == t.mask, "top certificate mismatch h {}", t.h);
            v.push(ce.npos);
        }
        top_npos.push(v);
    }
    for tv in &tops_by_d {
        for t in tv.iter().step_by(97) {
            for _ in 0..8 {
                let span = 1u128 << (rnd() % 25);
                let a = t.lo + u128::from(rnd()) % (t.hi - t.lo + 1);
                let c = (a + span).min(t.hi);
                let g = cert_generic::<M>(b, a, c, sh.k);
                let f = cx.cert(a, c);
                assert_eq!(g, f, "fast cert != generic at [{a}, {c}]");
                let r = cpu::top_cert_split::<M>(base, a, c, sh.k, sh.k + 2);
                assert_eq!(r.map(|z| z.0), if g.rep { None } else { Some(g.mask) }, "cert != top_cert_split");
                // monotonicity: the sub-interval's certificate contains the top's, position by position
                let tc = cx.cert(t.lo, t.hi);
                for w in 0..2 {
                    if tc.pos[w].0 < tc.pos[w].1 {
                        assert!(g.pos[w].0 <= tc.pos[w].0 && g.pos[w].1 == tc.pos[w].1);
                        for j in tc.pos[w].0..tc.pos[w].1 {
                            assert_eq!(g.dig[w][j as usize], tc.dig[w][j as usize]);
                        }
                    }
                }
                nchk += 1;
            }
        }
    }
    eprintln!(
        "slice b{b} pip {pip}: {} parents, {ntops} tops, cert cross-checks {nchk} ok, setup {:.1}s",
        ps.len(),
        t0.elapsed().as_secs_f64()
    );
    println!("SETUP b={b} pip={pip} parents={} tops={ntops} certchecks={nchk} rank={rank_all:?}", ps.len());

    let mut vars: Vec<Var> = Vec::new();
    let v = |name: &str, ord: Ord_, csz: usize, ivl: Ivl, extras: bool| Var { name: name.into(), ord, csz, ivl, extras };
    vars.push(v("code", Ord_::Code, 64, Ivl::None, true));
    for k in [0u32, 2, 4, 6, 8, 10, 12, 16] {
        vars.push(v(&format!("key{k}"), Ord_::Key(k), 64, Ivl::None, false));
    }
    vars.push(v("lex", Ord_::Lex, 64, Ivl::None, true));
    vars.push(v("code_c32", Ord_::Code, 32, Ivl::None, false));
    vars.push(v("lex_c32", Ord_::Lex, 32, Ivl::None, false));
    vars.push(v("code_c128", Ord_::Code, 128, Ivl::None, false));
    vars.push(v("lorder_plain", Ord_::LOrder, 64, Ivl::None, false));
    vars.push(v("lorder_ext", Ord_::LOrder, 64, Ivl::Tight, false));
    vars.push(v("lorder_ext_c32", Ord_::LOrder, 32, Ivl::Tight, false));
    for j in 1..=6u32 {
        vars.push(v(&format!("hyb{j}_plain"), Ord_::Hybrid(j), 64, Ivl::None, false));
        vars.push(v(&format!("hyb{j}_cell"), Ord_::Hybrid(j), 64, Ivl::Cell(j), false));
        vars.push(v(&format!("hyb{j}_tight"), Ord_::Hybrid(j), 64, Ivl::Tight, false));
    }
    vars.push(v("code_tight", Ord_::Code, 64, Ivl::Tight, false));
    if greedy {
        vars.push(v("greedy", Ord_::Greedy, 64, Ivl::None, false));
    }
    if wide {
        // wide-only pass: chunk widths 128 and 256 with records (the default list above is unchanged)
        vars.clear();
        vars.push(v("code", Ord_::Code, 64, Ivl::None, true));
        vars.push(v("lex", Ord_::Lex, 64, Ivl::None, true));
        vars.push(v("code_c128", Ord_::Code, 128, Ivl::None, true));
        vars.push(v("lex_c128", Ord_::Lex, 128, Ivl::None, true));
        vars.push(v("key12_c128", Ord_::Key(12), 128, Ivl::None, false));
        vars.push(v("code_c256", Ord_::Code, 256, Ivl::None, false));
        vars.push(v("lex_c256", Ord_::Lex, 256, Ivl::None, true));
        vars.push(v("lorder_ext_c128", Ord_::LOrder, 128, Ivl::Tight, false));
        vars.push(v("hyb3_cell_c128", Ord_::Hybrid(3), 128, Ivl::Cell(3), false));
    }
    if q6 {
        // the base-65 pass (Q6): today's order, the best orders of Q1, Q2's L order and the first hybrids
        vars.clear();
        vars.push(v("code", Ord_::Code, 64, Ivl::None, true));
        vars.push(v("lex", Ord_::Lex, 64, Ivl::None, false));
        vars.push(v("key12", Ord_::Key(12), 64, Ivl::None, false));
        vars.push(v("lorder_ext", Ord_::LOrder, 64, Ivl::Tight, false));
        vars.push(v("hyb1_cell", Ord_::Hybrid(1), 64, Ivl::Cell(1), false));
        vars.push(v("hyb2_cell", Ord_::Hybrid(2), 64, Ivl::Cell(2), false));
        vars.push(v("hyb3_cell", Ord_::Hybrid(3), 64, Ivl::Cell(3), false));
    }
    if a_q6b() {
        // a second base-65 pass: the hybrids with more bits of L, and L order at 32
        vars.clear();
        vars.push(v("code", Ord_::Code, 64, Ivl::None, false));
        vars.push(v("hyb4_cell", Ord_::Hybrid(4), 64, Ivl::Cell(4), false));
        vars.push(v("hyb5_cell", Ord_::Hybrid(5), 64, Ivl::Cell(5), false));
        vars.push(v("hyb6_cell", Ord_::Hybrid(6), 64, Ivl::Cell(6), false));
        vars.push(v("lorder_ext_c32", Ord_::LOrder, 32, Ivl::Tight, false));
        vars.push(v("lorder_ext_c128", Ord_::LOrder, 128, Ivl::Tight, false));
    }
    let nv = vars.len();
    let njobs = m * bu;
    let next = AtomicUsize::new(0);
    let total: Mutex<Vec<St>> = Mutex::new(vec![St::default(); nv]);
    let done = AtomicUsize::new(0);
    std::thread::scope(|s| {
        for _ in 0..threads {
            s.spawn(|| {
                let mut acc = vec![St::default(); nv];
                let mut probes_i: Vec<usize> = Vec::new();
                loop {
                    let jb = next.fetch_add(1, Ordering::Relaxed);
                    if jb >= njobs {
                        break;
                    }
                    let (c, d) = (jb / bu, jb % bu);
                    let cc = (c + d) % m;
                    probes_i.clear();
                    for &rt in &base.roots {
                        let ct = (rt as usize + m - cc) % m;
                        probes_i.extend_from_slice(&tseg[d][ct]);
                    }
                    let probes: Vec<&Top<M>> = probes_i.iter().map(|&i| &tops_by_d[d][i]).collect();
                    let tcert: Vec<Cert<M>> = probes_i
                        .iter()
                        .map(|&i| {
                            let t = &tops_by_d[d][i];
                            let mut ce = Cert { mask: t.mask, rep: false, npos: top_npos[d][i], pos: [(0, 0); 2], dig: [[0; 48]; 2] };
                            ce.mask = t.mask;
                            ce
                        })
                        .collect();
                    let mut ch: Vec<Ch<M>> = Vec::new();
                    for (p, par) in ps.iter().enumerate().take(pseg[c + 1]).skip(pseg[c]) {
                        let x = child_mask(b, par, d as u32);
                        if !x.is_zero() {
                            ch.push(Ch { m: x, pm: par.mask, l: (par.r % pw4) as u64, pi: p as u32 });
                        }
                    }
                    let n = ch.len() as u32;
                    for (vi, var) in vars.iter().enumerate() {
                        let mut order: Vec<u32> = (0..n).collect();
                        let rr = |i: u32| ps[ch[i as usize].pi as usize].r;
                        match var.ord {
                            Ord_::Code => {}
                            Ord_::Key(k) => order.sort_by_cached_key(|&i| (Reverse(keyk(ch[i as usize].pm, k)), rr(i))),
                            Ord_::Lex => order.sort_by_cached_key(|&i| (Reverse(keyk(ch[i as usize].m, b)), rr(i))),
                            Ord_::LOrder => order.sort_by_key(|&i| ch[i as usize].l),
                            Ord_::Hybrid(j) => order.sort_by_cached_key(|&i| {
                                let c = &ch[i as usize];
                                (u128::from(c.l) * (1u128 << j) / pw4, Reverse(keyk(c.pm, 8)), rr(i))
                            }),
                            Ord_::Greedy => {
                                let mut rem: Vec<u32> = (0..n).collect();
                                order.clear();
                                while !rem.is_empty() {
                                    let f = rem.remove(0);
                                    order.push(f);
                                    let mut common = ch[f as usize].m;
                                    for _ in 1..var.csz {
                                        if rem.is_empty() {
                                            break;
                                        }
                                        let mut best = 0usize;
                                        let mut bs = 0u32;
                                        for (ri, &ci) in rem.iter().enumerate() {
                                            let s = (common & ch[ci as usize].m).count_ones();
                                            if ri == 0 || s > bs {
                                                bs = s;
                                                best = ri;
                                            }
                                        }
                                        let ci = rem.remove(best);
                                        common &= ch[ci as usize].m;
                                        order.push(ci);
                                    }
                                }
                            }
                        }
                        eval(&cx, d as u32, &ch, &probes, &tcert, &order, var.csz, var.ivl, var.extras, &mut acc[vi]);
                    }
                    let k = done.fetch_add(1, Ordering::Relaxed) + 1;
                    if k % 500 == 0 {
                        eprintln!("  {k}/{njobs} jobs, {:.0}s", t0.elapsed().as_secs_f64());
                    }
                }
                let mut t = total.lock().unwrap();
                for (a, b) in t.iter_mut().zip(&acc) {
                    a.add(b);
                }
            });
        }
    });
    let t = total.lock().unwrap();
    for (var, st) in vars.iter().zip(t.iter()) {
        println!("{} ord={:?} csz={} ivl={:?}", st.line(&var.name), var.ord, var.csz, var.ivl);
    }
    println!("TIME secs={:.1}", t0.elapsed().as_secs_f64());
}

fn a_q6b() -> bool {
    std::env::args().skip(4).any(|s| s == "q6b")
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let b: u32 = a[1].parse().unwrap();
    let pip: u128 = a[2].parse().unwrap();
    let threads: usize = a[3].parse().unwrap();
    let greedy = a.iter().skip(4).any(|s| s == "greedy");
    let wide = a.iter().skip(4).any(|s| s == "wide");
    let q6 = a.iter().skip(4).any(|s| s == "q6");
    if b <= 64 {
        run::<u64>(b, pip, threads, greedy, wide, q6);
    } else {
        run::<u128>(b, pip, threads, greedy, wide, q6);
    }
}

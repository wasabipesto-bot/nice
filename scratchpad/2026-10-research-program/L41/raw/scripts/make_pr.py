#!/usr/bin/env python3
"""make_pr.py FILE: the lean prefilter (FX + MT + GM + RC, no knobs) applied to 7832f89's common/src/cubecl_join.rs."""
import sys
p = sys.argv[1]
s = open(p).read()
def rep(old, new, n=1):
    global s
    c = s.count(old)
    assert c == n, (old[:90], c)
    s = s.replace(old, new)

# --- doc comment
rep("""    /// A pair inside the top's range is a join survivor
    /// (counted in `and_count`) and goes through the middle-digit prefilter
    /// there and then ([`walk_pf`]); only the pairs that pass it, about 6% at
    /// bases 57-64, are staged in shared memory, and the stage goes to the
    /// list once it is half full, checked after every 32 tops.
""", """    /// A pair inside the top's range is a join survivor
    /// (counted in `and_count`) and goes through the middle-digit prefilter
    /// there and then ([`walk_pf_lean`], or [`walk_pf`] for small test
    /// shapes); only the pairs that pass it, about 6% at bases 57-64, are
    /// staged in shared memory, and the stage goes to the list once it is
    /// half full, checked after every 32 tops. The range test is done per
    /// chunk, not per pair: only a clipped top (a block at the field's ends,
    /// whose range is not the whole `[0, w)`) can reject a residue, so the
    /// batch load marks the clipped tops in a word per chunk (`s_cw`), and a
    /// chunk with one clears their out-of-range pass bits before the walk.
    /// Every bit walked is then a join survivor, counted by popcount.
""")
rep("""    /// what it depends on: the wave load forms each entry's part once per
    /// 256 tops (`ac`: the two carries; `pc`: `2R | 3R² << 16`), the top
    /// chunk load the top's (`t_dm`: `D | seed << 16`), and a pair costs two
    /// multiply-adds mod `b^mid` and the digit tests, about 50 instructions.
    /// Rebuilding all `k2` digit columns of n² and n³ for every pair instead,
    /// as this kernel used to when it flushed the stage, was about 290.""",
"""    /// what it depends on: the wave load forms each entry's part once per
    /// 256 tops, the batch load the top's, and a pair costs two
    /// multiply-adds and the digit tests. At `mid = 2` (every production
    /// shape) the reduction mod `b²` and the two digits come from
    /// fixed-point arithmetic ([`walk_pf_lean`]): the entry holds `A·C` and
    /// `P` for each power (`A` the carry, `P` = `2R` or `3R²`, `C =
    /// ceil(2^32/b²)`), the top `ceil(D·2^32/b²)` (`t_dm`) and its
    /// certificate gated by its seed flag (`t_glo`, `t_ghi`), and a pair
    /// costs about 25 instructions. Elsewhere `ac`/`pc` pack the carries and
    /// `2R | 3R² << 16`, `t_dm` is `D | seed << 16`, and [`walk_pf`] reduces
    /// by division. Rebuilding all `k2` digit columns of n² and n³ for every
    /// pair instead, as this kernel used to when it flushed the stage, was
    /// about 290.
    ///
    /// The digit masks are held bit-reversed in this kernel when the lean
    /// prefilter runs (digit d at bit 63 - d), entries' and tops' alike: the
    /// AND is the same disjointness test under any labelling of the bits,
    /// and the prefilter reads digit g as the sign bit of `hi32(seen << g)`.""")

# --- signature
rep("""        nwork: u32,
        nbp: u32,
        surv_cap: u32,
        #[comptime] base: u32,""", """        nwork: u32,
        nbp: u32,
        surv_cap: u32,
        w_f0: u32,
        #[comptime] base: u32,""")
rep("""        let v_digits = comptime!(if key_level && f0 <= mid {
            (k - 1 - f0).min(mid + 1 - f0)
        } else {
            0
        });
        let mut t_lo""", """        let v_digits = comptime!(if key_level && f0 <= mid {
            (k - 1 - f0).min(mid + 1 - f0)
        } else {
            0
        });
        // The fixed-point prefilter ([`walk_pf_lean`]) at mid = 2, k >= 2:
        // C = ceil(2^32/b²), and 2^32 = Q·b² + R.
        let lean = comptime!(mid == 2 && k >= 2);
        let fx_c = comptime!(fx_consts(base).0);
        let fx_q = comptime!(fx_consts(base).1);
        let fx_r = comptime!(fx_consts(base).2);
        let bsq = comptime!(base * base);
        let mut t_lo""")
rep("""        let mut t_dm = SharedMemory::<u32>::new(comptime!(TOP_CAP as usize));""",
"""        let mut t_dm = SharedMemory::<u32>::new(comptime!(TOP_CAP as usize));
        // The tops' certificates where their seed flag is set, else 0.
        let mut t_glo =
            SharedMemory::<u32>::new(comptime!(if lean { TOP_CAP as usize } else { 1 }));
        let mut t_ghi =
            SharedMemory::<u32>::new(comptime!(if lean { TOP_CAP as usize } else { 1 }));
        // Per chunk of 32 tops: bit i set iff top i is clipped.
        let mut s_cw = SharedMemory::<Atomic<u32>>::new(comptime!((TOP_CAP / 32) as usize));""")
rep("""        if UNIT_POS_X == 0u32 {
            s_cnt[0].store(0u32);
        }
        sync_cube();

        let mut w = CUBE_POS_X;""", """        if UNIT_POS_X == 0u32 {
            s_cnt[0].store(0u32);
        }
        if UNIT_POS_X < comptime!(TOP_CAP / 32) {
            s_cw[UNIT_POS_X as usize].store(0u32);
        }
        sync_cube();

        let mut w = CUBE_POS_X;""")
# --- batch load
rep("""                    let r8 = TOP_REC_WORDS * t;
                    t_lo[UNIT_POS_X as usize] = top_rec[(r8 + 2u32) as usize];
                    t_hi[UNIT_POS_X as usize] = top_rec[(r8 + 3u32) as usize];
                    t_rlo[UNIT_POS_X as usize] = top_rec[(r8 + 4u32) as usize];
                    t_rhi[UNIT_POS_X as usize] = top_rec[(r8 + 5u32) as usize];
                    t_id[UNIT_POS_X as usize] = t;
                    // D (below b^mid <= 2^12) and the seed flag.
                    t_dm[UNIT_POS_X as usize] = (top_rec[(r8 + 6u32) as usize] / dm_div)
                        | (top_rec[(r8 + 7u32) as usize] << 16u32);
                }""", """                    let r8 = TOP_REC_WORDS * t;
                    let mut lo = top_rec[(r8 + 2u32) as usize];
                    let mut hi = top_rec[(r8 + 3u32) as usize];
                    if comptime!(lean) {
                        let l0 = lo;
                        lo = hi.reverse_bits();
                        hi = l0.reverse_bits();
                    }
                    t_lo[UNIT_POS_X as usize] = lo;
                    t_hi[UNIT_POS_X as usize] = hi;
                    let rlo = top_rec[(r8 + 4u32) as usize];
                    let rhi = top_rec[(r8 + 5u32) as usize];
                    t_rlo[UNIT_POS_X as usize] = rlo;
                    t_rhi[UNIT_POS_X as usize] = rhi;
                    if rlo != 0u32 || rhi != w_f0 {
                        s_cw[(UNIT_POS_X / 32u32) as usize].fetch_or(1u32 << (UNIT_POS_X % 32u32));
                    }
                    t_id[UNIT_POS_X as usize] = t;
                    // D (below b^mid <= 2^12) and the seed flag.
                    let dm = top_rec[(r8 + 6u32) as usize] / dm_div;
                    let seed = top_rec[(r8 + 7u32) as usize];
                    if comptime!(lean) {
                        // ceil(D·2^32/b²) = D·Q + ceil(D·R/b²).
                        t_dm[UNIT_POS_X as usize] = dm * fx_q + (dm * fx_r + comptime!(bsq - 1)) / bsq;
                        t_glo[UNIT_POS_X as usize] = select(seed != 0u32, lo, 0u32);
                        t_ghi[UNIT_POS_X as usize] = select(seed != 0u32, hi, 0u32);
                    } else {
                        t_dm[UNIT_POS_X as usize] = dm | (seed << 16u32);
                    }
                }""")
# --- wave load
rep("""                    let mut ac = Array::<u32>::new(ept as usize);
                    let mut pc = Array::<u32>::new(ept as usize);
                    #[unroll]
                    for j in 0..ept {
                        let sl = ws + UNIT_POS_X + comptime!(j * JOIN_WG);
                        mlo[j as usize] = 0xFFFF_FFFFu32;
                        mhi[j as usize] = 0xFFFF_FFFFu32;
                        rr[j as usize] = 0u32;
                        vv[j as usize] = 0u32;
                        ac[j as usize] = 0u32;
                        pc[j as usize] = 0u32;""", """                    let mut ac = Array::<u32>::new(ept as usize);
                    let mut pc = Array::<u32>::new(ept as usize);
                    // Lean: `ac`/`pc` the n² terms (A·C, P), `ac3`/`pc3` n³'s.
                    let mut ac3 = Array::<u32>::new(ept as usize);
                    let mut pc3 = Array::<u32>::new(ept as usize);
                    #[unroll]
                    for j in 0..ept {
                        let sl = ws + UNIT_POS_X + comptime!(j * JOIN_WG);
                        mlo[j as usize] = 0xFFFF_FFFFu32;
                        mhi[j as usize] = 0xFFFF_FFFFu32;
                        rr[j as usize] = 0u32;
                        vv[j as usize] = 0u32;
                        ac[j as usize] = 0u32;
                        pc[j as usize] = 0u32;
                        ac3[j as usize] = 0u32;
                        pc3[j as usize] = 0u32;""")
rep("""                                m |= (1u64 << u64::cast_from(g2)) | (1u64 << u64::cast_from(g3));
                                ac[j as usize] = (t2 / base) | ((t3 / base) << 16u32);""",
"""                                m |= (1u64 << u64::cast_from(g2)) | (1u64 << u64::cast_from(g3));
                                if comptime!(lean) {
                                    ac[j as usize] = (t2 / base) * fx_c;
                                    ac3[j as usize] = (t3 / base) * fx_c;
                                } else {
                                    ac[j as usize] = (t2 / base) | ((t3 / base) << 16u32);
                                }""")
rep("""                                pc[j as usize] = p2 | (p3 << 16u32);
                            } else {
                                ac[j as usize] = q0;
                                pc[j as usize] = q1;
                            }
                            mlo[j as usize] = u32::cast_from(m);
                            mhi[j as usize] = u32::cast_from(m >> 32u64);""", """                                if comptime!(lean) {
                                    pc[j as usize] = p2;
                                    pc3[j as usize] = p3;
                                } else {
                                    pc[j as usize] = p2 | (p3 << 16u32);
                                }
                            } else if comptime!(lean) {
                                ac[j as usize] = (q0 & 0xFFFFu32) * fx_c;
                                ac3[j as usize] = (q0 >> 16u32) * fx_c;
                                pc[j as usize] = q1 & 0xFFFFu32;
                                pc3[j as usize] = q1 >> 16u32;
                            } else {
                                ac[j as usize] = q0;
                                pc[j as usize] = q1;
                            }
                            if comptime!(lean) {
                                mlo[j as usize] = u32::cast_from(m >> 32u64).reverse_bits();
                                mhi[j as usize] = u32::cast_from(m).reverse_bits();
                            } else {
                                mlo[j as usize] = u32::cast_from(m);
                                mhi[j as usize] = u32::cast_from(m >> 32u64);
                            }""")
# --- chunk: range test on clipped tops, survivors by popcount; walk
rep("""                        #[unroll]
                        for j in 0..ept {
                            let mut x = pm[j as usize] & vv[j as usize];
                            let r0 = rr[j as usize];
                            while plane_any(x != 0u32) {
                                if x != 0u32 {
                                    let jt2 = jc + x.trailing_zeros();
                                    x &= x - 1u32;
                                    if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                        nand += 1u32;
                                        if walk_pf(
                                            ac[j as usize],
                                            pc[j as usize],
                                            t_dm[jt2 as usize],
                                            mlo[j as usize],
                                            mhi[j as usize],
                                            t_lo[jt2 as usize],
                                            t_hi[jt2 as usize],
                                            base,
                                            k,
                                            k2,
                                        ) {""", """                        // The range test, on the chunk's clipped tops only
                        // (none but in a field's edge blocks): their pass
                        // bits for residues outside the range are cleared,
                        // so every bit walked is a join survivor.
                        let cw = s_cw[(jc / 32u32) as usize].load();
                        if cw != 0u32 {
                            #[unroll]
                            for j in 0..ept {
                                let r0 = rr[j as usize];
                                let mut y = pm[j as usize] & vv[j as usize] & cw;
                                while y != 0u32 {
                                    let i = y.trailing_zeros();
                                    y &= y - 1u32;
                                    if r0 < t_rlo[(jc + i) as usize] || r0 >= t_rhi[(jc + i) as usize] {
                                        pm[j as usize] ^= 1u32 << i;
                                    }
                                }
                            }
                        }
                        #[unroll]
                        for j in 0..ept {
                            nand += (pm[j as usize] & vv[j as usize]).count_ones();
                        }
                        #[unroll]
                        for j in 0..ept {
                            let mut x = pm[j as usize] & vv[j as usize];
                            let r0 = rr[j as usize];
                            while plane_any(x != 0u32) {
                                if x != 0u32 {
                                    let jt2 = jc + x.trailing_zeros();
                                    x &= x - 1u32;
                                    let mut pass = false;
                                    if comptime!(lean) {
                                        pass = walk_pf_lean(
                                            ac[j as usize],
                                            ac3[j as usize],
                                            pc[j as usize],
                                            pc3[j as usize],
                                            t_dm[jt2 as usize],
                                            mlo[j as usize],
                                            mhi[j as usize],
                                            t_glo[jt2 as usize],
                                            t_ghi[jt2 as usize],
                                            base,
                                        );
                                    } else {
                                        pass = walk_pf(
                                            ac[j as usize],
                                            pc[j as usize],
                                            t_dm[jt2 as usize],
                                            mlo[j as usize],
                                            mhi[j as usize],
                                            t_lo[jt2 as usize],
                                            t_hi[jt2 as usize],
                                            base,
                                            k,
                                            k2,
                                        );
                                    }
                                    {
                                        if pass {""")
# (then the bare block is removed and its body dedented: see the end of this script)
rep("""                    ws += wave;
                }
                tc += TOP_CAP;
                sync_cube();""", """                    ws += wave;
                }
                // Every thread is past its last read of the clip words (each
                // chunk ends with barriers), and the next batch sets them
                // after the barrier below.
                if UNIT_POS_X < comptime!(TOP_CAP / 32) {
                    s_cw[UNIT_POS_X as usize].store(0u32);
                }
                tc += TOP_CAP;
                sync_cube();""")
# --- walk_pf_lean + fx_consts
rep("""        ok
    }

    /// Write the shared survivor stage to the list.""", """        ok
    }

    /// The constants of [`walk_pf_lean`] at base b: `C = ceil(2^32/b²)`, and
    /// `Q`, `R` with `2^32 = Q·b² + R`.
    #[allow(clippy::cast_possible_truncation)]
    pub(super) fn fx_consts(base: u32) -> (u32, u32, u32) {
        let b2 = u64::from(base * base);
        (
            (1u64 << 32).div_ceil(b2) as u32,
            ((1u64 << 32) / b2) as u32,
            ((1u64 << 32) % b2) as u32,
        )
    }

    /// [`walk_pf`] at mid = 2 (k >= 2) without a division: `x mod b²` as a
    /// 32-bit fraction of b², `F = (ah + p·dh) mod 2^32` with `ah = A·C`,
    /// `C = ceil(2^32/b²)` (the entry's) and `dh = ceil(D·2^32/b²)` (the
    /// top's); then `F·b² = (x mod b²)·2^32 + Δ` with `Δ = A·(C·b² − 2^32) +
    /// P·(dh·b² − D·2^32) < 2b⁴ <= 2^25`, so the high words of `F·b` and of
    /// `(F·b mod 2^32)·b` are the two digits of `x mod b²` exactly. The masks
    /// are bit-reversed (digit d at bit 63 - d), so digit g is in `seen` iff
    /// bit 63 of `seen << g` is set: four shifts and a sign test, and six
    /// compares for the digits' distinctness. `tlo`/`thi` are the top's
    /// certificate if its seed flag is set, else 0.
    #[cube]
    fn walk_pf_lean(
        ah2: u32,
        ah3: u32,
        p2: u32,
        p3: u32,
        dh: u32,
        mlo: u32,
        mhi: u32,
        tlo: u32,
        thi: u32,
        #[comptime] base: u32,
    ) -> bool {
        let f2 = ah2 + p2 * dh;
        let f3 = ah3 + p3 * dh;
        let h2 = u32::mul_hi(f2, base);
        let g2 = u32::mul_hi(f2 * base, base);
        let h3 = u32::mul_hi(f3, base);
        let g3 = u32::mul_hi(f3 * base, base);
        let seen = (u64::cast_from(mhi | thi) << 32u64) | u64::cast_from(mlo | tlo);
        let hit = u32::cast_from((seen << u64::cast_from(g2)) >> 32u64)
            | u32::cast_from((seen << u64::cast_from(g3)) >> 32u64)
            | u32::cast_from((seen << u64::cast_from(h2)) >> 32u64)
            | u32::cast_from((seen << u64::cast_from(h3)) >> 32u64);
        let mut ok = true;
        // The sign test last: first, it compiled to a select and a byte
        // extension in front of the compares.
        if g2 == g3
            || h2 == h3
            || g2 == h2
            || g2 == h3
            || g3 == h2
            || g3 == h3
            || i32::cast_from(hit) < 0i32
        {
            ok = false;
        }
        ok
    }

    /// Write the shared survivor stage to the list.""")
# --- host launch
rep("""                nwork_u32,
                self.nbp,
                self.list_cap,
                self.b,""", """                nwork_u32,
                self.nbp,
                self.list_cap,
                self.w_f0,
                self.b,""")
lines = s.split('\n')
i = next(k for k, l in enumerate(lines) if l.strip() == '{' and lines[k + 1].strip() == 'if pass {')
ind = len(lines[i]) - len(lines[i].lstrip())
j = next(k for k in range(i + 1, len(lines)) if lines[k] == ' ' * ind + '}')
body = [l[4:] if l.startswith(' ' * (ind + 4)) else l for l in lines[i + 1:j]]
s = '\n'.join(lines[:i] + body + lines[j + 1:])
open(p, 'w').write(s)
print('ok')

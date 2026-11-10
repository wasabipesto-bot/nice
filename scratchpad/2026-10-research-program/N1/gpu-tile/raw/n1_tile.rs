//! N1 tile harness (experimental, research program 2026-11-10; test-only).
//!
//! The dense phase of `cubecl_join::join_kernel` on synthetic tiles: a work
//! item is one bucket of `nbat` batch-side items (loaded 256 at a time as
//! 8-word records into shared memory and transposed digit-major, as the
//! production kernel loads its tops) against `nreg` register-side items
//! (loaded per wave of 512 through a list index, with the production key-level
//! arithmetic, as the production kernel loads its entries). The AND is the
//! production one (AND_GROUP chunks per set-bit iteration), in 32-bit chunk
//! words or 64-bit ones. `walk` adds the production walk (plane rounds + the
//! lean prefilter) and counts prefilter passes instead of staging them.
//!
//! Orientation is a property of the data only: today's orientation puts the
//! tops on the batch side (D_T digits) and the bottoms in registers (D_B);
//! the reverse puts the bottoms on the batch side and the tops in registers.
#![allow(
    clippy::all,
    clippy::pedantic,
    clippy::nursery,
    unused_assignments,
    unused_mut,
    unused_variables,
    dead_code
)]

use cubecl::prelude::*;

const WG: u32 = 256;
const CAP: u32 = 256;
const REC: u32 = 8;
const STAGE_CAP: u32 = 1024;
const BASE: u32 = 62;

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

/// `out[0]` AND survivors, `out[1]` prefilter passes (walk only).
#[cube(launch_unchecked)]
pub fn tile_kernel(
    bat: &Array<u32>,
    reg_m: &Array<u32>,
    reg_q: &Array<u32>,
    reg_r: &Array<u32>,
    lists: &Array<u32>,
    out: &mut Array<Atomic<u32>>,
    nwork: u32,
    nbat: u32,
    nreg: u32,
    bat_span: u32,
    list_span: u32,
    w_f0: u32,
    dkey: u32,
    #[comptime] ept: u32,
    #[comptime] w64: bool,
    #[comptime] ag: u32,
    #[comptime] tmin: u32,
    #[comptime] walk: bool,
    #[comptime] noand: bool,
) {
    let base = comptime!(BASE);
    let wave = comptime!(ept * WG);
    // b62, f0 3, k 6, k2 8 (the production shape's comptime values).
    let bm = comptime!(BASE * BASE);
    let big_m = comptime!(BASE * BASE * BASE);
    let dm_div = comptime!(BASE * BASE * BASE);
    let fx_c = comptime!(((1u64 << 32).div_ceil(u64::from(BASE * BASE))) as u32);
    let fx_q = comptime!(((1u64 << 32) / u64::from(BASE * BASE)) as u32);
    let fx_r = comptime!(((1u64 << 32) % u64::from(BASE * BASE)) as u32);
    let bsq = comptime!(BASE * BASE);
    let mut t_lo = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_hi = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_rlo = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_rhi = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_id = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_dm = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_glo = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let mut t_ghi = SharedMemory::<u32>::new(comptime!(CAP as usize));
    let s_cw = SharedMemory::<Atomic<u32>>::new(comptime!((CAP / 32) as usize));
    let mut t_tr =
        SharedMemory::<u32>::new(comptime!(if w64 { 1usize } else { (CAP / 32 * 64) as usize }));
    let mut t_tr64 =
        SharedMemory::<u64>::new(comptime!(if w64 { (CAP / 64 * 64) as usize } else { 1usize }));
    // The production stage (8 KiB), kept for the occupancy (5 cubes per SM).
    let mut s_t = SharedMemory::<u32>::new(comptime!(STAGE_CAP as usize));
    let mut s_r = SharedMemory::<u32>::new(comptime!(STAGE_CAP as usize));
    let mut nand = 0u32;
    let mut npf = 0u32;

    if UNIT_POS_X < comptime!(CAP / 32) {
        s_cw[UNIT_POS_X as usize].store(0u32);
    }
    sync_cube();

    let mut w = CUBE_POS_X;
    while w < nwork {
        let h = w * 2654435761u32;
        let bstart = (h >> 3u32) % bat_span;
        let lstart = (h >> 5u32) % list_span;
        sync_cube();
        let mut tc = 0u32;
        while tc < nbat {
            let mut nt = nbat - tc;
            if nt > CAP {
                nt = CAP;
            }
            if UNIT_POS_X < nt {
                let t = bstart + tc + UNIT_POS_X;
                let r8 = REC * t;
                let l0 = bat[(r8 + 2u32) as usize];
                let h0 = bat[(r8 + 3u32) as usize];
                let lo = h0.reverse_bits();
                let hi = l0.reverse_bits();
                t_lo[UNIT_POS_X as usize] = lo;
                t_hi[UNIT_POS_X as usize] = hi;
                let rlo = bat[(r8 + 4u32) as usize];
                let rhi = bat[(r8 + 5u32) as usize];
                t_rlo[UNIT_POS_X as usize] = rlo;
                t_rhi[UNIT_POS_X as usize] = rhi;
                if rlo != 0u32 || rhi != w_f0 {
                    s_cw[(UNIT_POS_X / 32u32) as usize].fetch_or(1u32 << (UNIT_POS_X % 32u32));
                }
                t_id[UNIT_POS_X as usize] = t;
                let dm = bat[(r8 + 6u32) as usize] / dm_div;
                let seed = bat[(r8 + 7u32) as usize];
                t_dm[UNIT_POS_X as usize] = dm * fx_q + (dm * fx_r + comptime!(bsq - 1)) / bsq;
                t_glo[UNIT_POS_X as usize] = select(seed != 0u32, lo, 0u32);
                t_ghi[UNIT_POS_X as usize] = select(seed != 0u32, hi, 0u32);
            }
            sync_cube();
            if nt >= tmin {
                if comptime!(w64) {
                    // Thread u: chunk u / 64 (64 tops), digit u % 64.
                    let cc = UNIT_POS_X / 64u32;
                    let d = UNIT_POS_X % 64u32;
                    let dl = d % 32u32;
                    let t0 = cc * 64u32;
                    let mut w0 = 0u32;
                    let mut w1 = 0u32;
                    if t0 < nt {
                        if d < 32u32 {
                            #[unroll]
                            for i in 0..32u32 {
                                let a = t_lo[(t0 + i) as usize];
                                let b = t_lo[(t0 + 32u32 + i) as usize];
                                w0 |= ((a >> dl) & 1u32) << i;
                                w1 |= ((b >> dl) & 1u32) << i;
                            }
                        } else {
                            #[unroll]
                            for i in 0..32u32 {
                                let a = t_hi[(t0 + i) as usize];
                                let b = t_hi[(t0 + 32u32 + i) as usize];
                                w0 |= ((a >> dl) & 1u32) << i;
                                w1 |= ((b >> dl) & 1u32) << i;
                            }
                        }
                        let n = nt - t0;
                        if n < 32u32 {
                            w0 &= (1u32 << n) - 1u32;
                            w1 = 0u32;
                        } else if n < 64u32 {
                            w1 &= (1u32 << (n - 32u32)) - 1u32;
                        }
                    }
                    t_tr64[(cc * 64u32 + d) as usize] =
                        (u64::cast_from(w1) << 32u64) | u64::cast_from(w0);
                } else {
                    let cc = UNIT_POS_X / 32u32;
                    let dl = UNIT_POS_X % 32u32;
                    let t0 = cc * 32u32;
                    let mut w0 = 0u32;
                    let mut w1 = 0u32;
                    if t0 < nt {
                        #[unroll]
                        for i in 0..32u32 {
                            let lo = t_lo[(t0 + i) as usize];
                            let hi = t_hi[(t0 + i) as usize];
                            w0 |= ((lo >> dl) & 1u32) << i;
                            w1 |= ((hi >> dl) & 1u32) << i;
                        }
                        let n = nt - t0;
                        if n < 32u32 {
                            let vm = (1u32 << n) - 1u32;
                            w0 &= vm;
                            w1 &= vm;
                        }
                    }
                    t_tr[(cc * 64u32 + dl) as usize] = w0;
                    t_tr[(cc * 64u32 + 32u32 + dl) as usize] = w1;
                }
            }
            sync_cube();

            let mut ws = 0u32;
            while ws < nreg {
                let mut mlo = Array::<u32>::new(ept as usize);
                let mut mhi = Array::<u32>::new(ept as usize);
                let mut rr = Array::<u32>::new(ept as usize);
                let mut vv = Array::<u32>::new(ept as usize);
                let mut ac = Array::<u32>::new(ept as usize);
                let mut pc = Array::<u32>::new(ept as usize);
                let mut ac3 = Array::<u32>::new(ept as usize);
                let mut pc3 = Array::<u32>::new(ept as usize);
                #[unroll]
                for j in 0..ept {
                    let sl = ws + UNIT_POS_X + comptime!(j * WG);
                    mlo[j as usize] = 0xFFFF_FFFFu32;
                    mhi[j as usize] = 0xFFFF_FFFFu32;
                    rr[j as usize] = 0u32;
                    vv[j as usize] = 0u32;
                    ac[j as usize] = 0u32;
                    pc[j as usize] = 0u32;
                    ac3[j as usize] = 0u32;
                    pc3[j as usize] = 0u32;
                    if sl < nreg {
                        vv[j as usize] = 0xFFFF_FFFFu32;
                        let e = lists[(lstart + sl) as usize];
                        let r0 = reg_r[e as usize];
                        let mut m = (u64::cast_from(reg_m[(2u32 * e + 1u32) as usize]) << 32u64)
                            | u64::cast_from(reg_m[(2u32 * e) as usize]);
                        let q0 = reg_q[(2u32 * e) as usize];
                        let q1 = reg_q[(2u32 * e + 1u32) as usize];
                        let sigma = r0;
                        let c3 = (q0 >> 18u32) | ((q1 >> 18u32) << 14u32);
                        let mut t2 = (q0 & 0x3FFFFu32) + dkey * (2u32 * sigma);
                        let mut t3 = (q1 & 0x3FFFFu32) + dkey * c3;
                        t2 %= big_m;
                        t3 %= big_m;
                        let g2 = t2 % base;
                        let g3 = t3 % base;
                        m |= (1u64 << u64::cast_from(g2)) | (1u64 << u64::cast_from(g3));
                        ac[j as usize] = (t2 / base) * fx_c;
                        ac3[j as usize] = (t3 / base) * fx_c;
                        let rho = sigma % bm;
                        pc3[j as usize] = (3u32 * ((rho * rho) % bm)) % bm;
                        pc[j as usize] = (2u32 * rho) % bm;
                        mlo[j as usize] = u32::cast_from(m >> 32u64).reverse_bits();
                        mhi[j as usize] = u32::cast_from(m).reverse_bits();
                        rr[j as usize] = r0;
                    }
                }
                if comptime!(w64) {
                    let mut acc = Array::<u64>::new(comptime!((ag * ept) as usize));
                    let mut jc = 0u32;
                    while jc < nt {
                        let mut cend = jc + 64u32;
                        if cend > nt {
                            cend = nt;
                        }
                        let mut pm = Array::<u64>::new(ept as usize);
                        if comptime!(noand) {
                            // Base only: one shared read per chunk keeps the
                            // loads and the transposed copy live.
                            let tw = t_tr64[((jc / 64u32) * 64u32) as usize];
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = tw & u64::cast_from(mlo[j as usize] & mhi[j as usize]);
                            }
                        } else if nt >= tmin {
                            let cb = jc / 64u32;
                            if cb % ag == 0u32 {
                                #[unroll]
                                for i in 0..comptime!(ag * ept) {
                                    acc[i as usize] = 0u64;
                                }
                                let ab = cb * 64u32;
                                #[unroll]
                                for j in 0..ept {
                                    let mut x = mlo[j as usize] & vv[j as usize];
                                    let mut y = mhi[j as usize] & vv[j as usize];
                                    while (x | y) != 0u32 {
                                        let lo = x != 0u32;
                                        let v = select(lo, x, y);
                                        let d = (v.find_first_set() - 1u32)
                                            + select(lo, 0u32, 32u32);
                                        let v1 = v & (v - 1u32);
                                        x = select(lo, v1, x);
                                        y = select(lo, y, v1);
                                        let a = ab + d;
                                        #[unroll]
                                        for c in 0..ag {
                                            acc[comptime!(c * ept + j) as usize] |=
                                                t_tr64[(a + comptime!(c * 64)) as usize];
                                        }
                                    }
                                }
                            }
                            let nb = cend - jc;
                            let cm = select(
                                nb >= 64u32,
                                0xFFFF_FFFF_FFFF_FFFFu64,
                                (1u64 << u64::cast_from(nb & 63u32)) - 1u64,
                            );
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = (acc[j as usize] ^ cm) & cm;
                            }
                            #[unroll]
                            for i in 0..comptime!((ag - 1) * ept) {
                                acc[i as usize] = acc[comptime!(i + ept) as usize];
                            }
                        } else {
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = 0u64;
                            }
                            let mut jt = jc;
                            let mut bit = 1u64;
                            while jt < cend {
                                let tlo = t_lo[jt as usize];
                                let thi = t_hi[jt as usize];
                                #[unroll]
                                for j in 0..ept {
                                    let z = (mlo[j as usize] & tlo) | (mhi[j as usize] & thi);
                                    pm[j as usize] |= select(z == 0u32, bit, 0u64);
                                }
                                bit <<= 1u64;
                                jt += 1u32;
                            }
                        }
                        let cw = s_cw[(jc / 32u32) as usize].load()
                            | s_cw[(jc / 32u32 + 1u32) as usize].load();
                        if cw != 0u32 {
                            // Never taken on this data (no clipped tops).
                            #[unroll]
                            for j in 0..ept {
                                let r0 = rr[j as usize];
                                if r0 < t_rlo[jc as usize] || r0 >= t_rhi[jc as usize] {
                                    pm[j as usize] = 0u64;
                                }
                            }
                        }
                        #[unroll]
                        for j in 0..ept {
                            let p = pm[j as usize];
                            let pl = u32::cast_from(p) & vv[j as usize];
                            let ph = u32::cast_from(p >> 32u64) & vv[j as usize];
                            nand += pl.count_ones() + ph.count_ones();
                        }
                        if comptime!(walk) {
                            #[unroll]
                            for j in 0..ept {
                                let p = pm[j as usize];
                                let mut x = u32::cast_from(p) & vv[j as usize];
                                    while plane_any(x != 0u32) {
                                        if x != 0u32 {
                                            let jt2 = jc + x.trailing_zeros();
                                            x &= x - 1u32;
                                            if walk_pf_lean(
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
                                            ) {
                                                npf += 1u32;
                                            }
                                        }
                                        sync_plane();
                                    }
                                x = u32::cast_from(p >> 32u64) & vv[j as usize];
                                    while plane_any(x != 0u32) {
                                        if x != 0u32 {
                                            let jt2 = (jc + 32u32) + x.trailing_zeros();
                                            x &= x - 1u32;
                                            if walk_pf_lean(
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
                                            ) {
                                                npf += 1u32;
                                            }
                                        }
                                        sync_plane();
                                    }
                            }
                        }
                        jc += 64u32;
                    }
                } else {
                    let mut acc = Array::<u32>::new(comptime!((ag * ept) as usize));
                    let mut jc = 0u32;
                    while jc < nt {
                        let mut cend = jc + 32u32;
                        if cend > nt {
                            cend = nt;
                        }
                        let mut pm = Array::<u32>::new(ept as usize);
                        if comptime!(noand) {
                            let tw = t_tr[((jc / 32u32) * 64u32) as usize];
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = tw & mlo[j as usize] & mhi[j as usize];
                            }
                        } else if nt >= tmin {
                            let cb = jc / 32u32;
                            if cb % ag == 0u32 {
                                #[unroll]
                                for i in 0..comptime!(ag * ept) {
                                    acc[i as usize] = 0u32;
                                }
                                let ab = cb * 64u32;
                                #[unroll]
                                for j in 0..ept {
                                    let mut x = mlo[j as usize] & vv[j as usize];
                                    let mut y = mhi[j as usize] & vv[j as usize];
                                    while (x | y) != 0u32 {
                                        let lo = x != 0u32;
                                        let v = select(lo, x, y);
                                        let d = (v.find_first_set() - 1u32)
                                            + select(lo, 0u32, 32u32);
                                        let v1 = v & (v - 1u32);
                                        x = select(lo, v1, x);
                                        y = select(lo, y, v1);
                                        let a = ab + d;
                                        #[unroll]
                                        for c in 0..ag {
                                            acc[comptime!(c * ept + j) as usize] |=
                                                t_tr[(a + comptime!(c * 64)) as usize];
                                        }
                                    }
                                }
                            }
                            let nb = cend - jc;
                            let cm = select(
                                nb >= 32u32,
                                0xFFFF_FFFFu32,
                                (1u32 << (nb & 31u32)) - 1u32,
                            );
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = (acc[j as usize] ^ cm) & cm;
                            }
                            #[unroll]
                            for i in 0..comptime!((ag - 1) * ept) {
                                acc[i as usize] = acc[comptime!(i + ept) as usize];
                            }
                        } else {
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = 0u32;
                            }
                            let mut jt = jc;
                            let mut bit = 1u32;
                            while jt < cend {
                                let tlo = t_lo[jt as usize];
                                let thi = t_hi[jt as usize];
                                #[unroll]
                                for j in 0..ept {
                                    let z = (mlo[j as usize] & tlo) | (mhi[j as usize] & thi);
                                    pm[j as usize] |= select(z == 0u32, bit, 0u32);
                                }
                                bit <<= 1u32;
                                jt += 1u32;
                            }
                        }
                        let cw = s_cw[(jc / 32u32) as usize].load();
                        if cw != 0u32 {
                            #[unroll]
                            for j in 0..ept {
                                let r0 = rr[j as usize];
                                let mut y = pm[j as usize] & vv[j as usize] & cw;
                                while y != 0u32 {
                                    let i = y.trailing_zeros();
                                    y &= y - 1u32;
                                    if r0 < t_rlo[(jc + i) as usize]
                                        || r0 >= t_rhi[(jc + i) as usize]
                                    {
                                        pm[j as usize] ^= 1u32 << i;
                                    }
                                }
                            }
                        }
                        #[unroll]
                        for j in 0..ept {
                            nand += (pm[j as usize] & vv[j as usize]).count_ones();
                        }
                        if comptime!(walk) {
                            #[unroll]
                            for j in 0..ept {
                                let mut x = pm[j as usize] & vv[j as usize];
                                while plane_any(x != 0u32) {
                                    if x != 0u32 {
                                        let jt2 = jc + x.trailing_zeros();
                                        x &= x - 1u32;
                                        if walk_pf_lean(
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
                                        ) {
                                            npf += 1u32;
                                        }
                                    }
                                    sync_plane();
                                }
                            }
                        }
                        jc += 32u32;
                    }
                }
                ws += wave;
            }
            sync_cube();
            tc += CAP;
        }
        w += CUBE_COUNT_X;
    }
    // Keep the stage arrays (never taken: nand cannot reach this value).
    if nand == 0xFFFF_FFF1u32 {
        s_t[UNIT_POS_X as usize] = nand;
        s_r[UNIT_POS_X as usize] = npf;
        sync_cube();
        npf += s_t[((UNIT_POS_X + 1u32) % STAGE_CAP) as usize]
            + s_r[((UNIT_POS_X + 3u32) % STAGE_CAP) as usize];
    }
    let pa = plane_sum(nand);
    let pp = plane_sum(npf);
    if UNIT_POS_PLANE == 0u32 {
        out[0].fetch_add(pa);
        out[1].fetch_add(pp);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use cubecl::cuda::{CudaDevice, CudaRuntime};

    struct Rng(u64);
    impl Rng {
        fn next(&mut self) -> u64 {
            // splitmix64
            self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
            let mut z = self.0;
            z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
            z ^ (z >> 31)
        }
        fn below(&mut self, n: u64) -> u64 {
            self.next() % n
        }
        /// A random set of `d` digits out of 62, as a mask (digit i at bit i).
        fn digits(&mut self, d: u32) -> u64 {
            let mut m = 0u64;
            let mut c = 0;
            while c < d {
                let b = self.below(62);
                if m & (1 << b) == 0 {
                    m |= 1 << b;
                    c += 1;
                }
            }
            m
        }
    }

    struct Pools {
        bat: Vec<u32>,
        reg_m: Vec<u32>,
        reg_q: Vec<u32>,
        reg_r: Vec<u32>,
        lists: Vec<u32>,
    }

    /// Batch-side records with `db` digits, register-side items with `dr`
    /// (the two key-level digits g2, g3 chosen among the item's own, so the
    /// mask keeps exactly `dr`).
    fn pools(db: u32, dr: u32, nb: usize, nr: usize, nl: usize, seed: u64) -> Pools {
        let mut g = Rng(seed);
        let mut bat = vec![0u32; nb * 8];
        for i in 0..nb {
            let m = g.digits(db);
            let r = &mut bat[i * 8..i * 8 + 8];
            r[0] = g.next() as u32;
            r[1] = g.next() as u32;
            r[2] = m as u32;
            r[3] = (m >> 32) as u32;
            r[4] = 0;
            r[5] = 0xFFFF_FFFF;
            r[6] = g.below(62u64.pow(5)) as u32;
            r[7] = (g.next() & 1) as u32;
        }
        let mut reg_m = vec![0u32; nr * 2];
        let mut reg_q = vec![0u32; nr * 2];
        let mut reg_r = vec![0u32; nr];
        for i in 0..nr {
            let m = g.digits(dr);
            reg_m[2 * i] = m as u32;
            reg_m[2 * i + 1] = (m >> 32) as u32;
            let bits: Vec<u32> = (0..62).filter(|b| m >> b & 1 == 1).collect();
            let a = bits[g.below(bits.len() as u64) as usize];
            let b = bits[g.below(bits.len() as u64) as usize];
            reg_q[2 * i] = a + 62 * g.below(3844) as u32 | ((g.next() as u32) & 0x3FFF) << 18;
            reg_q[2 * i + 1] = b + 62 * g.below(3844) as u32 | ((g.next() as u32) & 0x3FFF) << 18;
            reg_r[i] = g.below(62u64.pow(5)) as u32;
        }
        // `lgap` 0: random entry indices (a gather over the whole pool); else
        // increasing indices with gaps uniform in 1..=2·lgap-1 (production: a
        // bucket's entries are the listed part of one class segment, in order).
        let lgap: u64 = std::env::var("NICE_N1_LGAP").map_or(0, |v| v.parse().unwrap());
        let mut acc = 0u64;
        let lists = (0..nl)
            .map(|_| {
                if lgap == 0 {
                    g.below(nr as u64) as u32
                } else {
                    acc += 1 + g.below(2 * lgap - 1);
                    (acc % nr as u64) as u32
                }
            })
            .collect();
        Pools {
            bat,
            reg_m,
            reg_q,
            reg_r,
            lists,
        }
    }

    #[derive(Clone, Debug)]
    struct Cfg {
        name: String,
        db: u32, // batch-side digits
        dr: u32, // register-side digits
        nbat: u32,
        nreg: u32,
        w64: bool,
        ag: u32,
        tmin: u32,
        walk: bool,
        noand: bool,
        nwork: u32,
    }

    fn parse_cfg(s: &str, target_pairs: f64) -> Cfg {
        // name=DB:DR:NBAT:NREG:W(32|64):AG:TMIN:WALK(0|1)
        let (name, v) = s.split_once('=').expect("name=...");
        let f: Vec<u32> = v.split(':').map(|x| x.parse().expect("u32")).collect();
        let pairs = f64::from(f[2]) * f64::from(f[3]);
        let nwork = ((target_pairs / pairs).ceil() as u32).max(1);
        Cfg {
            name: name.into(),
            db: f[0],
            dr: f[1],
            nbat: f[2],
            nreg: f[3],
            w64: f[4] == 64,
            ag: f[5],
            tmin: f[6],
            walk: f[7] == 1,
            noand: f.get(8) == Some(&1),
            nwork,
        }
    }

    fn launch(
        c: &ComputeClient<CudaRuntime>,
        h: &[cubecl::server::Handle; 5],
        lens: &[usize; 5],
        cfg: &Cfg,
        nb_pool: u32,
        nl: u32,
    ) -> (f64, u64, u64) {
        let out = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 4]));
        // Sync before the timer.
        let _ = c.read_one(c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1])));
        let t = std::time::Instant::now();
        unsafe {
            tile_kernel::launch_unchecked::<CudaRuntime>(
                c,
                CubeCount::Static(cfg.nwork.min(65_535), 1, 1),
                CubeDim::new_1d(WG),
                ArrayArg::from_raw_parts(h[0].clone(), lens[0]),
                ArrayArg::from_raw_parts(h[1].clone(), lens[1]),
                ArrayArg::from_raw_parts(h[2].clone(), lens[2]),
                ArrayArg::from_raw_parts(h[3].clone(), lens[3]),
                ArrayArg::from_raw_parts(h[4].clone(), lens[4]),
                ArrayArg::from_raw_parts(out.clone(), 4),
                cfg.nwork,
                cfg.nbat,
                cfg.nreg,
                nb_pool - cfg.nbat,
                nl - cfg.nreg,
                0xFFFF_FFFFu32,
                0u32,
                2u32,
                cfg.w64,
                cfg.ag,
                cfg.tmin,
                cfg.walk,
                cfg.noand,
            );
        }
        let bytes = c.read_one(out).expect("read");
        let secs = t.elapsed().as_secs_f64();
        let o = u32::from_bytes(&bytes);
        (secs, u64::from(o[0]), u64::from(o[1]))
    }

    /// `NICE_N1_CFGS` (`;`-separated `name=DB:DR:NBAT:NREG:W:AG:TMIN:WALK`),
    /// `NICE_N1_ROUNDS`, `NICE_N1_PAIRS` (pairs per launch), `NICE_N1_REPS`
    /// (launches per measurement). Configurations with the same digit counts
    /// share pools; every round runs every configuration once, the order
    /// rotated by one per round.
    #[test]
    #[ignore = "N1 tile harness; needs an NVIDIA device"]
    fn n1_tile_harness() {
        let cfgs_s = std::env::var("NICE_N1_CFGS").expect("NICE_N1_CFGS");
        let rounds: usize = std::env::var("NICE_N1_ROUNDS").map_or(3, |v| v.parse().unwrap());
        let reps: usize = std::env::var("NICE_N1_REPS").map_or(3, |v| v.parse().unwrap());
        let target: f64 = std::env::var("NICE_N1_PAIRS").map_or(5e10, |v| v.parse().unwrap());
        let cfgs: Vec<Cfg> = cfgs_s
            .split(';')
            .filter(|x| !x.trim().is_empty())
            .map(|s| parse_cfg(s.trim(), target))
            .collect();
        let c = CudaRuntime::client(&CudaDevice::new(0));
        let env = |k: &str, d: usize| std::env::var(k).map_or(d, |v| v.parse().unwrap());
        let nb_pool: usize = env("NICE_N1_BPOOL", 1 << 22); // records of 32 B
        let nr_pool: usize = env("NICE_N1_RPOOL", 1 << 22); // entries (8 + 8 + 4 B)
        let nl: usize = env("NICE_N1_LPOOL", 1 << 23);
        eprintln!(
            "N1POOLS bpool={nb_pool} rpool={nr_pool} lpool={nl} lgap={}",
            std::env::var("NICE_N1_LGAP").unwrap_or_default()
        );
        let mut pool_cache: Vec<((u32, u32), [cubecl::server::Handle; 5], [usize; 5])> = Vec::new();
        for cfg in &cfgs {
            if !pool_cache.iter().any(|p| p.0 == (cfg.db, cfg.dr)) {
                let p = pools(
                    cfg.db,
                    cfg.dr,
                    nb_pool,
                    nr_pool,
                    nl,
                    0x5EED ^ u64::from(cfg.db * 100 + cfg.dr),
                );
                let lens = [p.bat.len(), p.reg_m.len(), p.reg_q.len(), p.reg_r.len(), p.lists.len()];
                let hs = [
                    c.create(cubecl::bytes::Bytes::from_elems(p.bat)),
                    c.create(cubecl::bytes::Bytes::from_elems(p.reg_m)),
                    c.create(cubecl::bytes::Bytes::from_elems(p.reg_q)),
                    c.create(cubecl::bytes::Bytes::from_elems(p.reg_r)),
                    c.create(cubecl::bytes::Bytes::from_elems(p.lists)),
                ];
                pool_cache.push(((cfg.db, cfg.dr), hs, lens));
            }
        }
        let get = |cfg: &Cfg| {
            let p = pool_cache
                .iter()
                .find(|p| p.0 == (cfg.db, cfg.dr))
                .expect("pool");
            (&p.1, &p.2)
        };
        // Warm-up: compile every kernel, one small launch each.
        for cfg in &cfgs {
            let (h, l) = get(cfg);
            let mut small = cfg.clone();
            small.nwork = small.nwork.min(64);
            let _ = launch(&c, h, l, &small, nb_pool as u32, nl as u32);
            let (s, a, p) = launch(&c, h, l, cfg, nb_pool as u32, nl as u32);
            eprintln!("N1WARM {} secs={s:.4} nand={a} npf={p}", cfg.name);
        }
        for r in 0..rounds {
            for i in 0..cfgs.len() {
                let cfg = &cfgs[(i + r) % cfgs.len()];
                let (h, l) = get(cfg);
                let mut best = f64::MAX;
                let mut tot = 0.0;
                let (mut a, mut p) = (0, 0);
                for _ in 0..reps {
                    let (s, a1, p1) = launch(&c, h, l, cfg, nb_pool as u32, nl as u32);
                    best = best.min(s);
                    tot += s;
                    a = a1;
                    p = p1;
                }
                let mean = tot / reps as f64;
                let pairs = f64::from(cfg.nwork) * f64::from(cfg.nbat) * f64::from(cfg.nreg);
                eprintln!(
                    "N1 round={r} cfg={} db={} dr={} nbat={} nreg={} w={} ag={} tmin={} walk={} noand={} \
                     nwork={} pairs={pairs:.6e} secs_mean={mean:.5} secs_min={best:.5} \
                     ps_pair_mean={:.4} ps_pair_min={:.4} nand={a} pass={:.5} npf={p} \
                     ps_surv_mean={:.3}",
                    cfg.name,
                    cfg.db,
                    cfg.dr,
                    cfg.nbat,
                    cfg.nreg,
                    if cfg.w64 { 64 } else { 32 },
                    cfg.ag,
                    cfg.tmin,
                    u32::from(cfg.walk),
                    u32::from(cfg.noand),
                    cfg.nwork,
                    mean / pairs * 1e12,
                    best / pairs * 1e12,
                    a as f64 / pairs,
                    mean / (a.max(1) as f64) * 1e12,
                );
            }
        }
    }
}

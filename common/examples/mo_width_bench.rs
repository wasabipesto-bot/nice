//! Phase 3b of the middle-out main kernel (`midout::gpu::kernels::g2_kernel`) alone, at 64, 128 and 256
//! children per lane word, on the inputs `mo_width_dump` wrote from the CPU reference (scratch branch
//! `exp/mo-word-width`, a measurement only).
//!
//! usage: mo_width_bench [--cuda] --dump DIR --pips P1,P2,.. [--reps N] [--variants a,b,..] [--force-w W] [--once]
//!
//! One cube per job instance (as `g2_kernel` is launched: every instance of a slice in one launch). Per round
//! the kernel copies the round's words (2,080 u32, the shared layout `[(v + 65 q)·NW + k]`) and the round's
//! probe listing (phase 3a's output, from the dump) into shared memory, then runs phase 3b exactly as
//! `g2_kernel` does: lane = chunk `q = t % (32/NW)`, `NT/(32/NW)` probe streams, `H` list entries per lane per
//! step, the unrolled 17 ORs of the probe's digit words, the kept-chunk and valid-row masks, two ballots per
//! entry (count, rank), plane-private slabs of 256 records, one record per nonzero word (NW/2 of today's
//! 16-byte records, `[top, child position + 64 j, lo, hi]`). `mode 0` does everything but the 3b loop (the
//! copies, the barriers), so 3b = full − mode 0. Exactness: per instance, the nonzero words (the records in its
//! slabs) and the survivor bits must equal the dump's; no timing is printed for a variant that differs.
#![allow(
    clippy::cast_possible_truncation,
    clippy::too_many_arguments,
    clippy::too_many_lines,
    clippy::cast_precision_loss,
    unused_assignments
)]

use anyhow::{Result, anyhow, bail};
use cubecl::prelude::*;
use cubecl::server::Handle;
use nice_common::cubecl_backend::CubeclContext;
use std::time::Instant;

const NT: u32 = 256;
const SLAB: u32 = 256;
const SLW: usize = 2080;

mod k {
    use super::NT;
    use cubecl::prelude::*;

    #[cube]
    fn plane_rank_m(flag: bool, lo: u32, hi: u32, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut r = (b[0usize] & lo).count_ones();
        if comptime!(w > 32) {
            r += (b[1usize] & hi).count_ones();
        }
        r
    }

    #[cube]
    fn plane_count(flag: bool, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut n = b[0usize].count_ones();
        if comptime!(w > 32) {
            n += b[1usize].count_ones();
        }
        n
    }

    /// `nw` u32 per digit word (2: 64 children, 4: 128, 8: 256), `hh` list entries per lane per step, `vec`: the
    /// shared words read as 16-byte vectors (`nw` a multiple of 4) instead of u32.
    #[cube(launch_unchecked)]
    pub fn w3b_kernel(
        inst: &Array<u32>,
        rounds: &Array<u32>,
        probes: &Array<Vector<u32, Const<4>>>,
        lists: &Array<u32>,
        words: &Array<Vector<u32, Const<4>>>,
        out: &mut Array<Vector<u32, Const<4>>>,
        slabn: &mut Array<Atomic<u32>>,
        slabcnt: &mut Array<u32>,
        slabinst: &mut Array<u32>,
        res: &mut Array<Atomic<u32>>,
        nslab_cap: u32,
        mode: u32,
        #[comptime] w: u32,
        #[comptime] nw: u32,
        #[comptime] hh: u32,
        #[comptime] vec: bool,
        #[comptime] swz: bool,
    ) {
        let cpr = comptime!(32 / nw); // chunks per round (lanes per probe stream)
        let nst = comptime!(NT / (32 / nw)); // probe streams
        let mut pq = SharedMemory::<u32>::new(comptime!((576 + 128) as usize));
        let mut sl = SharedMemory::<u32>::new(comptime!((if vec { 32 } else { 2080 }) as usize));
        let mut slv =
            SharedMemory::<Vector<u32, Const<4>>>::new(comptime!((if vec { 520 } else { 8 }) as usize));
        let mut prob_d = SharedMemory::<Vector<u32, Const<4>>>::new(576usize);

        let t = UNIT_POS_X;
        let lane = UNIT_POS_PLANE;
        let rl = UNIT_POS_PLANE;
        let rlo = select(rl >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(rl, 31u32)) - 1u32);
        let rhi = select(rl >= 32u32, (1u32 << (rl & 31u32)) - 1u32, 0u32);
        let ib = CUBE_POS_X * 8u32;
        let nprobe = inst[(ib + 4u32) as usize];
        let pbase = inst[(ib + 5u32) as usize];
        let rbase = inst[(ib + 6u32) as usize];
        let nr = inst[(ib + 7u32) as usize];
        {
            let mut j = t;
            while j < nprobe {
                prob_d[j as usize] = probes[(pbase + j) as usize];
                j += NT;
            }
        }
        let mut my_surv = 0u32;
        let mut my_lslots = 0u32;
        let mut slab_id = 0u32;
        let mut slab_used = 256u32;
        let mut have_slab = false;
        let q = t % cpr;
        let st = t / cpr;
        let q65 = 65u32 * q;
        let qs = 16u32 + q;
        let mut odd1 = 0u32;
        if comptime!(swz) {
            odd1 = st & 1u32;
        }
        let mut r = 0u32;
        while r < nr {
            let rb = (rbase + r) * 8u32;
            let slr = rounds[rb as usize];
            let nch = rounds[(rb + 1u32) as usize];
            let ntake = rounds[(rb + 2u32) as usize];
            let loff = rounds[(rb + 3u32) as usize];
            let nlist0 = rounds[(rb + 4u32) as usize];
            let cdone = rounds[(rb + 5u32) as usize];
            sync_cube();
            {
                let mut z = t;
                while z < 520u32 {
                    let v = words[(slr * 520u32 + z) as usize];
                    if comptime!(vec) {
                        slv[z as usize] = v;
                    } else {
                        #[unroll]
                        for kk in 0..4u32 {
                            sl[(z * 4u32 + kk) as usize] = v[kk as usize];
                        }
                    }
                    z += NT;
                }
                let mut z2 = t;
                while z2 < nlist0 {
                    pq[z2 as usize] = lists[(loff + z2) as usize];
                    z2 += NT;
                }
            }
            sync_cube();
            let nlist = select((mode & 1u32) != 0u32, nlist0, 0u32);
            // phase 3b
            let wd = comptime!(nw * 32);
            let nq = select(q < nch, min(wd, ntake - min(ntake, q * wd)), 0u32);
            let mut valid = Array::<u32>::new(comptime!(nw as usize));
            #[unroll]
            for kk in 0..nw {
                let lo = comptime!(kk * 32);
                valid[kk as usize] = select(
                    nq >= comptime!(kk * 32 + 32),
                    0xFFFF_FFFFu32,
                    select(nq > lo, (1u32 << ((nq - min(nq, lo)) % 32u32)) - 1u32, 0u32),
                );
            }
            let cpos = cdone + q * wd;
            let mut e0 = 0u32;
            while e0 < nlist {
                let mut wv = Array::<u32>::new(comptime!((nw * hh) as usize));
                let mut pk = Array::<u32>::new(comptime!(hh as usize));
                #[unroll]
                for h in 0..hh {
                    let e = e0 + st + comptime!(nst * h);
                    let ent = select(e < nlist, pq[e as usize], 0u32);
                    let p16 = ent & 0xFFFFu32;
                    let kmask = 0u32 - ((ent >> qs) & 1u32);
                    let mut a = Array::<u32>::new(comptime!(nw as usize));
                    #[unroll]
                    for kk in 0..nw {
                        a[kk as usize] = 0u32;
                    }
                    let dws = prob_d[(p16 >> 4u32) as usize];
                    pk[h as usize] = dws[3usize] >> 12u32;
                    #[unroll]
                    for k in 0..17u32 {
                        let dg = (dws[comptime!(k / 5) as usize] >> comptime!(6 * (k % 5))) & 63u32;
                        if comptime!(vec) {
                            let row = (dg + q65) * comptime!(nw / 4);
                            #[unroll]
                            for jj in 0..comptime!(nw / 4) {
                                // swz (nw = 8): odd probe streams read the two halves in the other order, so that the
                                // two streams of an 8-lane LDS.128 phase fall on different banks
                                let mut v = slv[(row + jj) as usize];
                                if comptime!(swz) {
                                    v = slv[(row + (jj ^ odd1)) as usize];
                                }
                                #[unroll]
                                for kk in 0..4u32 {
                                    a[comptime!(jj * 4 + kk) as usize] |= v[kk as usize];
                                }
                            }
                        } else {
                            let row = (dg + q65) * nw;
                            #[unroll]
                            for kk in 0..nw {
                                a[kk as usize] |= sl[(row + kk) as usize];
                            }
                        }
                    }
                    if comptime!(swz) {
                        let odd = (st & 1u32) != 0u32;
                        #[unroll]
                        for kk in 0..4u32 {
                            let x = a[kk as usize];
                            let y = a[comptime!(kk + 4) as usize];
                            a[kk as usize] = select(odd, y, x);
                            a[comptime!(kk + 4) as usize] = select(odd, x, y);
                        }
                    }
                    #[unroll]
                    for kk in 0..nw {
                        wv[comptime!(h * nw + kk) as usize] = !a[kk as usize] & valid[kk as usize] & kmask;
                    }
                }
                if t == 0u32 {
                    my_lslots += min(comptime!(nst * hh), nlist - e0) * nch;
                }
                let mut nz = Array::<bool>::new(comptime!(hh as usize));
                #[unroll]
                for h in 0..hh {
                    let mut o = 0u32;
                    #[unroll]
                    for kk in 0..nw {
                        o |= wv[comptime!(h * nw + kk) as usize];
                    }
                    nz[h as usize] = o != 0u32;
                }
                {
                    let mut base = Array::<u32>::new(comptime!(hh as usize));
                    let mut rk = Array::<u32>::new(comptime!(hh as usize));
                    let mut nn = 0u32;
                    #[unroll]
                    for h in 0..hh {
                        base[h as usize] = nn;
                        nn += plane_count(nz[h as usize], w);
                    }
                    #[unroll]
                    for h in 0..hh {
                        rk[h as usize] = plane_rank_m(nz[h as usize], rlo, rhi, w);
                    }
                    if nn > 0u32 {
                        if slab_used + nn > 256u32 {
                            if lane == 0u32 && have_slab {
                                slabcnt[slab_id as usize] = slab_used;
                            }
                            let mut sid = 0u32;
                            if lane == 0u32 {
                                sid = slabn[0usize].fetch_add(1u32);
                                if sid < nslab_cap {
                                    slabinst[sid as usize] = CUBE_POS_X;
                                }
                            }
                            slab_id = plane_sum(sid);
                            slab_used = 0u32;
                            have_slab = true;
                        }
                        let sbase = slab_id * 256u32 + slab_used;
                        // mode bit 2 (timing only): the records are not written (their count and slabs are)
                        if slab_id < nslab_cap && (mode & 2u32) == 0u32 {
                            #[unroll]
                            for h in 0..hh {
                                if nz[h as usize] {
                                    let ri = (sbase + base[h as usize] + rk[h as usize]) * comptime!(nw / 2);
                                    #[unroll]
                                    for jj in 0..comptime!(nw / 2) {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        rv[0usize] = pk[h as usize];
                                        rv[1usize] = cpos + comptime!(64 * jj);
                                        rv[2usize] = wv[comptime!(h * nw + 2 * jj) as usize];
                                        rv[3usize] = wv[comptime!(h * nw + 2 * jj + 1) as usize];
                                        out[(ri + jj) as usize] = rv;
                                    }
                                }
                            }
                        }
                        #[unroll]
                        for kk in 0..comptime!(nw * hh) {
                            my_surv += wv[kk as usize].count_ones();
                        }
                        slab_used += nn;
                    }
                }
                e0 += comptime!(nst * hh);
            }
            r += 1u32;
        }
        if lane == 0u32 && have_slab && slab_id < nslab_cap {
            slabcnt[slab_id as usize] = slab_used;
        }
        let ss = plane_sum(my_surv);
        if lane == 0u32 && ss > 0u32 {
            res[(CUBE_POS_X * 4u32 + 1u32) as usize].fetch_add(ss);
        }
        if t == 0u32 {
            res[(CUBE_POS_X * 4u32 + 3u32) as usize].fetch_add(my_lslots);
            res[(CUBE_POS_X * 4u32 + 2u32) as usize].fetch_add(1u32);
        }
    }
}

struct Dump {
    w: u32,
    ninst: usize,
    inst: Vec<u32>,
    rounds: Vec<u32>,
    probes: Vec<u32>,
    lists: Vec<u32>,
    words: Vec<u32>,
    expect: Vec<u32>,
}

fn load(path: &str) -> Result<Dump> {
    let b = std::fs::read(path)?;
    let v: Vec<u32> = b.chunks_exact(4).map(|c| u32::from_le_bytes(c.try_into().unwrap())).collect();
    if v[0] != 0x5744_5448 {
        bail!("{path}: bad magic");
    }
    let (w, ninst, nround, nprobe, nlist, nslr) =
        (v[1], v[2] as usize, v[3] as usize, v[4] as usize, v[5] as usize, v[6] as usize);
    let mut o = 8;
    let mut take = |n: usize| {
        let s = v[o..o + n].to_vec();
        o += n;
        s
    };
    let inst = take(ninst * 8);
    let rounds = take(nround * 8);
    let probes = take(nprobe * 4);
    let lists = take(nlist.max(1));
    let words = take(nslr * SLW);
    let expect = take(ninst * 4);
    Ok(Dump { w, ninst, inst, rounds, probes, lists, words, expect })
}

#[derive(Clone, Copy, Debug)]
struct Var {
    name: &'static str,
    nw: u32,
    hh: u32,
    vec: bool,
    swz: bool,
}

const VARS: &[Var] = &[
    Var { name: "w64", nw: 2, hh: 2, vec: false, swz: false },
    Var { name: "w128s2", nw: 4, hh: 2, vec: false, swz: false },
    Var { name: "w128v2", nw: 4, hh: 2, vec: true, swz: false },
    Var { name: "w128s1", nw: 4, hh: 1, vec: false, swz: false },
    Var { name: "w128v1", nw: 4, hh: 1, vec: true, swz: false },
    Var { name: "w256s1", nw: 8, hh: 1, vec: false, swz: false },
    Var { name: "w256v1", nw: 8, hh: 1, vec: true, swz: false },
    Var { name: "w256v2", nw: 8, hh: 2, vec: true, swz: false },
    Var { name: "w256x1", nw: 8, hh: 1, vec: true, swz: true },
    Var { name: "w256x2", nw: 8, hh: 2, vec: true, swz: true },
];

struct Dev {
    inst: Handle,
    rounds: Handle,
    probes: Handle,
    lists: Handle,
    words: Handle,
    out: Handle,
    slabcnt: Handle,
    slabinst: Handle,
    cap: u32,
    ninst: usize,
    nround: usize,
    nprobe: usize,
    nlist: usize,
    nslr: usize,
}

fn run<R: Runtime>(client: &ComputeClient<R>, w: u32) -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let opt = |name: &str| args.iter().position(|a| a == name).and_then(|i| args.get(i + 1)).cloned();
    let dir = opt("--dump").ok_or_else(|| anyhow!("--dump DIR"))?;
    let pips: Vec<String> = opt("--pips").ok_or_else(|| anyhow!("--pips"))?.split(',').map(String::from).collect();
    let reps: usize = opt("--reps").map_or(Ok(10), |s| s.parse())?;
    let once = args.iter().any(|a| a == "--once");
    // --max-inst N: only the first N instances (a SPIR-V dump on a software device; counts then cover those only)
    let max_inst: Option<usize> = opt("--max-inst").map(|s| s.parse()).transpose()?;
    let vars: Vec<Var> = match opt("--variants") {
        Some(s) => s
            .split(',')
            .map(|n| VARS.iter().copied().find(|v| v.name == n).ok_or_else(|| anyhow!("variant {n}")))
            .collect::<Result<_>>()?,
        None => VARS.to_vec(),
    };
    let mk = |v: &[u32]| client.create(cubecl::bytes::Bytes::from_elems(v.to_vec()));
    let rd = |h: &Handle| -> Result<Vec<u32>> {
        Ok(u32::from_bytes(&client.read_one(h.clone()).map_err(|e| anyhow!("read: {e:?}"))?).to_vec())
    };
    let sync = || cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"));
    println!("W(plane) {w}; reps {reps}; variants {:?}", vars.iter().map(|v| v.name).collect::<Vec<_>>());
    for pip in &pips {
        // the three widths of this slice on the device at once (interleaved timing)
        let mut devs: Vec<(u32, Dev, Vec<u32>)> = Vec::new();
        for wd in [64u32, 128, 256] {
            if !vars.iter().any(|v| v.nw * 32 == wd) {
                continue;
            }
            let mut d = load(&format!("{dir}/s{pip}_w{wd}.bin"))?;
            if let Some(m) = max_inst {
                d.ninst = d.ninst.min(m);
            }
            assert_eq!(d.w, wd);
            let nz: u64 = (0..d.ninst).map(|i| u64::from(d.expect[i * 4])).sum();
            let cap = (nz / 160 + d.ninst as u64 * u64::from(NT / w) + 2048) as u32;
            let nv = (wd / 64) as usize;
            let dv = Dev {
                inst: mk(&d.inst),
                rounds: mk(&d.rounds),
                probes: mk(&d.probes),
                lists: mk(&d.lists),
                words: mk(&d.words),
                out: client.empty(cap as usize * SLAB as usize * nv * 16),
                slabcnt: client.empty(cap as usize * 4),
                slabinst: client.empty(cap as usize * 4),
                cap,
                ninst: d.ninst,
                nround: d.rounds.len() / 8,
                nprobe: d.probes.len() / 4,
                nlist: d.lists.len(),
                nslr: d.words.len() / SLW,
            };
            println!(
                "LOADED s{pip} w{wd}: inst {} rounds {} probes {} list {} word-rounds {} expected nonzero {nz} slab cap {cap}",
                d.ninst, dv.nround, dv.nprobe, dv.nlist, dv.nslr
            );
            devs.push((wd, dv, d.expect));
        }
        sync()?;
        let launch = |v: &Var, dv: &Dev, mode: u32| -> Result<(Handle, Handle)> {
            let slabn = mk(&[0u32]);
            let res = mk(&vec![0u32; dv.ninst * 4]);
            let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n) };
            unsafe {
                k::w3b_kernel::launch_unchecked::<R>(
                    client,
                    CubeCount::Static(dv.ninst as u32, 1, 1),
                    CubeDim::new_1d(NT),
                    a(&dv.inst, dv.ninst * 8),
                    a(&dv.rounds, dv.nround * 8),
                    a(&dv.probes, dv.nprobe),
                    a(&dv.lists, dv.nlist),
                    a(&dv.words, dv.nslr * SLW / 4),
                    a(&dv.out, dv.cap as usize * SLAB as usize * (v.nw / 2) as usize),
                    a(&slabn, 1),
                    a(&dv.slabcnt, dv.cap as usize),
                    a(&dv.slabinst, dv.cap as usize),
                    a(&res, dv.ninst * 4),
                    dv.cap,
                    mode,
                    w,
                    v.nw,
                    v.hh,
                    v.vec,
                    v.swz,
                );
            }
            Ok((slabn, res))
        };
        // exactness first: every variant once, counts per instance against the dump
        let mut ok = Vec::new();
        for v in &vars {
            let (_, dv, ex) = devs.iter().find(|(wd, _, _)| *wd == v.nw * 32).unwrap();
            let (slabn, res) = launch(v, dv, 1)?;
            sync()?;
            let ns = rd(&slabn)?[0];
            let res = rd(&res)?;
            let sc = rd(&dv.slabcnt)?;
            let si = rd(&dv.slabinst)?;
            let mut nzi = vec![0u64; dv.ninst];
            if ns > dv.cap {
                println!("EXACT s{pip} {}: slab overflow {ns} > {}", v.name, dv.cap);
                ok.push(false);
                continue;
            }
            for s in 0..ns as usize {
                nzi[si[s] as usize] += u64::from(sc[s]);
            }
            let (mut bad, mut tnz, mut tb, mut tls, mut ran) = (0usize, 0u64, 0u64, 0u64, 0u64);
            for i in 0..dv.ninst {
                let (enz, eb) = (u64::from(ex[i * 4]), u64::from(ex[i * 4 + 1]));
                if nzi[i] != enz || u64::from(res[i * 4 + 1]) != eb {
                    if bad < 3 {
                        println!(
                            "  MISMATCH {} inst {i}: nonzero {} vs {enz}, bits {} vs {eb}",
                            v.name,
                            nzi[i],
                            res[i * 4 + 1]
                        );
                    }
                    bad += 1;
                }
                tnz += nzi[i];
                tb += u64::from(res[i * 4 + 1]);
                tls += u64::from(res[i * 4 + 3]);
                ran += u64::from(res[i * 4 + 2]);
            }
            let enz: u64 = (0..dv.ninst).map(|i| u64::from(ex[i * 4])).sum();
            let eb: u64 = (0..dv.ninst).map(|i| u64::from(ex[i * 4 + 1])).sum();
            println!(
                "EXACT s{pip} {}: instances ran {ran}/{} | per-instance mismatches {bad} | nonzero {tnz} (dump {enz}) bits {tb} (dump {eb}) | slabs {ns} | kernel lane slots {tls}",
                v.name, dv.ninst
            );
            ok.push(bad == 0 && ran == dv.ninst as u64);
        }
        if once {
            continue;
        }
        // timing: modes {full, no-3b} × variants, interleaved, `reps` rounds of 3 launches each
        let mut tm: Vec<[Vec<f64>; 3]> = vars.iter().map(|_| [Vec::new(), Vec::new(), Vec::new()]).collect();
        for _rep in 0..reps {
            for (vi, v) in vars.iter().enumerate() {
                if !ok[vi] {
                    continue;
                }
                let (_, dv, _) = devs.iter().find(|(wd, _, _)| *wd == v.nw * 32).unwrap();
                for (mi, mode) in [1u32, 0, 3].iter().enumerate() {
                    let pre: Vec<_> = (0..3).map(|_| (mk(&[0u32]), mk(&vec![0u32; dv.ninst * 4]))).collect();
                    drop(pre);
                    sync()?;
                    let t0 = Instant::now();
                    for _ in 0..3 {
                        launch(v, dv, *mode)?;
                    }
                    sync()?;
                    tm[vi][mi].push(t0.elapsed().as_secs_f64() / 3.0 * 1e3);
                }
            }
        }
        for (vi, v) in vars.iter().enumerate() {
            if !ok[vi] {
                println!("TIME s{pip} {}: NOT TIMED (counts differ)", v.name);
                continue;
            }
            let med = |x: &mut Vec<f64>| {
                x.sort_by(|a, b| a.partial_cmp(b).unwrap());
                (x[x.len() / 2], x[0], x[x.len() - 1])
            };
            let (f, fmin, fmax) = med(&mut tm[vi][0].clone());
            let (z, zmin, zmax) = med(&mut tm[vi][1].clone());
            let (ns, nsmin, nsmax) = med(&mut tm[vi][2].clone());
            println!(
                "TIME s{pip} {}: full {f:.4} ms [{fmin:.4}, {fmax:.4}] | no-3b {z:.4} ms [{zmin:.4}, {zmax:.4}] | 3b {:.4} ms (median difference) | no-store {ns:.4} ms [{nsmin:.4}, {nsmax:.4}] store {:.4} ms | raw full {:?} | raw no3b {:?}",
                v.name,
                f - z,
                f - ns,
                tm[vi][0].iter().map(|x| (x * 1e4).round() / 1e4).collect::<Vec<_>>(),
                tm[vi][1].iter().map(|x| (x * 1e4).round() / 1e4).collect::<Vec<_>>()
            );
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let fw: Option<u32> = args
        .iter()
        .position(|a| a == "--force-w")
        .and_then(|i| args.get(i + 1))
        .map(|s| s.parse())
        .transpose()?;
    let ctx = if args.iter().any(|a| a == "--cuda") {
        #[cfg(feature = "cubecl-cuda")]
        {
            CubeclContext::new_cuda(0)?
        }
        #[cfg(not(feature = "cubecl-cuda"))]
        bail!("--cuda needs the cubecl-cuda feature")
    } else {
        CubeclContext::new_default()?
    };
    println!("device {}", ctx.device_name());
    match &ctx {
        CubeclContext::Wgpu { client, .. } => {
            let w = fw.unwrap_or(client.properties().hardware.plane_size_max);
            run(client, w)
        }
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => run(client, fw.unwrap_or(32)),
        #[allow(unreachable_patterns)]
        _ => bail!("unsupported runtime"),
    }
}

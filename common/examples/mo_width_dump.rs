//! What the main kernel's phase 3b consumes, from the CPU reference, at 64, 128 and 256 children per lane word
//! (scratch branch `exp/mo-word-width`, a measurement only; nothing in the library uses this).
//!
//! usage: mo_width_dump <pip> <out_dir> [threads]        dump one base-64 slice
//!        mo_width_dump --field-slices <t> <k>           print the first k slices of field t (coordinate 4,8,5)
//!
//! Per slice it rebuilds `cpu::slice_join`'s objects in its order (parents sorted by class and key, tops per unit
//! split by class, a job's probes = the 8 compatible top classes in root order, a job's children = its class's
//! parents' certified children in order), then for each width W in {64, 128, 256}: chunks of W children, rounds
//! of 1,024 children (16, 8 or 4 chunks), the common-mask skip per chunk, the round's probe listing (the probes
//! that at least one chunk of the round keeps, in probe order; entry = `probe·16 | kept-chunk mask << 16`, as
//! phase 3a writes it), the round's words in the kernel's shared layout `[(v + 65 q)·NW + k]` (NW = W / 32 u32
//! per digit word), and per job instance the expected count of nonzero words and of survivor bits. Jobs of more
//! than 576 probes are two instances, as the kernel queues them. At W 64 the totals are compared with
//! `cpu::slice_join_threads`'s counters (flat, kept, words, survivors + clipped), which the run prints.
//!
//! File `<out_dir>/s<pip>_w<W>.bin`, little-endian u32: header [magic 0x5744_5448, W, ninst, nround, nprobe,
//! nlist, nslr, 0], then inst (ninst × 8: job, c, d, poff, nprobe, probe_off, round_off, nrounds), rounds
//! (nround × 8: slr, nch, ntake, list_off, nlist, cdone, 0, 0), probes (nprobe × 4: `tdig` words, top index in
//! bits 12–31 of word 3), lists (nlist), words (nslr × 2080), expected (ninst × 4: nonzero words, survivor
//! bits, kept (probe, chunk) pairs, lane slots).
#![allow(clippy::cast_possible_truncation, clippy::too_many_lines)]

use nice_common::midout::Coord;
use nice_common::midout::cpu::{
    self, Base, Parent, Shape, Top, child_mask, key_digits, parents, unit_tops,
};
use std::io::Write;

#[path = "mo_width_dump/share.rs"]
mod share;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};

const PMAX: usize = 576;
const MAXPOP: usize = 17;
const SLW: usize = 2080;

fn par_jobs<T: Send>(threads: usize, n: usize, f: impl Fn(usize) -> T + Sync) -> Vec<T> {
    let next = AtomicUsize::new(0);
    let out: Mutex<Vec<Option<T>>> = Mutex::new((0..n).map(|_| None).collect());
    std::thread::scope(|s| {
        for _ in 0..threads {
            s.spawn(|| {
                loop {
                    let i = next.fetch_add(1, Ordering::Relaxed);
                    if i >= n {
                        break;
                    }
                    let r = f(i);
                    out.lock().unwrap()[i] = Some(r);
                }
            });
        }
    });
    out.into_inner().unwrap().into_iter().map(Option::unwrap).collect()
}

/// A top's digits as `tdig` (20 6-bit fields, 5 per word, ascending, padded with the first digit), with its
/// index in bits 12–31 of word 3 (as the main kernel's `prob_d`).
fn tdig(mask: u64, idx: u32) -> [u32; 4] {
    let mut dg = Vec::new();
    let mut y = mask;
    while y != 0 {
        dg.push(y.trailing_zeros());
        y &= y - 1;
    }
    assert!(!dg.is_empty() && dg.len() <= MAXPOP, "top popcount {}", dg.len());
    let first = dg[0];
    while dg.len() < 20 {
        dg.push(first);
    }
    let mut w = [0u32; 4];
    for (k, &v) in dg.iter().enumerate() {
        w[k / 5] |= v << (6 * (k % 5));
    }
    assert!(idx < (1 << 20));
    w[3] = (w[3] & 0xFFF) | (idx << 12);
    w
}

struct Job {
    c: u32,
    d: u32,
    kids: Vec<u64>,
    probes: Vec<(u64, u32)>, // (mask, global top index)
    /// per probe: its certificate's digits in position order (n² from the most significant down, then n³)
    certs: Vec<(Vec<u8>, Vec<u8>)>,
}

/// The certificate's digits of the top over `[a, c]` in position order, as `top_cert_split` finds them: n²'s
/// constant leading digits from the most significant down, then n³'s.
fn cert_order(b: u64, a: u128, c: u128, kpos: u32) -> (Vec<u8>, Vec<u8>) {
    use nice_common::midout::arith::U384;
    let (xa, xc) = (U384::from_u128(a), U384::from_u128(c));
    let (sa, sc) = (xa.mul(&xa), xc.mul(&xc));
    let (ca, cc) = (sa.mul(&xa), sc.mul(&xc));
    let mut out = (Vec::new(), Vec::new());
    for (w, (p, q)) in [(sa, sc), (ca, cc)].into_iter().enumerate() {
        let (dp, dq) = (p.digits(b), q.digits(b));
        if dp.len() != dq.len() {
            continue;
        }
        let mut j = dp.len();
        while j > kpos as usize {
            j -= 1;
            if dp[j] != dq[j] {
                break;
            }
            if w == 0 { out.0.push(dp[j]) } else { out.1.push(dp[j]) }
        }
    }
    out
}

#[derive(Default)]
struct WidthOut {
    inst: Vec<[u32; 8]>,
    rounds: Vec<[u32; 8]>,
    probes: Vec<[u32; 4]>,
    lists: Vec<u32>,
    words: Vec<u32>,
    expect: Vec<[u32; 4]>,
    flat: u64,
    pairs: u64,
}

/// One job at width `wd`: its instances' rows (offsets relative to the job, fixed up by the caller).
fn job_width(j: &Job, wd: usize) -> WidthOut {
    let nw = wd / 32;
    let cpr = 1024 / wd; // chunks per round
    let n = j.kids.len();
    let nround = n.div_ceil(1024);
    let mut o = WidthOut::default();
    // words of each round (shared by the job's instances)
    let mut commons: Vec<Vec<u64>> = Vec::with_capacity(nround);
    let mut valids: Vec<Vec<usize>> = Vec::with_capacity(nround);
    for r in 0..nround {
        let base = o.words.len();
        o.words.resize(base + SLW, 0);
        let mut cm = Vec::new();
        let mut nv = Vec::new();
        let r0 = r * 1024;
        let ntake = (n - r0).min(1024);
        let nch = ntake.div_ceil(wd);
        for q in 0..nch {
            let c0 = r0 + q * wd;
            let nq = (n - c0).min(wd);
            let mut common = !0u64;
            for i in 0..nq {
                let mk = j.kids[c0 + i];
                common &= mk;
                let mut y = mk;
                while y != 0 {
                    let v = y.trailing_zeros() as usize;
                    o.words[base + (v + 65 * q) * nw + i / 32] |= 1u32 << (i % 32);
                    y &= y - 1;
                }
            }
            cm.push(common);
            nv.push(nq);
        }
        commons.push(cm);
        valids.push(nv);
    }
    let np = j.probes.len();
    let ninst = if np > PMAX { 2 } else { 1 };
    for ins in 0..ninst {
        let poff = ins * PMAX;
        let npi = (np - poff).min(PMAX);
        let mut ex = [0u32; 4];
        let mut lsl = 0u64;
        let probe_off = o.probes.len();
        for p in 0..npi {
            let (mk, ti) = j.probes[poff + p];
            o.probes.push(tdig(mk, ti));
        }
        let round_off = o.rounds.len();
        for r in 0..nround {
            let ntake = (n - r * 1024).min(1024);
            let nch = commons[r].len();
            let list_off = o.lists.len();
            for p in 0..npi {
                let (mk, _) = j.probes[poff + p];
                let mut km = 0u32;
                for q in 0..nch {
                    if commons[r][q] & mk == 0 {
                        km |= 1 << q;
                    }
                }
                o.flat += nch as u64;
                if km == 0 {
                    continue;
                }
                o.lists.push((p as u32 * 16) | (km << 16));
                ex[2] += km.count_ones();
                lsl += nch as u64;
                // the words: OR of the probe's digit words over the kept chunks
                let wbase = r * SLW;
                for q in 0..nch {
                    if km >> q & 1 == 0 {
                        continue;
                    }
                    let mut nz = false;
                    for k in 0..nw {
                        let mut acc = 0u32;
                        let mut y = mk;
                        while y != 0 {
                            let v = y.trailing_zeros() as usize;
                            acc |= o.words[wbase + (v + 65 * q) * nw + k];
                            y &= y - 1;
                        }
                        let nq = valids[r][q];
                        let lo = 32 * k;
                        let valid = if nq >= lo + 32 {
                            u32::MAX
                        } else if nq > lo {
                            (1u32 << (nq - lo)) - 1
                        } else {
                            0
                        };
                        let w = !acc & valid;
                        ex[1] += w.count_ones();
                        nz |= w != 0;
                    }
                    ex[0] += u32::from(nz);
                }
            }
            let nlist = o.lists.len() - list_off;
            o.rounds.push([
                r as u32, // slr relative to the job
                nch as u32,
                ntake as u32,
                list_off as u32,
                nlist as u32,
                (r * 1024) as u32,
                0,
                0,
            ]);
        }
        ex[3] = u32::try_from(lsl).unwrap();
        o.inst.push([
            0,
            j.c,
            j.d,
            poff as u32,
            npi as u32,
            probe_off as u32,
            round_off as u32,
            nround as u32,
        ]);
        o.expect.push(ex);
    }
    o.pairs = n as u64 * np as u64;
    o
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let coord = Coord::for_base(64).unwrap();
    let sh = Shape::for_coord(&coord);
    if args[1] == "--field-slices" {
        let t: u128 = args[2].parse().unwrap();
        let k: usize = args[3].parse().unwrap();
        for p in sh.slices_of(&coord, t).take(k) {
            println!("{p}");
        }
        return;
    }
    let pip: u128 = args[1].parse().unwrap();
    let dir = &args[2];
    let threads: usize = args.get(3).map_or(8, |s| s.parse().unwrap());
    let base = Base::new(&coord);
    let b = 64usize;
    let m = 63usize;
    let t0 = std::time::Instant::now();
    // the reference's counters, on their own threads, while the dump is built
    let refc = std::thread::scope(|s| {
        let h = s.spawn(|| cpu::slice_join_threads::<u64>(&base, sh, pip, threads.div_ceil(2), |_, _, _| {}));
        // --- slice_join's preamble (SliceSetup::new), same objects, same order ---
        let ps: Vec<Parent<u64>> = parents::<u64>(&base, sh, pip);
        let step = base.pw[(sh.k - 1 - sh.f0) as usize];
        let tops_by_d: Vec<Vec<Top<u64>>> = par_jobs(threads, b, |d| {
            let mut tt = 0;
            unit_tops::<u64>(&base, sh, pip + d as u128 * step, &mut tt)
        });
        let certs_by_d: Vec<Vec<(Vec<u8>, Vec<u8>)>> = par_jobs(threads, b, |d| {
            tops_by_d[d]
                .iter()
                .map(|t| {
                    let co = cert_order(64, t.lo, t.hi, sh.k);
                    let mut mk = 0u64;
                    for &v in co.0.iter().chain(co.1.iter()) {
                        assert!(mk >> v & 1 == 0);
                        mk |= 1 << v;
                    }
                    assert_eq!(mk, t.mask, "certificate order differs from the mask");
                    co
                })
                .collect()
        });
        let digit_count = |it: &mut dyn Iterator<Item = u64>| -> Vec<u64> {
            let mut f = vec![0u64; b];
            for mut x in it {
                while x != 0 {
                    f[x.trailing_zeros() as usize] += 1;
                    x &= x - 1;
                }
            }
            f
        };
        let fp = digit_count(&mut ps.iter().map(|p| p.mask));
        let ft = digit_count(&mut tops_by_d.iter().flatten().map(|t| t.mask));
        let rank = key_digits(64, &fp, &ft);
        let key = |mk: u64| -> u64 {
            let mut kk = 0u64;
            for (i, &v) in rank.iter().enumerate() {
                kk |= u64::from(mk >> v & 1 != 0) << (7 - i);
            }
            kk
        };
        let mut ps = ps;
        ps.sort_by_key(|p| (u64::from(p.cls) << 8) + (255 - key(p.mask)));
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
        let mut tseg: Vec<Vec<Vec<usize>>> = vec![vec![Vec::new(); m]; b];
        for (d, tv) in tops_by_d.iter().enumerate() {
            for (i, t) in tv.iter().enumerate() {
                tseg[d][(t.h % m as u128) as usize].push(i);
            }
        }
        // a global top index (unit-major), as a record names its top
        let mut toff = vec![0u32; b + 1];
        for d in 0..b {
            toff[d + 1] = toff[d] + tops_by_d[d].len() as u32;
        }
        // jobs in the kernel's order: job = c · 64 + d (one batch of all 63 classes)
        let jobs: Vec<Job> = par_jobs(threads, m * b, |jx| {
            let (c, d) = (jx / b, jx % b);
            let cc = (c + d) % m;
            let mut probes = Vec::new();
            let mut certs = Vec::new();
            for &rt in &base.roots {
                let ct = (rt as usize + m - cc) % m;
                for &ti in &tseg[d][ct] {
                    probes.push((tops_by_d[d][ti].mask, toff[d] + ti as u32));
                    certs.push(certs_by_d[d][ti].clone());
                }
            }
            let mut kids = Vec::new();
            for par in &ps[pseg[c]..pseg[c + 1]] {
                let x = child_mask(64, par, d as u32);
                if x != 0 {
                    kids.push(x);
                }
            }
            Job {
                c: c as u32,
                d: d as u32,
                kids,
                probes,
                certs,
            }
        });
        let nk: usize = jobs.iter().map(|j| j.kids.len()).sum();
        let ntop: u32 = toff[b];
        println!(
            "SLICE {pip} parents {} tops {ntop} children {nk} jobs {} max probes {} ({:.1} s)",
            ps.len(),
            jobs.len(),
            jobs.iter().map(|j| j.probes.len()).max().unwrap(),
            t0.elapsed().as_secs_f64()
        );
        if std::env::var("MO_SHARE").is_ok() {
            share::run(&jobs, pip, dir, threads);
            return h.join().unwrap();
        }
        for wd in [64usize, 128, 256] {
            let parts: Vec<WidthOut> = par_jobs(threads, jobs.len(), |jx| job_width(&jobs[jx], wd));
            let mut all = WidthOut::default();
            for (jx, mut p) in parts.into_iter().enumerate() {
                let (po, ro, lo, so) = (
                    all.probes.len() as u32,
                    all.rounds.len() as u32,
                    all.lists.len() as u32,
                    (all.words.len() / SLW) as u32,
                );
                for r in &mut p.rounds {
                    r[0] += so;
                    r[3] += lo;
                }
                for i in &mut p.inst {
                    i[0] = jx as u32;
                    i[5] += po;
                    i[6] += ro;
                }
                all.inst.extend(p.inst);
                all.rounds.extend(p.rounds);
                all.probes.extend(p.probes);
                all.lists.extend(p.lists);
                all.words.extend(p.words);
                all.expect.extend(p.expect);
                all.flat += p.flat;
                all.pairs += p.pairs;
            }
            let sum = |k: usize| all.expect.iter().map(|e| u64::from(e[k])).sum::<u64>();
            println!(
                "WIDTH {wd} inst {} rounds {} probes {} list {} words_rounds {} | flat {} kept {} nonzero {} bits {} lslots {} pairs {}",
                all.inst.len(),
                all.rounds.len(),
                all.probes.len(),
                all.lists.len(),
                all.words.len() / SLW,
                all.flat,
                sum(2),
                sum(0),
                sum(1),
                sum(3),
                all.pairs
            );
            let path = format!("{dir}/s{pip}_w{wd}.bin");
            let mut f = std::io::BufWriter::new(std::fs::File::create(&path).unwrap());
            let mut put = |v: &[u32]| {
                for x in v {
                    f.write_all(&x.to_le_bytes()).unwrap();
                }
            };
            put(&[
                0x5744_5448,
                wd as u32,
                all.inst.len() as u32,
                all.rounds.len() as u32,
                all.probes.len() as u32,
                all.lists.len() as u32,
                (all.words.len() / SLW) as u32,
                0,
            ]);
            for r in &all.inst {
                put(r);
            }
            for r in &all.rounds {
                put(r);
            }
            for r in &all.probes {
                put(r);
            }
            put(&all.lists);
            put(&all.words);
            for r in &all.expect {
                put(r);
            }
            drop(put);
            f.flush().unwrap();
            println!("WROTE {path} ({:.1} s)", t0.elapsed().as_secs_f64());
        }
        h.join().unwrap()
    });
    println!(
        "REF slice_join_threads: flat {} kept {} words {} survivors {} clipped {} (bits = survivors + clipped = {}) children {} chunks {} pairs {} ({:.1} s)",
        refc.flat,
        refc.kept,
        refc.words,
        refc.survivors,
        refc.clipped,
        refc.survivors + refc.clipped,
        refc.children,
        refc.chunks,
        refc.pairs,
        t0.elapsed().as_secs_f64()
    );
}

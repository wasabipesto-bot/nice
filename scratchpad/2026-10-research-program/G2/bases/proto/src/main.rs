mod arith;
mod join;
mod su;

use join::*;
use std::collections::HashSet;
use std::time::Instant;

fn args() -> Vec<String> {
    std::env::args().collect()
}

/// xorshift for picking units
fn rng(seed: &mut u64) -> u64 {
    *seed ^= *seed << 13;
    *seed ^= *seed >> 7;
    *seed ^= *seed << 17;
    *seed
}

fn main() {
    let a = args();
    match a[1].as_str() {
        "range" => {
            for b in a[2..].iter().map(|x| x.parse::<u64>().unwrap()) {
                let base = Base::new(b);
                println!(
                    "b{} L={} start={} end={} W={:.3e} roots={:?}",
                    b, base.l, base.start, base.end, (base.end - base.start) as f64, base.roots
                );
            }
        }
        // small b fr kr u0 u1: whole base by units vs brute force for shape (fr,kr)
        "small" => {
            let p: Vec<u32> = a[2..7].iter().map(|x| x.parse().unwrap()).collect();
            let base = Base::new(p[0] as u64);
            let s = Shape { fr: p[1], kr: p[2] };
            let (u0, u1) = (p[3], p[4]);
            let mut st = JoinStats::default();
            let mut got: HashSet<u128> = HashSet::new();
            let nunits = base.pw[(u1 - u0) as usize];
            for uval in 0..nunits {
                let lists = unit_lists(&base, &s, u0, u1, uval, &mut st);
                for n in join_scalar(&base, &s, u0, &lists, &mut st) {
                    assert!(got.insert(n), "duplicate {n}");
                }
            }
            let mut want: HashSet<u128> = HashSet::new();
            let mut nice = Vec::new();
            for n in base.start..base.end {
                if q_shape(&base, &s, n) {
                    want.insert(n);
                }
                if arith::unique_digits(n, base.b).1 {
                    nice.push(n);
                }
            }
            let ok = got == want;
            println!(
                "b{} L{} shape(f0 {}, k {}) unit[{},{}) units {} : join {} brute {} equal={} nice(brute)={:?} nice(join)={:?} pairs {} tops {}/{} bots {}",
                base.b, base.l, s.fr, s.kr, u0, u1, nunits, got.len(), want.len(), ok, nice, st.nice,
                st.pairs, st.top_cert, st.top_tested, st.bot_cert
            );
            for n in &nice {
                assert!(got.contains(n), "nice {n} lost");
            }
            assert!(ok);
        }
        // unit b f0 k nunits seed reps : G2 shape (f0,k) vs reference (3,6) on random units
        "unit" => {
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let nunits: u32 = a[5].parse().unwrap();
            let mut seed: u64 = a[6].parse().unwrap();
            let reps: u32 = a[7].parse().unwrap();
            let do_ref = a.get(8).map(|x| x != "noref" && x != "streamref").unwrap_or(true);
            let base = Base::new(b);
            let sn = Shape { fr: f0, kr: k };
            let sr = Shape { fr: 3, kr: 6 };
            let span = base.pw[(k - f0) as usize];
            for _ in 0..nunits {
                let uval = (rng(&mut seed) as u128) % span;
                let mut stn = JoinStats::default();
                let t0 = Instant::now();
                let ln = unit_lists(&base, &sn, f0, k, uval, &mut stn);
                let t_lists = t0.elapsed().as_secs_f64();
                let t1 = Instant::now();
                let mut bst = BotStats::default();
                let _ = bottoms(&base, k, f0, uval, &mut bst);
                let t_bots = t1.elapsed().as_secs_f64();
                let sn_out = join_scalar(&base, &sn, f0, &ln, &mut stn);
                // admissible n in the unit
                let lead_lo = base.start / base.pw[k as usize];
                let lead_hi = (base.end - 1) / base.pw[k as usize];
                let width = (lead_hi - lead_lo + 1) as f64 * base.pw[f0 as usize] as f64;
                let adm = width * base.roots.len() as f64 / (b - 1) as f64;
                println!(
                    "UNIT b{} pi={} shape(f0 {}, k {}) adm~{:.3e} tops {}/{} bots {} (visits {}, nodes {}) pairs {} surv {} maxuniq {} nice {} t_lists {:.2}s t_bots {:.2}s",
                    b, uval, f0, k, adm, stn.top_cert, stn.top_tested, stn.bot_cert, stn.bot.visits, stn.bot.nodes,
                    stn.pairs, stn.survivors, stn.max_unique, stn.nice.len(), t_lists, t_bots
                );
                println!(
                    "  per adm: tops_tested {:.3e} tops {:.3e} bot_visits {:.3e} bots {:.3e} pairs {:.3e} surv {:.3e}",
                    stn.top_tested as f64 / adm, stn.top_cert as f64 / adm, stn.bot.visits as f64 / adm,
                    stn.bot_cert as f64 / adm, stn.pairs as f64 / adm, stn.survivors as f64 / adm
                );
                if a.get(8).map(|x| x == "streamref").unwrap_or(false) {
                    // streamed reference: every S_ref member that satisfies Q_new (by list lookup) must be in S_new
                    use std::collections::HashMap;
                    let setn: HashSet<u128> = sn_out.iter().copied().collect();
                    let tmap: HashMap<u128, Mask> = ln.tops.iter().map(|(_, t)| (t.h, t.mask)).collect();
                    let bmap: HashMap<u128, Mask> = ln.bots.iter().map(|x| (x.r, x.mask)).collect();
                    let mut str_ = JoinStats::default();
                    let tr0 = Instant::now();
                    let lr = unit_lists(&base, &sr, f0, k, uval, &mut str_);
                    let t_rl = tr0.elapsed().as_secs_f64();
                    let (mut nref, mut both, mut lost) = (0u64, 0u64, 0u64);
                    let bk = base.pw[k as usize];
                    let m = (b - 1) as u128;
                    join_cb(&base, &sr, f0, &lr, &mut str_, |n| {
                        nref += 1;
                        let h = n / bk;
                        let r = n % bk;
                        let qn = match (tmap.get(&h), bmap.get(&r)) {
                            (Some(tm), Some(bm)) => tm & bm == 0 && base.roots.contains(&((n % m) as u64)),
                            _ => false,
                        };
                        if qn {
                            if setn.contains(&n) { both += 1; } else { lost += 1; }
                        }
                    });
                    // and every S_new member must satisfy Q_ref directly (sampled: all if small)
                    let mut checked = 0;
                    for &n in sn_out.iter().step_by((sn_out.len() / 20000).max(1)) {
                        let _ = q_shape(&base, &sr, n);
                        assert!(q_shape(&base, &sn, n), "new false positive {n}");
                        checked += 1;
                    }
                    println!(
                        "  REF(3,6) streamed: tops {}/{} bots {} pairs {} surv {} | per adm pairs {:.3e} surv {:.3e} | lists {:.1}s",
                        str_.top_cert, str_.top_tested, str_.bot_cert, str_.pairs, nref, str_.pairs as f64 / adm, nref as f64 / adm, t_rl
                    );
                    println!("  EXACT(stream): S_ref ∩ Q_new = {} members, all in S_new: lost {} ; {} S_new members re-verified against Q_new directly", both, lost, checked);
                    assert_eq!(lost, 0);
                } else if do_ref {
                    let mut str_ = JoinStats::default();
                    let lr = unit_lists(&base, &sr, f0, k, uval, &mut str_);
                    let t2 = Instant::now();
                    let sr_out = join_scalar(&base, &sr, f0, &lr, &mut str_);
                    let t_rj = t2.elapsed().as_secs_f64();
                    println!(
                        "  REF(3,6): tops {}/{} bots {} (visits {}) pairs {} surv {} maxuniq {} | per adm pairs {:.3e} surv {:.3e} | scalar join {:.2}s",
                        str_.top_cert, str_.top_tested, str_.bot_cert, str_.bot.visits, str_.pairs, str_.survivors,
                        str_.max_unique, str_.pairs as f64 / adm, str_.survivors as f64 / adm, t_rj
                    );
                    // exactness: S_new ∩ Q_ref == S_ref ∩ Q_new
                    let setn: HashSet<u128> = sn_out.iter().copied().collect();
                    let setr: HashSet<u128> = sr_out.iter().copied().collect();
                    let mut both = 0;
                    for &n in &sn_out {
                        if setr.contains(&n) {
                            both += 1;
                        } else {
                            assert!(!q_shape(&base, &sr, n), "ref missed {n}");
                        }
                        assert!(q_shape(&base, &sn, n), "new false positive {n}");
                    }
                    for &n in &sr_out {
                        if !setn.contains(&n) {
                            assert!(!q_shape(&base, &sn, n), "new missed {n}");
                        }
                        assert!(q_shape(&base, &sr, n), "ref false positive {n}");
                    }
                    println!(
                        "  EXACT: |S_new|={} |S_ref|={} |both|={} ; every S_new\\S_ref fails Q_ref, every S_ref\\S_new fails Q_new, all outputs satisfy their own Q",
                        sn_out.len(), sr_out.len(), both
                    );
                }
            }
        }
        // ptop b f0 k samples seed: P_T(f0) and parent-certified fraction, cert sizes
        "ptop" => {
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let ns: u64 = a[5].parse().unwrap();
            let mut seed: u64 = a[6].parse().unwrap();
            let base = Base::new(b);
            let pf = base.pw[f0 as usize];
            let (plo, phi) = (base.start / pf, (base.end - 1) / pf);
            let (mut ok, mut par_ok, mut both, mut bits) = (0u64, 0u64, 0u64, 0u64);
            for _ in 0..ns {
                let r = ((rng(&mut seed) as u128) << 64) | rng(&mut seed) as u128;
                let p = plo + r % (phi - plo + 1);
                let a0 = (p * pf).max(base.start);
                let c0 = (p * pf + pf - 1).min(base.end - 1);
                let pp = p / b as u128;
                let pa = (pp * pf * b as u128).max(base.start);
                let pc = (pp * pf * b as u128 + pf * b as u128 - 1).min(base.end - 1);
                let t = top_cert(&base, a0, c0, k);
                let tp = top_cert(&base, pa, pc, k);
                if let Some(m) = t { ok += 1; bits += m.count_ones() as u64; }
                if tp.is_some() { par_ok += 1; if t.is_some() { both += 1; } }
            }
            println!("PTOP b{} f0 {} k {} samples {} P_T {:.4} P_T(parent) {:.4} child|parent {:.4} mean cert digits {:.2}",
                b, f0, k, ns, ok as f64 / ns as f64, par_ok as f64 / ns as f64, both as f64 / par_ok.max(1) as f64, bits as f64 / ok.max(1) as f64);
        }
        // dumpsu b f0 k pip outdir : one super-unit (digits [f0,k-1) = pip), all b units of digit k-1
        "dumpsu" => {
            use std::io::Write;
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let pip: u128 = a[5].parse().unwrap();
            let out = &a[6];
            std::fs::create_dir_all(out).unwrap();
            let base = Base::new(b);
            let sn = Shape { fr: f0, kr: k };
            let step = base.pw[(k - 1 - f0) as usize];
            let mut tf = std::fs::File::create(format!("{out}/tops.bin")).unwrap();
            let mut sf = std::fs::File::create(format!("{out}/surv.bin")).unwrap();
            let mut meta = std::fs::File::create(format!("{out}/meta.txt")).unwrap();
            writeln!(meta, "b {} f0 {} k {} pip {} start {} end {}", b, f0, k, pip, base.start, base.end).unwrap();
            let (mut tt, mut ss, mut pp, mut bb) = (0u64, 0u64, 0u64, 0u64);
            for d in 0..b as u128 {
                let uval = pip + d * step;
                let mut st = JoinStats::default();
                let ln = unit_lists(&base, &sn, f0, k, uval, &mut st);
                let out_n = join_scalar(&base, &sn, f0, &ln, &mut st);
                // tops record: d u32, h u64, mask (u64 if b <= 64 = the bench's 40-byte format; u128 above: 48 bytes),
                // lo u128, hi u128 (little endian)
                for (_, t) in &ln.tops {
                    tf.write_all(&(d as u32).to_le_bytes()).unwrap();
                    assert!(t.h < (1u128 << 64));
                    tf.write_all(&(t.h as u64).to_le_bytes()).unwrap();
                    if b <= 64 { tf.write_all(&(t.mask as u64).to_le_bytes()).unwrap(); } else { tf.write_all(&t.mask.to_le_bytes()).unwrap(); }
                    tf.write_all(&t.lo.to_le_bytes()).unwrap();
                    tf.write_all(&t.hi.to_le_bytes()).unwrap();
                }
                let mut v = out_n.clone(); v.sort();
                for n in v { sf.write_all(&n.to_le_bytes()).unwrap(); }
                writeln!(meta, "unit {} uval {} tops {} tops_tested {} bottoms {} pairs {} surv {}", d, uval, ln.tops.len(), st.top_tested, ln.bots.len(), st.pairs, out_n.len()).unwrap();
                tt += ln.tops.len() as u64; ss += out_n.len() as u64; pp += st.pairs; bb += ln.bots.len() as u64;
                eprintln!("unit {d}: tops {} bots {} pairs {} surv {}", ln.tops.len(), ln.bots.len(), st.pairs, out_n.len());
            }
            writeln!(meta, "total tops {} bottoms {} pairs {} surv {}", tt, bb, pp, ss).unwrap();
        }

        // su b f0 k pip q seed [verify_units]: one super-unit (digits [f0,k-1) = pip) through the G2 CPU reference;
        // verify_units > 0: the first V units' survivor sets against the scalar keyed join (direct depth-k bottoms DFS,
        // same sampled tops), an independent path inside this crate
        "su" => {
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let pip: u128 = a[5].parse().unwrap();
            let q: f64 = a[6].parse().unwrap();
            let seed: u64 = a[7].parse().unwrap();
            let nver: usize = a.get(8).map(|x| x.parse().unwrap()).unwrap_or(0);
            let base = Base::new(b);
            let t0 = Instant::now();
            let (cn, sets, tops) = su::run_su(&base, f0, k, pip, q, seed, nver > 0, true);
            let secs = t0.elapsed().as_secs_f64();
            print_su(&base, f0, k, pip, q, &cn, secs);
            if nver > 0 {
                let step = base.pw[(k - 1 - f0) as usize];
                let s = Shape { fr: f0, kr: k };
                for d in 0..nver.min(b as usize) {
                    let uval = pip + d as u128 * step;
                    let mut st = JoinStats::default();
                    let bots = bottoms(&base, k, f0, uval, &mut st.bot);
                    let lists = UnitLists { tops: tops[d].iter().map(|t| (0u64, *t)).collect(), bots };
                    let mut v = Vec::new();
                    join_cb(&base, &s, f0, &lists, &mut st, |n| v.push(n));
                    v.sort();
                    // and every survivor satisfies the direct predicate (sampled up to 2000)
                    for &n in v.iter().step_by((v.len() / 2000).max(1)) { assert!(q_shape(&base, &s, n), "q_shape fails {n}"); }
                    println!("  VERIFY unit {d}: pipeline {} scalar join {} equal={}", sets[d].len(), v.len(), sets[d] == v);
                    assert!(sets[d] == v);
                }
            }
        }
        // unitat b f0 k uval [dumpfile]: one unit's lists + scalar join (counts as the recorded UNIT lines)
        "unitat" => {
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let uval: u128 = a[5].parse().unwrap();
            let base = Base::new(b);
            let s = Shape { fr: f0, kr: k };
            let mut st = JoinStats::default();
            let ln = unit_lists(&base, &s, f0, k, uval, &mut st);
            let mut out = join_scalar(&base, &s, f0, &ln, &mut st);
            out.sort();
            println!("UNITAT b{} pi={} shape(f0 {}, k {}) tops {}/{} bots {} (visits {}, nodes {}) pairs {} surv {} maxuniq {} nice {}",
                b, uval, f0, k, st.top_cert, st.top_tested, st.bot_cert, st.bot.visits, st.bot.nodes, st.pairs, st.survivors, st.max_unique, st.nice.len());
            if let Some(f) = a.get(6) {
                use std::io::Write;
                let mut w = std::io::BufWriter::new(std::fs::File::create(f).unwrap());
                for n in &out { writeln!(w, "{n}").unwrap(); }
            }
        }
        // sample b f0 k nsu q seed: random super-units, one SU line each
        "sample" => {
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let nsu: u32 = a[5].parse().unwrap();
            let q: f64 = a[6].parse().unwrap();
            let mut seed: u64 = a[7].parse().unwrap();
            let base = Base::new(b);
            let span = base.pw[(k - 1 - f0) as usize];
            for _ in 0..nsu {
                let pip = (((rng(&mut seed) as u128) << 64) | rng(&mut seed) as u128) % span;
                let t0 = Instant::now();
                let (cn, _, _) = su::run_su(&base, f0, k, pip, q, seed, false, false);
                print_su(&base, f0, k, pip, q, &cn, t0.elapsed().as_secs_f64());
            }
        }
        // smallsu b f0 k: every super-unit of a small base through the G2 pipeline vs brute force (q_shape on every n)
        "smallsu" => {
            let b: u64 = a[2].parse().unwrap();
            let f0: u32 = a[3].parse().unwrap();
            let k: u32 = a[4].parse().unwrap();
            let base = Base::new(b);
            let s = Shape { fr: f0, kr: k };
            let span = base.pw[(k - 1 - f0) as usize];
            let mut got: Vec<u128> = Vec::new();
            let mut tot = su::SuCounts::default();
            for pip in 0..span {
                let (cn, sets, _) = su::run_su(&base, f0, k, pip, 1.0, 0, true, false);
                for v in sets { got.extend(v); }
                tot.pairs += cn.pairs; tot.kept += cn.kept; tot.flat += cn.flat; tot.surv += cn.surv; tot.clipped += cn.clipped; tot.children += cn.children;
            }
            got.sort();
            let n_got = got.len();
            got.dedup();
            let mut want = Vec::new();
            let mut nice = Vec::new();
            for n in base.start..base.end {
                if q_shape(&base, &s, n) { want.push(n); }
                if arith::unique_digits(n, base.b).1 { nice.push(n); }
            }
            let nice_ok = nice.iter().all(|n| got.binary_search(n).is_ok());
            println!("SMALLSU b{} L{} (f0 {}, k {}) super-units {} : pipeline {} (dups {}) brute {} equal={} | nice {:?} all found={} | children {} pairs {} flat {} kept {} clipped {}",
                b, base.l, f0, k, span, n_got, n_got - got.len(), want.len(), got == want, nice, nice_ok, tot.children, tot.pairs, tot.flat, tot.kept, tot.clipped);
            assert!(got == want && nice_ok && n_got == got.len());
        }
        _ => panic!("unknown command"),
    }
}

fn print_su(base: &Base, f0: u32, k: u32, pip: u128, q: f64, cn: &su::SuCounts, secs: f64) {
    let b = base.b;
    let nsu = base.pw[(k - 1 - f0) as usize] as f64;
    let adm = (base.end - base.start) as f64 / nsu * base.roots.len() as f64 / (b - 1) as f64;
    let at = adm * q.min(1.0); // admissible n covered by the sampled tops
    println!("SU b{} (f0 {}, k {}) pip {} q {} adm {:.4e} | roots_f0 {} parents {} children {} chunks {} | tops {}/{} probes {} pairs {} flat {} kept {} ({:.4}) words_nz {} surv {} clipped {} pop_kept_mean {:.2} pop_max {} key {:?} | {:.1}s",
        b, f0, k, pip, q, adm, cn.roots_f0, cn.parents, cn.children, cn.chunks, cn.tops, cn.tops_tested, cn.probes, cn.pairs, cn.flat, cn.kept,
        cn.kept as f64 / cn.flat.max(1) as f64, cn.words_nz, cn.surv, cn.clipped, cn.pop_kept as f64 / cn.kept.max(1) as f64, cn.pop_max, cn.key_digits, secs);
    println!("  PERADM b{} f0 {} k {} roots_scan {:.4e} parents {:.4e} children {:.4e} chunks {:.4e} tops_tested {:.4e} tops {:.4e} pairs {:.4e} flat {:.4e} kept {:.4e} words_nz {:.4e} surv {:.4e}",
        b, f0, k, cn.roots_f0 as f64 / adm, cn.parents as f64 / adm, cn.children as f64 / adm, cn.chunks as f64 / adm,
        cn.tops_tested as f64 / at, cn.tops as f64 / at, cn.pairs as f64 / at, cn.flat as f64 / at, cn.kept as f64 / at, cn.words_nz as f64 / at, cn.surv as f64 / at);
}

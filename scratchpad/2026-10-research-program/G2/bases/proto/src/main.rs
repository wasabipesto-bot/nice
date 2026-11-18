mod andv;
mod pipe;
mod arith;
mod join;

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
                // pairing variants
                if std::env::var("G2_PIPE").is_ok() {
                    for cl in [false, true] {
                        pipe::run(&base, f0, k, uval, &ln.tops, stn.survivors, adm, cl);
                    }
                }
                if std::env::var("G2_NOCLUSTER").is_err() {
                    // clustering counts, both orientations
                    let m = (b - 1) as usize;
                    let mut tg: Vec<Vec<u64>> = vec![Vec::new(); m];
                    for (_, t) in &ln.tops { tg[(t.h % m as u128) as usize].push(t.mask); }
                    let mut bg: Vec<Vec<u64>> = vec![Vec::new(); m];
                    for x in &ln.bots { bg[(x.r % m as u128) as usize].push(x.mask); }
                    let mut pb = Vec::new();
                    for x in &ln.bots { let cb = (x.r % m as u128) as u64; for &rt in &base.roots { pb.push((x.mask, ((rt + m as u64 - cb) % m as u64) as usize)); } }
                    let mut pt = Vec::new();
                    for (_, t) in &ln.tops { let ct = (t.h % m as u128) as u64; for &rt in &base.roots { pt.push((t.mask, ((rt + m as u64 - ct) % m as u64) as usize)); } }
                    {
                        // TD with flat chunks sorted by (a) the child's own mask, (b) the parent's mask (shareable by the 62-64 sibling units)
                        let bk1 = base.pw[(k - 1) as usize];
                        let bkk = base.pw[k as usize];
                        let mut it_child: Vec<Vec<(u64, u64)>> = vec![Vec::new(); m];
                        let mut it_par: Vec<Vec<(u64, u64)>> = vec![Vec::new(); m];
                        for x in &ln.bots {
                            let r2 = (x.r * x.r) % bkk; let r3 = (r2 * x.r) % bkk;
                            let e2 = (r2 / bk1) % b as u128; let e3 = (r3 / bk1) % b as u128;
                            let pm = x.mask & !((1u64 << e2) | (1u64 << e3));
                            let g = (x.r % m as u128) as usize;
                            it_child[g].push((x.mask, x.mask));
                            it_par[g].push((x.mask, pm));
                        }
                        let (f1, k1) = andv::sorted_chunks_eval(&it_child, &pt);
                        let (f2, k2) = andv::sorted_chunks_eval(&it_par, &pt);
                        println!("  SORTED TD: flat {} | child-key kept {} ({:.3}, {:.3e}/adm) | parent-key kept {} ({:.3}, {:.3e}/adm)",
                            f1, k1, k1 as f64 / f1 as f64, k1 as f64 / adm, k2, k2 as f64 / f2 as f64, k2 as f64 / adm);
                    }
                    for (name, items, probes) in [("bottom-driven (tops chunked)", &tg, &pb), ("top-driven (bottoms chunked)", &bg, &pt)] {
                        for w in [false, true] {
                        let o = andv::cluster_eval_w(items, probes, w);
                        println!("  CLUSTER{} {}: pairs {} flat_chunks {} ({:.3e}/adm) trie_leaves {} kept {} ({:.3} of flat, {:.3e}/adm) descent_nodes {} ({:.3} of flat)",
                            if w { "(probe-weighted)" } else { "" }, name, o[0], o[1], o[1] as f64 / adm, o[2], o[3], o[3] as f64 / o[1] as f64, o[3] as f64 / adm, o[4], o[4] as f64 / o[1] as f64);
                        }
                    }
                }
                for by_mask in (if std::env::var("G2_NOVAR").is_ok() { vec![] } else { vec![false, true] }) {
                let groups = andv::build_groups(&base, &ln.tops, by_mask);
                let vs = andv::run_variants(&base, &groups, &ln.bots, reps);
                println!("  [chunk order: {}]", if by_mask { "mask-clustered" } else { "leading digits" });
                println!(
                    "  variants: pairs {} chunk_inc {} kept {} ({:.3}) schunk_inc {} kept {} ({:.3}) digit_ops {} surv {:?}",
                    vs.pairs, vs.chunk_inc, vs.chunk_kept, vs.chunk_kept as f64 / vs.chunk_inc as f64,
                    vs.schunk_inc, vs.schunk_kept, vs.schunk_kept as f64 / vs.schunk_inc.max(1) as f64, vs.digit_ops, vs.surv
                );
                println!(
                    "  ns/pair: scalar {:.4} sliced {:.4} 4R {:.4} 4R+skip {:.4} 4R+2skip {:.4} | ns/bottom-chunk: sliced {:.3} 4R {:.3}",
                    vs.secs[0] * 1e9 / vs.pairs as f64, vs.secs[1] * 1e9 / vs.pairs as f64,
                    vs.secs[2] * 1e9 / vs.pairs as f64, vs.secs[3] * 1e9 / vs.pairs as f64,
                    vs.secs[4] * 1e9 / vs.pairs as f64,
                    vs.secs[1] * 1e9 / vs.chunk_inc as f64, vs.secs[2] * 1e9 / vs.chunk_inc as f64
                );
                }
                if a.get(8).map(|x| x == "streamref").unwrap_or(false) {
                    // streamed reference: every S_ref member that satisfies Q_new (by list lookup) must be in S_new
                    use std::collections::HashMap;
                    let setn: HashSet<u128> = sn_out.iter().copied().collect();
                    let tmap: HashMap<u128, u64> = ln.tops.iter().map(|(_, t)| (t.h, t.mask)).collect();
                    let bmap: HashMap<u128, u64> = ln.bots.iter().map(|x| (x.r, x.mask)).collect();
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
                // tops record: d u32, h u64, mask u64, lo u128, hi u128  (little endian)
                for (_, t) in &ln.tops {
                    tf.write_all(&(d as u32).to_le_bytes()).unwrap();
                    tf.write_all(&(t.h as u64).to_le_bytes()).unwrap();
                    tf.write_all(&t.mask.to_le_bytes()).unwrap();
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
        _ => panic!("unknown command"),
    }
}

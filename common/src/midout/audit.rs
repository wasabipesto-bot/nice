//! (dev/mo-audit) The audit of the middle-out join's device path, 2026-11-18:
//! a parity sweep of the device against the CPU reference on many real
//! base-64 slices, and fault injection into the device path to see which
//! failures the host's accounts catch. Tests only; every test is ignored
//! (they need a CUDA card and minutes to hours of CPU).
//!
//! Environment: `AUDIT_SLICES` (comma list of slices, digits 4-8) or
//! `AUDIT_SEED` + `AUDIT_N` (seeded uniform slices over the base);
//! `AUDIT_THREADS` CPU workers (5); `AUDIT_OUT` a JSON-lines file;
//! `AUDIT_FAULTS` (comma list of fault bit sets) for `audit_faults`.

use super::*;
use crate::midout::cpu::{Base, Counts, parents, slice_join};
use std::io::Write;

fn env_u64(k: &str, d: u64) -> u64 {
    std::env::var(k).ok().map_or(d, |s| s.parse().unwrap())
}

fn splitmix(x: &mut u64) -> u64 {
    *x = x.wrapping_add(0x9E37_79B9_7F4A_7C15);
    let mut z = *x;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
    z ^ (z >> 31)
}

/// The slices of a run: `AUDIT_SLICES`, else `AUDIT_N` seeded by `AUDIT_SEED`.
fn audit_slices() -> Vec<u64> {
    if let Ok(s) = std::env::var("AUDIT_SLICES") {
        return s.split(',').filter(|x| !x.is_empty()).map(|x| x.trim().parse().unwrap()).collect();
    }
    let mut st = env_u64("AUDIT_SEED", 20_261_118);
    (0..env_u64("AUDIT_N", 300))
        .map(|_| splitmix(&mut st) & ((1 << 30) - 1))
        .collect()
}

/// An order-independent hash of a set of n (count, wrapping sum, xor of a mix).
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct SetHash(u64, u64, u64);

impl SetHash {
    fn add(&mut self, n: u128) {
        let mut x = (n as u64) ^ ((n >> 64) as u64).rotate_left(17);
        let h = splitmix(&mut x);
        self.0 += 1;
        self.1 = self.1.wrapping_add(h);
        self.2 ^= h.rotate_left(29);
    }
}

/// What the CPU reference says about a slice.
struct Ref {
    pip: u64,
    st: SliceTops,
    pass: Vec<u128>,
    all: SetHash,
    cn: Counts,
    cls_max: usize,
    cls_min: usize,
    bucket_max: usize,
    probe_min: u32,
    zero_jobs: u32,
    cpu_s: f64,
}

fn reference(base: &Base, roots: &[u32], pip: u64) -> Ref {
    let t0 = Instant::now();
    let st = slice_tops(pip, roots);
    let mut pass = Vec::new();
    let mut all = SetHash::default();
    let cn = slice_join::<u64>(base, Shape { f0: 4, k: 10 }, u128::from(pip), |_, n, p| {
        all.add(n);
        if p {
            pass.push(n);
        }
    });
    pass.sort_unstable();
    // class sizes (the main kernel's pending parent index is 16 bits) and the device's sort buckets (class, key)
    let ps = parents::<u64>(base, Shape { f0: 4, k: 10 }, u128::from(pip));
    let mut cls = vec![0usize; 63];
    let mut bk = std::collections::HashMap::<u32, usize>::new();
    for p in &ps {
        cls[p.cls as usize] += 1;
        let mut k8 = 0u32;
        for (i, &v) in st.rank.iter().enumerate() {
            k8 |= (((p.mask >> v) & 1) as u32) << (7 - i);
        }
        *bk.entry(p.cls * 256 + (255 - k8)).or_default() += 1;
    }
    let mut probe_min = u32::MAX;
    let mut zero_jobs = 0;
    for c in 0..63u32 {
        for d in 0..64u32 {
            let cc = (c + d) % M;
            let mut n = 0;
            for &r in &ROOTS {
                let ct = (r + M - cc) % M;
                let s = ((d * M + ct) * 2) as usize;
                n += st.tseg[s + 1] - st.tseg[s];
            }
            probe_min = probe_min.min(n);
            zero_jobs += u32::from(n == 0);
        }
    }
    Ref {
        pip,
        cls_max: *cls.iter().max().unwrap(),
        cls_min: *cls.iter().min().unwrap(),
        bucket_max: bk.values().copied().max().unwrap_or(0),
        st,
        pass,
        all,
        cn,
        probe_min,
        zero_jobs,
        cpu_s: t0.elapsed().as_secs_f64(),
    }
}

fn cuda_client() -> cubecl::prelude::ComputeClient<cubecl::cuda::CudaRuntime> {
    match crate::cubecl_backend::CubeclContext::new_cuda(0).expect("a CUDA device") {
        crate::cubecl_backend::CubeclContext::Cuda { client, .. } => client,
        #[allow(unreachable_patterns)]
        _ => panic!("not CUDA"),
    }
}

/// The parity sweep: for every slice, the device (production kernels, device tops) against the CPU reference:
/// device tops = host tops; the prefiltered list = the reference's, n for n; with the prefilter off (`F_NOPF`), the
/// whole survivor set = the reference's (count and an order-independent hash); children, chunks, flat, survivors,
/// checked equal. One JSON line per slice with the limits' observed values. Fails at the end if any slice differs.
#[test]
#[ignore = "needs CUDA and hours of CPU"]
fn audit_sweep() {
    let pips = audit_slices();
    let threads = env_u64("AUDIT_THREADS", 5) as usize;
    let out_path = std::env::var("AUDIT_OUT").unwrap_or_else(|_| "/root/audit/sweep.jsonl".into());
    let mut out = std::fs::OpenOptions::new().create(true).append(true).open(&out_path).unwrap();
    let client = cuda_client();
    let gj = GpuJoin::new(client.clone(), Caps::b64(63)).unwrap();
    let mut gn = GpuJoin::new(client, Caps::b64(63)).unwrap();
    gn.set_fault(F_NOPF);
    let coord = Coord::for_base(64).unwrap();
    let base = Base::new(&coord);
    let roots = gj.roots().to_vec();
    let next = AtomicUsize::new(0);
    let (tx, rx) = mpsc::sync_channel::<Ref>(threads);
    let mut bad = Vec::new();
    std::thread::scope(|s| {
        for _ in 0..threads {
            let tx = tx.clone();
            let (next, pips, base, roots) = (&next, &pips, &base, &roots);
            s.spawn(move || {
                loop {
                    let i = next.fetch_add(1, Ordering::Relaxed);
                    if i >= pips.len() {
                        break;
                    }
                    if tx.send(reference(base, roots, pips[i])).is_err() {
                        break;
                    }
                }
            });
        }
        drop(tx);
        let mut k = 0;
        for r in rx {
            k += 1;
            let t0 = Instant::now();
            let pip = r.pip;
            let mut why = Vec::new();
            // production kernels, device tops
            let (dc, mut got, mut tops) = match gj.run_slice_dev(pip, &r.st.rank, usize::MAX) {
                Ok(x) => x,
                Err(e) => {
                    why.push(format!("device error: {e}"));
                    (DevCounts::default(), Vec::new(), Vec::new())
                }
            };
            let mut htops: Vec<(u32, u64)> = r.st.thd.iter().copied().zip(r.st.tmask.iter().copied()).collect();
            htops.sort_unstable();
            tops.sort_unstable();
            if tops != htops {
                why.push(format!("tops differ: device {} host {}", tops.len(), htops.len()));
            }
            got.sort_unstable();
            if got != r.pass {
                let gs: std::collections::HashSet<u128> = got.iter().copied().collect();
                let ws: std::collections::HashSet<u128> = r.pass.iter().copied().collect();
                let miss: Vec<u128> = ws.difference(&gs).copied().take(5).collect();
                let extra: Vec<u128> = gs.difference(&ws).copied().take(5).collect();
                why.push(format!(
                    "prefiltered lists differ: device {} cpu {}; missing {miss:?} extra {extra:?}",
                    got.len(),
                    r.pass.len()
                ));
            }
            let cn = &r.cn;
            if (dc.children, dc.chunks, dc.flat, dc.survivors, dc.checked)
                != (cn.children, cn.chunks, cn.flat, cn.survivors, cn.checked)
            {
                why.push(format!(
                    "counts differ: device {:?} cpu {:?}",
                    (dc.children, dc.chunks, dc.flat, dc.survivors, dc.checked),
                    (cn.children, cn.chunks, cn.flat, cn.survivors, cn.checked)
                ));
            }
            // the whole survivor set, prefilter off
            let mut ah = SetHash::default();
            let mut dn = DevCounts::default();
            match gn.run_slice_dev(pip, &r.st.rank, usize::MAX) {
                Ok((d2, all, _)) => {
                    for &n in &all {
                        ah.add(n);
                    }
                    dn = d2;
                }
                Err(e) => why.push(format!("device (no prefilter) error: {e}")),
            }
            if ah != r.all {
                why.push(format!("survivor sets differ: device {ah:?} cpu {:?}", r.all));
            }
            if dn.checked != cn.survivors {
                why.push(format!("no-prefilter checked {} != survivors {}", dn.checked, cn.survivors));
            }
            let ok = why.is_empty();
            let line = format!(
                "{{\"pip\":{pip},\"ok\":{ok},\"why\":{:?},\"tops\":{},\"tested\":{},\"maxpop\":{},\"maxprobe\":{},\"probe_min\":{},\"zero_jobs\":{},\"parents\":{},\"cls_max\":{},\"cls_min\":{},\"bucket_max\":{},\"children\":{},\"chunks\":{},\"flat\":{},\"kept_dev\":{},\"kept_cpu\":{},\"survivors\":{},\"checked\":{},\"slabs_max\":{},\"list_max\":{},\"list_max_nopf\":{},\"slabs_max_nopf\":{},\"flat_d_max\":{},\"surv_d_max\":{},\"cpu_s\":{:.1},\"dev_s\":{:.2}}}",
                why.join(" | "),
                r.st.tmask.len(),
                dc.tested,
                r.st.maxpop,
                r.st.maxprobe,
                r.probe_min,
                r.zero_jobs,
                cn.parents,
                r.cls_max,
                r.cls_min,
                r.bucket_max,
                cn.children,
                cn.chunks,
                cn.flat,
                dc.kept,
                cn.kept,
                cn.survivors,
                cn.checked,
                dc.slabs_max,
                dc.list_max,
                dn.list_max,
                dn.slabs_max,
                dc.flat_d_max,
                dc.surv_d_max,
                r.cpu_s,
                t0.elapsed().as_secs_f64()
            );
            writeln!(out, "{line}").unwrap();
            out.flush().unwrap();
            println!("[{k}/{}] slice {pip}: {}", pips.len(), if ok { "equal".to_string() } else { why.join(" | ") });
            if !ok {
                bad.push(pip);
            }
        }
    });
    assert!(bad.is_empty(), "slices that differ: {bad:?}");
}

/// The host's tops of many slices only (no join): the distribution of the limits that depend on the tops (tops per
/// slice, popcount, probes per job), to pick the extreme slices for the sweep. One JSON line per slice.
#[test]
#[ignore = "minutes of CPU"]
fn audit_tops_scan() {
    let pips = audit_slices();
    let threads = env_u64("AUDIT_THREADS", 5) as usize;
    let out_path = std::env::var("AUDIT_OUT").unwrap_or_else(|_| "/root/audit/tops_scan.jsonl".into());
    let next = AtomicUsize::new(0);
    let lines = Mutex::new(Vec::new());
    std::thread::scope(|s| {
        for _ in 0..threads {
            s.spawn(|| {
                loop {
                    let i = next.fetch_add(1, Ordering::Relaxed);
                    if i >= pips.len() {
                        break;
                    }
                    let st = slice_tops(pips[i], &[]);
                    let mut pmin = u32::MAX;
                    let mut zero = 0;
                    let mut segmax = 0;
                    for c in 0..63u32 {
                        for d in 0..64u32 {
                            let cc = (c + d) % M;
                            let mut n = 0;
                            for &r in &ROOTS {
                                let ct = (r + M - cc) % M;
                                let s = ((d * M + ct) * 2) as usize;
                                n += st.tseg[s + 1] - st.tseg[s];
                                segmax = segmax.max(st.tseg[s + 1] - st.tseg[s]);
                            }
                            pmin = pmin.min(n);
                            zero += u32::from(n == 0);
                        }
                    }
                    lines.lock().unwrap().push(format!(
                        "{{\"pip\":{},\"tops\":{},\"maxpop\":{},\"maxprobe\":{},\"probe_min\":{pmin},\"zero_jobs\":{zero},\"segmax\":{segmax}}}",
                        st.pip,
                        st.tmask.len(),
                        st.maxpop,
                        st.maxprobe
                    ));
                }
            });
        }
    });
    let mut f = std::fs::File::create(&out_path).unwrap();
    for l in lines.into_inner().unwrap() {
        writeln!(f, "{l}").unwrap();
    }
}

/// A group of slices through the production path of `search_field` (device tops, `queue_dev`, one
/// `finish_group`): its accounts' verdict and counts.
fn group<R: Runtime>(gj: &GpuJoin<R>, pips: &[u64]) -> Result<DevCounts> {
    let rank = slice_tops(pips[0], gj.roots()).rank;
    let rankh = gj.mk(rank.to_vec());
    let cnt = gj.mk(vec![0u32; NCNT]);
    let mut tk = Vec::new();
    for &p in pips {
        gj.queue_dev(p, &rankh, &cnt, &mut tk);
    }
    gj.finish_group(&cnt, &tk)
}

/// Fault injection: each fault set of `AUDIT_FAULTS` on the slices of `AUDIT_SLICES`, as one group through the
/// production path; prints whether the accounts failed (loud) or passed, and the counts against the run without a
/// fault (a pass with other counts is a silent fault).
#[test]
#[ignore = "needs CUDA"]
fn audit_faults() {
    let pips = audit_slices();
    let faults: Vec<u32> = std::env::var("AUDIT_FAULTS")
        .unwrap_or_else(|_| "2,4,8,16,32,64,128,256,512".into())
        .split(',')
        .map(|s| s.parse().unwrap())
        .collect();
    let mut gj = GpuJoin::new(cuda_client(), Caps::b64(63)).unwrap();
    let base = group(&gj, &pips).expect("the run without a fault passes its accounts");
    println!("fault 0: accounts pass: {base:?}");
    // the nice-number buffer: whatever the faults do, nothing is reported
    for f in faults {
        gj.set_fault(f);
        let r = group(&gj, &pips);
        gj.set_fault(0);
        // a fault may leave device state behind (the stream must still be usable): a clean run after it
        let again = group(&gj, &pips);
        match r {
            Err(e) => println!("fault {f}: LOUD: {e}"),
            Ok(dc) => {
                let same = (dc.survivors, dc.checked, dc.children, dc.chunks, dc.flat)
                    == (base.survivors, base.checked, base.children, base.chunks, base.flat);
                println!(
                    "fault {f}: accounts PASS, counts {} (survivors {} vs {}, checked {} vs {}, children {} vs {}, flat {} vs {})",
                    if same { "unchanged" } else { "CHANGED: SILENT" },
                    dc.survivors,
                    base.survivors,
                    dc.checked,
                    base.checked,
                    dc.children,
                    base.children,
                    dc.flat,
                    base.flat
                );
            }
        }
        match again {
            Ok(dc) if dc.survivors == base.survivors && dc.checked == base.checked => {}
            other => println!("fault {f}: the clean run after it differs: {other:?}"),
        }
    }
}

/// `MIDOUT_STOP` (a timing switch read from the environment by `GpuJoin::new`) set to anything but 6 makes
/// `search_field` skip every account and return a field with no survivors as a success.
#[test]
#[ignore = "needs CUDA"]
fn audit_stop_env_is_silent() {
    let mut gj = GpuJoin::new(cuda_client(), Caps::b64(63)).unwrap();
    gj.stop = 2;
    let coord = Coord::for_base(64).unwrap();
    let t = 77_777u128;
    let r = search_field(
        &gj,
        &coord,
        coord.start + t * coord.quantum(),
        coord.quantum(),
        GpuOptions {
            group: 16,
            host_threads: 1,
            device_tops: true,
        },
    );
    match r {
        Ok((o, dc, _)) => println!(
            "MIDOUT_STOP=2: search_field returned Ok: survivors {} checked {} slices {} nice {:?} ({dc:?})",
            o.survivors, o.checked, o.slices, o.nice
        ),
        Err(e) => println!("MIDOUT_STOP=2: search_field failed: {e}"),
    }
}

/// The coordinate layer, base 64 and the padded base 65: the slices of all fields are a partition of the slice keys
/// (digits 4-8: each value in exactly one field t and once in it), and every n (the ends of the range, the ends of
/// the padding, random n) lies in the field its v names and in a slice of that field whose units and leads cover it.
#[test]
fn audit_coord_slices_partition() {
    for b in [64u32, 65] {
        let c = Coord::for_base(b).unwrap();
        let sh = Shape::for_coord(&c);
        let bb = u128::from(b);
        let nkeys = bb.pow(5) as usize;
        let mut seen = vec![0u64; nkeys.div_ceil(64)];
        let nt = (c.v_end() - c.start) / c.quantum();
        assert_eq!(nt, bb.pow(3));
        let mut count = 0usize;
        for t in 0..nt {
            for p in sh.slices_of(&c, t) {
                assert_eq!(p / (bb * bb), t, "b{b} slice {p} not in field {t}");
                let p = p as usize;
                assert!(p < nkeys);
                assert_eq!((seen[p / 64] >> (p % 64)) & 1, 0, "b{b} slice {p} twice");
                seen[p / 64] |= 1 << (p % 64);
                count += 1;
            }
        }
        assert_eq!(count, nkeys, "b{b}: slices of all fields");
        let mut x = 0x5EED_u64;
        let mut ns = vec![c.start, c.start + 1, c.end - 1, c.end - 2];
        for _ in 0..200_000 {
            let r = u128::from(splitmix(&mut x)) << 64 | u128::from(splitmix(&mut x));
            ns.push(c.start + r % (c.end - c.start));
        }
        let (lead_lo, lead_hi) = (c.start / bb.pow(10), (c.end - 1) / bb.pow(10));
        for n in ns {
            let v = c.v_of_n(n);
            assert_eq!(c.n_of_v(v), Some(n));
            let t = (v - c.start) / c.quantum();
            assert_eq!(c.field_digits(c.start + t * c.quantum(), c.quantum()).unwrap(), t..t + 1);
            assert_eq!((n / bb.pow(6)) % bb.pow(3), t, "b{b} n {n}: field digits");
            let pip = (n / bb.pow(4)) % bb.pow(5);
            assert!(sh.slices_of(&c, t).any(|p| p == pip), "b{b} n {n}: slice not in its field");
            // inside the slice: unit d = digit 9 < b, lead h = n div b^10 in the leads the tops enumerate
            let h = n / bb.pow(10);
            assert!(h >= lead_lo && h <= lead_hi);
            if b == 64 {
                assert!((H_LO as u128..H_HI as u128).contains(&h), "b64 n {n}: lead {h} outside the device's");
            }
        }
    }
}

/// The production path takes the parents' key from the field's first slice; the sweep runs each slice with its own
/// key. Any key must give the same survivors: per slice, the device's prefiltered list (n for n) and the whole
/// survivor set (hash, prefilter off) with its own key equal those with foreign keys (other slices', the identity
/// key 0-7, and a key of the rarest digits); and the production group path (`queue_dev` + `finish_group`, the field's
/// key, several slices in one group, the 64-slice parent level reused across them) gives the per-slice sums.
#[test]
#[ignore = "needs CUDA"]
fn audit_key_and_group_independence() {
    let pips = audit_slices();
    let client = cuda_client();
    let gj = GpuJoin::new(client.clone(), Caps::b64(63)).unwrap();
    let mut gn = GpuJoin::new(client, Caps::b64(63)).unwrap();
    gn.set_fault(F_NOPF);
    let roots = gj.roots().to_vec();
    let mut keys: Vec<[u32; 8]> = vec![[0, 1, 2, 3, 4, 5, 6, 7], [63, 62, 61, 60, 59, 58, 57, 56]];
    for &p in pips.iter().take(3) {
        keys.push(slice_tops(p, &roots).rank);
    }
    let mut bad = 0;
    let (mut sum_s, mut sum_c) = (0u64, 0u64);
    for &pip in &pips {
        let own = slice_tops(pip, &roots).rank;
        let (d0, mut l0, _) = gj.run_slice_dev(pip, &own, usize::MAX).unwrap();
        l0.sort_unstable();
        let mut h0 = SetHash::default();
        for n in gn.run_slice_dev(pip, &own, usize::MAX).unwrap().1 {
            h0.add(n);
        }
        sum_s += d0.survivors;
        sum_c += d0.checked;
        for k in &keys {
            let (d1, mut l1, _) = gj.run_slice_dev(pip, k, usize::MAX).unwrap();
            l1.sort_unstable();
            let mut h1 = SetHash::default();
            for n in gn.run_slice_dev(pip, k, usize::MAX).unwrap().1 {
                h1.add(n);
            }
            let ok = l1 == l0 && h1 == h0 && (d1.survivors, d1.checked, d1.children) == (d0.survivors, d0.checked, d0.children);
            if !ok {
                bad += 1;
            }
            println!(
                "slice {pip} key {k:?}: {} (survivors {} checked {} chunks {} kept {}; own key chunks {} kept {})",
                if ok { "equal" } else { "DIFFERS" },
                d1.survivors,
                d1.checked,
                d1.chunks,
                d1.kept,
                d0.chunks,
                d0.kept
            );
        }
    }
    for g in [pips.len(), 1.max(pips.len() / 2)] {
        let mut s = (0u64, 0u64);
        for ch in pips.chunks(g) {
            let dc = group(&gj, ch).unwrap();
            s.0 += dc.survivors;
            s.1 += dc.checked;
        }
        println!("group path, groups of {g}: survivors {} checked {} (per-slice sums {sum_s} {sum_c})", s.0, s.1);
        if s != (sum_s, sum_c) {
            bad += 1;
        }
    }
    assert_eq!(bad, 0);
}

/// A device allocation that fails (here: the card's memory filled first, `AUDIT_FILL_MB`) panics in CubeCL's stream
/// thread, not in the caller; the kernels that use the missing buffer are dropped. Does the production group path
/// notice? Prints what `GpuJoin::new` and a group of one slice return.
#[test]
#[ignore = "needs CUDA; fills the card's memory"]
fn audit_oom_is_silent() {
    let client = cuda_client();
    let fill_mb = env_u64("AUDIT_FILL_MB", 0);
    let mut hold = Vec::new();
    for _ in 0..fill_mb / 64 {
        hold.push(client.empty(64 << 20));
    }
    let _ = cubecl::future::block_on(client.sync());
    println!("filled {} MiB", 64 * hold.len());
    // AUDIT_HOLD_S: this process is only the helper that holds the memory (another process runs the join)
    let hold_s = env_u64("AUDIT_HOLD_S", 0);
    if hold_s > 0 {
        std::thread::sleep(std::time::Duration::from_secs(hold_s));
        return;
    }
    let gj = match GpuJoin::new(client, Caps::b64(63)) {
        Ok(g) => g,
        Err(e) => {
            println!("GpuJoin::new failed: {e}");
            return;
        }
    };
    println!("GpuJoin::new returned Ok");
    for pip in [712_012_851u64, 318_575_442] {
        match group(&gj, &[pip]) {
            Ok(dc) => println!("slice {pip}: group path returned Ok: {dc:?}"),
            Err(e) => println!("slice {pip}: group path failed: {e}"),
        }
    }
    let r = gj.nice();
    println!("nice(): {r:?}");
    drop(hold);
}

/// The production field path (groups of 16 slices, the field's key, the 64-slice parent level shared by consecutive
/// slices) against the same slices run one at a time (`run_slice_dev`, the same key): equal sums. The first
/// `AUDIT_NSL` (128) slices of field `AUDIT_T` (0), i.e. two 64-slice parent groups.
#[test]
#[ignore = "needs CUDA"]
fn audit_group_vs_single() {
    let t = u128::from(env_u64("AUDIT_T", 0));
    let nsl = env_u64("AUDIT_NSL", 128) as usize;
    let coord = Coord::for_base(64).unwrap();
    let sh = Shape::for_coord(&coord);
    let pips: Vec<u64> = sh.slices_of(&coord, t).take(nsl).map(|p| p as u64).collect();
    let gj = GpuJoin::new(cuda_client(), Caps::b64(63)).unwrap();
    let rank = slice_tops(pips[0], gj.roots()).rank;
    let key = |d: &DevCounts| (d.survivors, d.checked, d.children, d.chunks, d.flat, d.kept, d.tops, d.tested);
    let mut res = Vec::new();
    for round in 0..env_u64("AUDIT_ROUNDS", 1) {
        let mut single = DevCounts::default();
        let mut per = Vec::new();
        for &p in &pips {
            let (dc, _, _) = gj.run_slice_dev(p, &rank, usize::MAX).unwrap();
            per.push(dc.kept);
            single.add(&dc);
        }
        let mut grouped = DevCounts::default();
        for ch in pips.chunks(16) {
            grouped.add(&group(&gj, ch).unwrap());
        }
        println!("field {t}, {nsl} slices, round {round}: single {:?}", key(&single));
        println!("field {t}, {nsl} slices, round {round}: groups {:?}", key(&grouped));
        println!("round {round}: per-slice kept (single) {:?}", &per[..8]);
        res.push((key(&single), key(&grouped)));
    }
    // the result: survivors and checked (and the counts that do not depend on the order of work) must agree
    for (a, b) in &res {
        assert_eq!((a.0, a.1, a.2, a.3, a.4, a.6, a.7), (b.0, b.1, b.2, b.3, b.4, b.6, b.7));
    }
}

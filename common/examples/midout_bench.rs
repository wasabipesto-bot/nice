//! Whole base-64 fields of the middle-out join through the library path
//! (`midout::gpu::search_field`): tops, preparation, main kernel, survivor
//! expansion and production's full check on the device (`--host-tops`: the
//! tops on the host instead). Local only: no API, no claims, no submissions.
//! Needs the feature `midout-bench`.
//!
//! usage: midout_bench [--cuda] [--fields T0,T1,..] [--group G] [--threads N] [--classes C] [--tops-only K]
//!                     [--no-cpu-check] [--slices K] [--digits K0,K1,Q0] [--no-share-parents]
//!   --fields: values of the field's fixed digits (6-8 under 4,9,6; 5-7 under 4,8,5): field t covers v = 2^75 + t·2^57
//!   --digits: the coordinate (default the base's, `Coord::for_base`)
//!   --no-share-parents: the parents' root pass not shared across digit 8 (`GpuJoin::set_parent_sharing`, on by default)
//!   --tops-only K: time the host's tops for K slices on N threads and exit
//!   --no-cpu-check: without the sampled CPU check of one random slice per field (on by default)
//!   --slices K: only each field's first K slices (dry runs on a software device; times are then per K slices)
//!   `MIDOUT_STOP` (environment, this bench only): time the stages up to a stop (1 tops, 2 parents, 3 main
//!   kernel, 5 expansion, 6 all; 11-15 the device-top kernels), no accounts and no result
#![allow(clippy::cast_precision_loss)]

use anyhow::{Result, bail};
use nice_common::cubecl_backend::CubeclContext;
use nice_common::midout::Coord;
use nice_common::midout::gpu::{
    Caps, GpuJoin, GpuOptions, depth4_roots, search_field, search_field_part, slice_tops,
    time_field, time_field_part,
};
use std::time::Instant;

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let opt = |name: &str| {
        args.iter()
            .position(|a| a == name)
            .and_then(|i| args.get(i + 1))
            .cloned()
    };
    let threads: usize = opt("--threads").map_or(Ok(15), |s| s.parse())?;
    let group: usize = opt("--group").map_or(Ok(16), |s| s.parse())?;
    let classes: u32 = opt("--classes").map_or(Ok(63), |s| s.parse())?;
    let part: Option<usize> = opt("--slices").map(|s| s.parse()).transpose()?;
    let fields: Vec<u128> = opt("--fields")
        .unwrap_or_else(|| "77777".into())
        .split(',')
        .map(str::parse)
        .collect::<Result<_, _>>()?;
    // --digits K0,K1,Q0: a known coordinate other than the base's default (e.g. 4,9,6 or 4,8,5)
    let coord = match opt("--digits") {
        Some(d) => {
            let d: Vec<u32> = d.split(',').map(str::parse).collect::<Result<_, _>>()?;
            if d.len() != 3 {
                bail!("--digits K0,K1,Q0");
            }
            let c = Coord::with_digits(64, d[0], d[1], d[2])?;
            if !c.is_known() {
                bail!("--digits {d:?}: not a known coordinate of the base");
            }
            c
        }
        None => Coord::for_base(64)?,
    };
    eprintln!("coordinate midout:{},{},{}", coord.k0, coord.k1, coord.q0);
    if let Some(k) = opt("--tops-only") {
        let k: u64 = k.parse()?;
        let roots = depth4_roots();
        let t0 = Instant::now();
        let next = std::sync::atomic::AtomicU64::new(0);
        let (mut tops, mut maxpop, mut maxprobe) = (0usize, 0u32, 0u32);
        let res: Vec<(usize, u32, u32)> = std::thread::scope(|s| {
            let hs: Vec<_> = (0..threads)
                .map(|_| {
                    s.spawn(|| {
                        let mut acc = (0usize, 0u32, 0u32);
                        loop {
                            let i = next.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                            if i >= k {
                                break;
                            }
                            let pip = (fields[0] << 12 | u128::from(i)) as u64;
                            let st = slice_tops(pip, &roots);
                            if st.maxprobe > nice_common::midout::gpu::PMAX {
                                println!("slice {pip}: a job of {} probes", st.maxprobe);
                            }
                            acc.0 += st.tmask.len();
                            acc.1 = acc.1.max(st.maxpop);
                            acc.2 = acc.2.max(st.maxprobe);
                        }
                        acc
                    })
                })
                .collect();
            hs.into_iter().map(|h| h.join().unwrap()).collect()
        });
        for (a, b, c) in res {
            tops += a;
            maxpop = maxpop.max(b);
            maxprobe = maxprobe.max(c);
        }
        let el = t0.elapsed().as_secs_f64();
        println!(
            "TOPS-ONLY {k} slices on {threads} threads: {el:.2} s, {:.3} ms per slice; tops {tops} ({:.0} per slice), max popcount {maxpop}, max probes per job {maxprobe}",
            el / k as f64 * 1e3,
            tops as f64 / k as f64
        );
        return Ok(());
    }
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
    let name = ctx.device_name();
    macro_rules! go {
        ($client:expr) => {{
            let mut gj = GpuJoin::new($client, Caps::b64(classes))?;
            let stop: Option<u32> = std::env::var("MIDOUT_STOP").ok().map(|x| x.parse()).transpose()?;
            if let Some(s) = stop {
                gj.set_timing_stop(s);
            }
            let cpu_check = !args.iter().any(|a| a == "--no-cpu-check");
            let share = !args.iter().any(|a| a == "--no-share-parents");
            gj.set_parent_sharing(share);
            println!("device {name}; W {}; group {group}; host threads {threads}; classes per batch {classes}; cpu check {cpu_check}; timing stop {stop:?}; slices per field {part:?}; parent sharing {share}", gj.w);
            let q = coord.quantum();
            let (mut wall, mut adm_all) = (0f64, 0f64);
            for &t in &fields {
                let vs = coord.start + t * q;
                let ncount = coord.n_count(vs, q)?;
                // a part of the field: its share of the admissible n (4,096 slices per field)
                let adm = ncount as f64 * 8.0 / 63.0 * part.map_or(1.0, |k| k.min(4096) as f64 / 4096.0);
                let go = if args.iter().any(|a| a == "--host-tops") {
                    GpuOptions::new(group, cpu_check).with_host_tops(threads)
                } else {
                    GpuOptions::new(group, cpu_check)
                };
                if let Some(s) = stop {
                    let tm = match part {
                        Some(k) => time_field_part(&gj, &coord, vs, q, go, k)?,
                        None => time_field(&gj, &coord, vs, q, go)?,
                    };
                    wall += tm.wall;
                    adm_all += adm;
                    println!("FIELD t {t} timing stop {s}: {:.2} s = {:.4} fs per admissible n (no accounts, no result)", tm.wall, tm.wall / adm * 1e15);
                    continue;
                }
                let (o, dc, tm) = match part {
                    Some(k) => search_field_part(&gj, &coord, vs, q, go, k)?,
                    None => search_field(&gj, &coord, vs, q, go)?,
                };
                wall += tm.wall;
                adm_all += adm;
                println!(
                    "FIELD t {t} v [{vs}, +{q}) n {ncount}: {:.2} s = {:.4} fs per admissible n | slices {} survivors {} checked {} nice {:?} | tops {} tested {} children {} chunks {} flat {} kept {} | host wait {:.2} s, sync+reads {:.2} s",
                    tm.wall,
                    tm.wall / adm * 1e15,
                    o.slices,
                    o.survivors,
                    o.checked,
                    o.nice,
                    dc.tops,
                    dc.tested,
                    dc.children,
                    dc.chunks,
                    dc.flat,
                    dc.kept,
                    tm.host_wait,
                    tm.sync
                );
                if share {
                    let (nl, listed) = gj.parent_sharing_last();
                    println!("SHARE t {t}: {nl} depth-8 lists, {listed} roots listed");
                }
                if let Some(p) = tm.sampled {
                    println!(
                        "SAMPLE t {t} slice {p}: equal; field {:.2} s, CPU thread {:.2} s, waited {:.2} s for it, device rerun {:.3} s",
                        tm.field, tm.cpu_check, tm.cpu_wait, tm.sample_dev
                    );
                }
            }
            println!(
                "TOTAL {} fields: {wall:.2} s, {:.4} fs per admissible n",
                fields.len(),
                wall / adm_all * 1e15
            );
        }};
    }
    match &ctx {
        CubeclContext::Wgpu { client, .. } => go!(client.clone()),
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => go!(client.clone()),
        #[allow(unreachable_patterns)]
        _ => bail!("unsupported runtime"),
    }
    Ok(())
}

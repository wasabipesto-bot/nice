//! Whole base-64 fields of the middle-out join through the library path
//! (`midout::gpu::search_field`): tops on the host, preparation, main kernel,
//! survivor expansion and production's full check on the device. Local only:
//! no API, no claims, no submissions.
//!
//! usage: midout_bench [--cuda] [--fields T0,T1,..] [--group G] [--threads N] [--classes C] [--tops-only K]
//!                     [--no-cpu-check]
//!   --fields: values of digits 6-8 (field t covers v = 2^75 + t·2^57, 2^57 of them)
//!   --tops-only K: time the host's tops for K slices on N threads and exit
//!   --no-cpu-check: without the sampled CPU check of one random slice per field (on by default)
//!   `MIDOUT_STOP` (environment, this bench only): time the stages up to a stop (1 tops, 2 parents, 3 main
//!   kernel, 5 expansion, 6 all; 11-15 the device-top kernels), no accounts and no result
#![allow(clippy::cast_precision_loss)]

use anyhow::{Result, bail};
use nice_common::cubecl_backend::CubeclContext;
use nice_common::midout::Coord;
use nice_common::midout::gpu::{
    Caps, GpuJoin, GpuOptions, depth4_roots, search_field, slice_tops, time_field,
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
    let fields: Vec<u128> = opt("--fields")
        .unwrap_or_else(|| "77777".into())
        .split(',')
        .map(str::parse)
        .collect::<Result<_, _>>()?;
    let coord = Coord::for_base(64)?;
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
            println!("device {name}; W {}; group {group}; host threads {threads}; classes per batch {classes}; cpu check {cpu_check}; timing stop {stop:?}", gj.w);
            let q = coord.quantum();
            let (mut wall, mut adm_all) = (0f64, 0f64);
            for &t in &fields {
                let vs = coord.start + t * q;
                let ncount = coord.n_count(vs, q)?;
                let adm = ncount as f64 * 8.0 / 63.0;
                let go = GpuOptions { group, host_threads: threads, device_tops: !args.iter().any(|a| a == "--host-tops"), cpu_check };
                if let Some(s) = stop {
                    let tm = time_field(&gj, &coord, vs, q, go)?;
                    wall += tm.wall;
                    adm_all += adm;
                    println!("FIELD t {t} timing stop {s}: {:.2} s = {:.4} fs per admissible n (no accounts, no result)", tm.wall, tm.wall / adm * 1e15);
                    continue;
                }
                let (o, dc, tm) = search_field(&gj, &coord, vs, q, go)?;
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

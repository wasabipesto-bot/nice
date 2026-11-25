//! **midout_bench**: time whole base-64 fields of the middle-out join on one
//! device, through the path a client takes (`midout::gpu::search_field`:
//! tops, preparation, main kernel, survivor expansion and production's full
//! check on the device, every account checked, and by default the sampled
//! CPU check of one random slice per field). Local only: no API, no claims,
//! no submissions. For bases 65-70 (the wide path) see `midout_wide_bench`;
//! for a work list for the development server, `midout_fields`.
//!
//! Run it (release, feature `midout-bench`; add `cubecl-cuda` and `--cuda`
//! for the CUDA runtime, or `cubecl-spirv` for Vulkan's SPIR-V compiler):
//!
//! ```text
//! cargo run --release -p nice_common --features cubecl-cuda,midout-bench \
//!     --example midout_bench -- --cuda --fields 77777,12345
//! ```
//!
//! **Output.** One `FIELD` line per field: its wall time and that time in
//! **fs per admissible n** (femtoseconds of wall time per number of the field
//! that could be nice: a nice number lies in one of the residue classes
//! `r mod (b − 1)` with `r² + r³ ≡ b(b − 1)/2`, `midout::arith::roots`, which
//! at base 64 are 8 of the 63, so a field of 2^57 n holds 2^57 · 8/63
//! admissible n); then its counters (slices, survivors, checked, nice
//! numbers; device counts), `SHARE` (parent sharing) and `SAMPLE` (the
//! sampled check) lines, and a `TOTAL`. With `--slices K` the times are of
//! the first K slices and the admissible n are that share of the field's.
//!
//! **Timing stops** (`MIDOUT_STOP`, environment, this bench only): queue
//! the stages up to a stop and time them, with no accounts and no result:
//! 1 tops, 2 parents, 3 main kernel, 5 expansion, 6 all; 11-15 the
//! device-top kernels. `--tops-only K` times the host's tops for the first
//! K slices of the first field on `--threads` threads and exits.
#![allow(clippy::cast_precision_loss)]

#[path = "support/args.rs"]
mod args;

use anyhow::{Result, bail, ensure};
use args::Opt;
use nice_common::cubecl_backend::CubeclContext;
use nice_common::midout::gpu::{
    Caps, GpuJoin, GpuOptions, depth4_roots, search_field, search_field_part, slice_tops,
    time_field, time_field_part,
};
use nice_common::midout::{Coord, Shape};
use std::time::Instant;

const ABOUT: &str = "Time whole base-64 fields of the middle-out join on one device (no API). Reports \
fs per admissible n: femtoseconds of wall time per n of the field in a residue class mod 63 a nice number \
can be in (8 of 63 at base 64).";

const OPTS: &[Opt] = &[
    Opt {
        name: "--cuda",
        value: None,
        help: "the CubeCL CUDA runtime (feature cubecl-cuda); default: wgpu",
    },
    Opt {
        name: "--fields",
        value: Some("T0,T1,.."),
        help: "fields by their fixed digits t (5-7 under 4,8,5; 6-8 under 4,9,6): v = 2^75 + t*2^57 (default 77777)",
    },
    Opt {
        name: "--digits",
        value: Some("K0,K1,Q0"),
        help: "a known coordinate of base 64 other than its default 4,8,5 (e.g. 4,9,6)",
    },
    Opt {
        name: "--group",
        value: Some("G"),
        help: "slices per synchronisation (default 16, the client's)",
    },
    Opt {
        name: "--classes",
        value: Some("C"),
        help: "residue classes per batch, 1-63 (default 63; 4 on lavapipe)",
    },
    Opt {
        name: "--slices",
        value: Some("K"),
        help: "only each field's first K slices (dry runs on a software device)",
    },
    Opt {
        name: "--no-cpu-check",
        value: None,
        help: "without the sampled CPU check (on by default, as in the client)",
    },
    Opt {
        name: "--cpu-threads",
        value: Some("N"),
        help: "the sampled check's CPU threads (default: gpu::sample_threads)",
    },
    Opt {
        name: "--no-share-parents",
        value: None,
        help: "do not share the parents' root pass across digit 8 (on by default)",
    },
    Opt {
        name: "--host-tops",
        value: None,
        help: "make the slices' tops on the host (on --threads threads), not on the device",
    },
    Opt {
        name: "--threads",
        value: Some("N"),
        help: "host threads for --host-tops and --tops-only (default 15)",
    },
    Opt {
        name: "--tops-only",
        value: Some("K"),
        help: "time the host's tops for the first field's first K slices and exit",
    },
];

/// The timing stops `MIDOUT_STOP` may name.
const STOPS: &[u32] = &[1, 2, 3, 5, 6, 11, 12, 13, 14, 15];

fn main() -> Result<()> {
    let a = args::parse("midout_bench", ABOUT, OPTS)?;
    let flag = |name: &str| a.flag(name);
    let threads: usize = a.get("--threads", 15)?;
    let group: usize = a.get("--group", 16)?;
    let classes: u32 = a.get("--classes", 63)?;
    let part: Option<usize> = a.opt("--slices")?;
    let cpu_threads: usize = a.get("--cpu-threads", 0)?;
    let fields: Vec<u128> = a.list("--fields")?.unwrap_or_else(|| vec![77777]);
    ensure!(threads >= 1, "--threads must be at least 1");
    ensure!(group >= 1, "--group must be at least 1");
    ensure!(
        (1..=63).contains(&classes),
        "--classes must be 1-63 (the residue classes mod 63)"
    );
    ensure!(part != Some(0), "--slices must be at least 1");
    let stop: Option<u32> = match std::env::var("MIDOUT_STOP") {
        Ok(x) => {
            let s: u32 = x
                .parse()
                .map_err(|_| anyhow::anyhow!("MIDOUT_STOP={x}: not a number"))?;
            ensure!(STOPS.contains(&s), "MIDOUT_STOP={s}: one of {STOPS:?}");
            Some(s)
        }
        Err(_) => None,
    };
    let coord = match args::digits(&a)? {
        Some((k0, k1, q0)) => {
            let c = Coord::with_digits(64, k0, k1, q0)?;
            if !c.is_known() {
                bail!(
                    "--digits {k0},{k1},{q0}: not a known coordinate of base 64 (4,8,5 or 4,9,6)"
                );
            }
            c
        }
        None => Coord::for_base(64)?,
    };
    let quanta = (coord.v_end() - coord.start()) / coord.quantum();
    if let Some(t) = fields.iter().find(|&&t| t >= quanta) {
        bail!(
            "--fields: t {t} is past the base's last field ({})",
            quanta - 1
        );
    }
    let sh = Shape::for_coord(&coord);
    // the admissible share of n: the residue classes mod 63 a nice number can be in
    let admissible = nice_common::midout::arith::roots(64).len() as f64 / 63.0;
    eprintln!(
        "coordinate midout:{},{},{}",
        coord.k0(),
        coord.k1(),
        coord.q0()
    );
    if let Some(k) = a.opt::<u64>("--tops-only")? {
        // the first field's slices in the coordinate's own order
        let pips: Vec<u64> = sh
            .slices_of(&coord, fields[0])
            .take(usize::try_from(k)?)
            .map(|p| u64::try_from(p).expect("a base-64 slice fits 64 bits"))
            .collect();
        let k = pips.len() as u64;
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
                            let pip = pips[usize::try_from(i).expect("below k")];
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
    let ctx = if flag("--cuda") {
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
            if let Some(s) = stop {
                gj.set_timing_stop(s);
            }
            let cpu_check = !flag("--no-cpu-check");
            let share = !flag("--no-share-parents");
            gj.set_parent_sharing(share);
            println!("device {name}; W {}; group {group}; host threads {threads}; classes per batch {classes}; cpu check {cpu_check} ({} threads); timing stop {stop:?}; slices per field {part:?}; parent sharing {share}", gj.w, nice_common::midout::gpu::sample_threads(cpu_threads));
            let q = coord.quantum();
            let (mut wall, mut adm_all) = (0f64, 0f64);
            for &t in &fields {
                let vs = coord.start() + t * q;
                let ncount = coord.n_count(vs, q)?;
                // a part of the field: its share of the admissible n (4,096 slices per field)
                let per_field = sh.slices_of(&coord, t).count();
                let adm = ncount as f64 * admissible * part.map_or(1.0, |k| k.min(per_field) as f64 / per_field as f64);
                let go = if flag("--host-tops") {
                    GpuOptions::new(group, cpu_check).with_cpu_threads(cpu_threads).with_host_tops(threads)
                } else {
                    GpuOptions::new(group, cpu_check).with_cpu_threads(cpu_threads)
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

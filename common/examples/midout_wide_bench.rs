//! **midout_wide_bench**: time whole fields of the middle-out join on the
//! wide device path (`midout::gpu_wide::search_field_wide`: two-word masks,
//! bases 64-70; tops, preparation, main kernel, expansion and the wide full
//! check on the device, every account checked), and with `--narrow` (base 64
//! only) the same fields also through the 64-bit path
//! (`midout::gpu::search_field`), alternating, in the same process. Local
//! only: no API, no claims, no submissions. For the base-64 path alone, with
//! its own switches, see `midout_bench`.
//!
//! Run it (release, feature `midout-bench`; add `cubecl-cuda` and `--cuda`
//! for the CUDA runtime):
//!
//! ```text
//! cargo run --release -p nice_common --features cubecl-cuda,midout-bench \
//!     --example midout_wide_bench -- --cuda --base 65 --fields 77777
//! ```
//!
//! **Output.** One `WIDE` (and with `--narrow`, `NARROW`) line per field: its
//! wall time and that time in **fs per admissible n** (femtoseconds of wall
//! time per number of the field that could be nice: one in a residue class
//! `r mod (b − 1)` with `r² + r³ ≡ b(b − 1)/2`, `midout::arith::roots`), then
//! its counters (slices, survivors, checked, nice numbers; device counts),
//! and a `TOTAL` per path. The sampled CPU check is off unless
//! `--cpu-check` is given (unlike `midout_bench` and the client, where it is
//! on).
//!
//! **Timing stops** (`MIDOUT_STOP`, environment, this bench only): time the
//! wide path's stages up to a stop, with no accounts and no result: 1 tops,
//! 2 parents, 3 main kernel, 5 expansion, 6 all.
#![allow(clippy::cast_precision_loss)]

#[path = "support/args.rs"]
mod args;

use anyhow::{Result, bail, ensure};
use args::Opt;
use nice_common::cubecl_backend::CubeclContext;
use nice_common::midout::gpu::{Caps, GpuJoin, GpuOptions, search_field};
use nice_common::midout::gpu_wide::{
    WideCaps, WideJoin, WideOptions, search_field_wide, time_field_wide,
};
use nice_common::midout::{Coord, Shape};

const ABOUT: &str = "Time whole middle-out fields of bases 64-70 on the wide device path (no API). Reports \
fs per admissible n: femtoseconds of wall time per n of the field in a residue class mod b-1 a nice number \
can be in.";

const OPTS: &[Opt] = &[
    Opt {
        name: "--cuda",
        value: None,
        help: "the CubeCL CUDA runtime (feature cubecl-cuda); default: wgpu",
    },
    Opt {
        name: "--base",
        value: Some("B"),
        help: "the base, 64-70 with a coordinate (default 65)",
    },
    Opt {
        name: "--fields",
        value: Some("T0,T1,.."),
        help: "fields by their fixed digits t (5-7 under 4,8,5; 6-8 under 4,9,6): v = start + t*quantum (default 77777)",
    },
    Opt {
        name: "--digits",
        value: Some("K0,K1,Q0"),
        help: "a known coordinate of the base other than its default (e.g. 4,9,6)",
    },
    Opt {
        name: "--group",
        value: Some("G"),
        help: "slices per synchronisation (default 16, the client's)",
    },
    Opt {
        name: "--classes",
        value: Some("C"),
        help: "residue classes per batch (default: WideCaps::for_base)",
    },
    Opt {
        name: "--maxpop",
        value: Some("P"),
        help: "the wide path's top-popcount cap (default: WideCaps::for_base)",
    },
    Opt {
        name: "--ninst",
        value: Some("I"),
        help: "the wide path's instance cap (default: WideCaps::for_base)",
    },
    Opt {
        name: "--narrow",
        value: None,
        help: "base 64: also each field through the 64-bit path, alternating",
    },
    Opt {
        name: "--narrow-only",
        value: None,
        help: "base 64: only the 64-bit path",
    },
    Opt {
        name: "--no-share-parents",
        value: None,
        help: "do not share the parents' root pass across the slice's top digit (on by default)",
    },
    Opt {
        name: "--pf-digits",
        value: None,
        help: "the expansion's prefilter digit by digit (pf_w, the earlier form), not in base b^2",
    },
    Opt {
        name: "--cpu-check",
        value: None,
        help: "the sampled CPU check of one random slice per field (off by default here)",
    },
    Opt {
        name: "--cpu-threads",
        value: Some("N"),
        help: "the sampled check's CPU threads (default: gpu::sample_threads)",
    },
];

/// The timing stops `MIDOUT_STOP` may name.
const STOPS: &[u32] = &[1, 2, 3, 5, 6];

fn main() -> Result<()> {
    let a = args::parse("midout_wide_bench", ABOUT, OPTS)?;
    let flag = |name: &str| a.flag(name);
    let b: u32 = a.get("--base", 65)?;
    let group: usize = a.get("--group", 16)?;
    let cpu_threads: usize = a.get("--cpu-threads", 0)?;
    let fields: Vec<u128> = a.list("--fields")?.unwrap_or_else(|| vec![77777]);
    ensure!(
        (64..=70).contains(&b),
        "--base {b}: the wide path searches bases 64-70"
    );
    ensure!(group >= 1, "--group must be at least 1");
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
            let c = Coord::with_digits(b, k0, k1, q0)?;
            if !c.is_known() {
                bail!("--digits {k0},{k1},{q0}: not a known coordinate of base {b}");
            }
            c
        }
        None => Coord::for_base(b)?,
    };
    let quanta = (coord.v_end() - coord.start()) / coord.quantum();
    if let Some(t) = fields.iter().find(|&&t| t >= quanta) {
        bail!(
            "--fields: t {t} is past the base's last field ({})",
            quanta - 1
        );
    }
    eprintln!(
        "coordinate midout:{},{},{}",
        coord.k0(),
        coord.k1(),
        coord.q0()
    );
    let sh = Shape::for_coord(&coord);
    let mut caps = WideCaps::for_base(b);
    if let Some(c) = a.opt("--classes")? {
        ensure!(
            c >= 1 && c < b,
            "--classes must be 1-{} (the residue classes mod {})",
            b - 1,
            b - 1
        );
        caps.classes = c;
    }
    if let Some(p) = a.opt("--maxpop")? {
        caps.maxpop = p;
    }
    if let Some(i) = a.opt("--ninst")? {
        caps.ninst = i;
    }
    let narrow = flag("--narrow") || flag("--narrow-only");
    if narrow && b != 64 {
        bail!("--narrow needs --base 64");
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
    let roots = nice_common::midout::arith::roots(b).len() as f64;
    macro_rules! go {
        ($client:expr) => {{
            let wide = if flag("--narrow-only") {
                None
            } else {
                let mut g = WideJoin::new($client, caps, &coord, sh)?;
                // timing only: the bench reads MIDOUT_STOP (the library never does) and times the stages up to it
                if let Some(st) = stop {
                    g.set_timing_stop(st);
                }
                // --pf-digits: the prefilter digit by digit (the earlier form), for A/B timing
                g.set_prefilter_b2(!flag("--pf-digits"));
                println!("prefilter {}", if flag("--pf-digits") { "digits (pf_w)" } else { "base b^2 (pf_w2)" });
                g.set_parent_sharing(!flag("--no-share-parents"));
                println!("parent sharing {}", !flag("--no-share-parents"));
                Some(g)
            };
            let nj = if narrow { Some(GpuJoin::new($client, Caps::b64(63))?) } else { None };
            println!(
                "device {name}; base {b} shape ({}, {}); group {group}; wide caps {caps:?}; wide W {:?}; narrow {}",
                sh.f0,
                sh.k,
                wide.as_ref().map(|g| g.w),
                narrow
            );
            let q = coord.quantum();
            let (mut wall_w, mut wall_n, mut adm_all) = (0f64, 0f64, 0f64);
            for &t in &fields {
                let vs = coord.start() + t * q;
                let ncount = coord.n_count(vs, q)?;
                let adm = ncount as f64 * roots / f64::from(b - 1);
                adm_all += adm;
                if let Some(gj) = &wide {
                    if gj.stop_set() {
                        let tm = time_field_wide(gj, &coord, vs, q, group)?;
                        wall_w += tm.wall;
                        println!("WIDE b{b} t {t} TIMING STOP: {:.2} s = {:.4} fs per admissible n", tm.wall, tm.wall / adm * 1e15);
                        continue;
                    }
                    let (o, dc, tm) = search_field_wide(gj, &coord, vs, q, WideOptions { group, cpu_check: flag("--cpu-check"), cpu_threads })?;
                    wall_w += tm.wall;
                    if let Some(p) = tm.sampled {
                        println!("WIDE b{b} t {t} sampled CPU check: slice {p} equal (cpu {:.1} s, host waited {:.1} s, device rerun {:.2} s; field alone {:.2} s)", tm.cpu_check, tm.cpu_wait, tm.sample_dev, tm.field);
                    }
                    println!(
                        "WIDE b{b} t {t} v [{vs}, +{q}) n {ncount}: {:.2} s = {:.4} fs per admissible n | slices {} survivors {} checked {} nice {:?} | tops {} children {} chunks {} flat {} kept {} | key {:.2} s, sync+reads {:.2} s",
                        tm.wall,
                        tm.wall / adm * 1e15,
                        o.slices,
                        o.survivors,
                        o.checked,
                        o.nice,
                        dc.tops,
                        dc.children,
                        dc.chunks,
                        dc.flat,
                        dc.kept,
                        tm.host_wait,
                        tm.sync
                    );
                    let (nl, listed) = gj.parent_sharing_last();
                    println!("WIDE SHARE t {t}: {nl} shared lists, {listed} roots listed");
                }
                if let Some(gn) = &nj {
                    let (o, dc, tm) = search_field(gn, &coord, vs, q, GpuOptions::new(group, flag("--cpu-check")).with_cpu_threads(cpu_threads))?;
                    wall_n += tm.wall;
                    println!(
                        "NARROW b{b} t {t} v [{vs}, +{q}) n {ncount}: {:.2} s = {:.4} fs per admissible n | slices {} survivors {} checked {} nice {:?} | tops {} children {} chunks {} flat {} kept {}",
                        tm.wall,
                        tm.wall / adm * 1e15,
                        o.slices,
                        o.survivors,
                        o.checked,
                        o.nice,
                        dc.tops,
                        dc.children,
                        dc.chunks,
                        dc.flat,
                        dc.kept
                    );
                }
            }
            if wide.is_some() {
                println!("TOTAL WIDE b{b} {} fields: {wall_w:.2} s, {:.4} fs per admissible n", fields.len(), wall_w / adm_all * 1e15);
            }
            if narrow {
                println!("TOTAL NARROW b{b} {} fields: {wall_n:.2} s, {:.4} fs per admissible n", fields.len(), wall_n / adm_all * 1e15);
            }
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

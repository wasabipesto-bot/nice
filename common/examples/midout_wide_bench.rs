//! Whole fields of the middle-out join through the wide device path
//! (`midout::gpu_wide::search_field_wide`): tops, preparation, main kernel,
//! expansion and the wide full check on the device. With `--narrow` (base
//! 64 only), the same fields also through the 64-bit path
//! (`midout::gpu::search_field`), alternating, in the same process. Local
//! only: no API, no claims, no submissions.
//!
//! usage: midout_wide_bench [--cuda] [--base B] [--fields T0,T1,..] [--group G] [--classes C]
//!                          [--maxpop P] [--ninst I] [--narrow] [--narrow-only]
//!   --fields: values of the field's fixed digits 6-8 (field t covers v = start + t·quantum)
#![allow(clippy::cast_precision_loss)]

use anyhow::{Result, bail};
use nice_common::cubecl_backend::CubeclContext;
use nice_common::midout::gpu::{Caps, GpuJoin, GpuOptions, search_field};
use nice_common::midout::gpu_wide::{WideCaps, WideJoin, search_field_wide};
use nice_common::midout::{Coord, Shape};

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let opt = |name: &str| {
        args.iter()
            .position(|a| a == name)
            .and_then(|i| args.get(i + 1))
            .cloned()
    };
    let flag = |name: &str| args.iter().any(|a| a == name);
    let b: u32 = opt("--base").map_or(Ok(65), |s| s.parse())?;
    let group: usize = opt("--group").map_or(Ok(16), |s| s.parse())?;
    let fields: Vec<u128> = opt("--fields")
        .unwrap_or_else(|| "77777".into())
        .split(',')
        .map(str::parse)
        .collect::<Result<_, _>>()?;
    let coord = Coord::for_base(b)?;
    let sh = Shape::for_coord(&coord);
    let mut caps = WideCaps::for_base(b);
    if let Some(c) = opt("--classes") {
        caps.classes = c.parse()?;
    }
    if let Some(p) = opt("--maxpop") {
        caps.maxpop = p.parse()?;
    }
    if let Some(i) = opt("--ninst") {
        caps.ninst = i.parse()?;
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
                Some(WideJoin::new($client, caps, &coord, sh)?)
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
                let vs = coord.start + t * q;
                let ncount = coord.n_count(vs, q)?;
                let adm = ncount as f64 * roots / f64::from(b - 1);
                adm_all += adm;
                if let Some(gj) = &wide {
                    let (o, dc, tm) = search_field_wide(gj, &coord, vs, q, group)?;
                    wall_w += tm.wall;
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
                }
                if let Some(gn) = &nj {
                    let (o, dc, tm) = search_field(gn, &coord, vs, q, GpuOptions { group, host_threads: 1, device_tops: true, cpu_check: flag("--cpu-check") })?;
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

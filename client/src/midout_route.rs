//! The middle-out route (development, off by default): claim fields of the
//! middle-out coordinate from a local coordinator, search them with
//! `nice_common::midout::route`, submit. Reached only through
//! `--midout-coordinator URL`; nothing else in the client calls it.
//!
//! Guards (each refuses with a reason and a non-zero exit, and submits
//! nothing for the field at hand):
//! - the coordinator's address is explicit and is not the production API
//!   (`midout::wire::check_coordinator_url`);
//! - a claim must name a middle-out coordinate this build knows
//!   (`"coordinate": "midout:K0,K1,Q0"`, the base's `Coord::for_base`), of a
//!   base with a device path, whole quanta, with the `range_size` the
//!   coordinate gives;
//! - a field whose accounts fail or whose sampled CPU check differs is not
//!   submitted (the library returns an error);
//! - a panic on any thread of the process (the GPU runtime's stream thread
//!   above all: CubeCL panics there on a failed allocation and the caller
//!   sees nothing) is recorded by a panic hook; after one, nothing more is
//!   submitted.

use crate::Cli;
use anyhow::{Context, Result, anyhow, bail, ensure};
use log::{error, info, warn};
use nice_common::client_api_async::{Client, submit_field_to_server_async};
use nice_common::midout::Coord;
use nice_common::midout::wire::{self, CoordClaim};
use nice_common::{BUILD_SHA, CLIENT_VERSION, DataToServer, NiceNumberSimple};
use serde_json::{Value, json};
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Instant;

static PANICKED: AtomicBool = AtomicBool::new(false);
static PANICS: Mutex<Vec<String>> = Mutex::new(Vec::new());

/// Record every panic of the process (then run the previous hook, which
/// prints it). Installed once by the route; the default client never
/// installs it.
fn install_panic_hook() {
    let previous = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        PANICKED.store(true, Ordering::SeqCst);
        let thread = std::thread::current();
        let line = format!("thread '{}': {info}", thread.name().unwrap_or("<unnamed>"));
        if let Ok(mut v) = PANICS.lock() {
            v.push(line);
        }
        previous(info);
    }));
}

/// The panics recorded so far, or `Ok` if none.
fn no_panic_so_far() -> Result<()> {
    if PANICKED.load(Ordering::SeqCst) {
        let v = PANICS.lock().map(|v| v.join("; ")).unwrap_or_default();
        bail!("middle-out: a thread of this process panicked ({v}): nothing more is submitted");
    }
    Ok(())
}

/// Claim one field: `None` when the coordinator has none left (204).
async fn claim(client: &Client, url: &str) -> Result<Option<CoordClaim>> {
    let full = format!("{}{}", url.trim_end_matches('/'), wire::CLAIM_PATH);
    let r = client
        .get(&full)
        .send()
        .await
        .with_context(|| format!("middle-out: claim from {full}"))?;
    let status = r.status();
    if status.as_u16() == 204 {
        return Ok(None);
    }
    let body = r.bytes().await?;
    ensure!(
        status.is_success(),
        "middle-out: claim refused by the coordinator: {status} {}",
        String::from_utf8_lossy(&body)
    );
    let c: CoordClaim = serde_json::from_slice(&body).with_context(|| {
        format!(
            "middle-out: not a middle-out claim: {}",
            String::from_utf8_lossy(&body)
        )
    })?;
    Ok(Some(c))
}

/// The claim's field `(coord, v_start, v_size)`, after every check a claim
/// must pass before any work starts.
fn field_of(c: &CoordClaim) -> Result<(Coord, u128, u128)> {
    // the claim names its coordinate; build it from the claim, then refuse it
    // unless it is the one this build's device path for the base searches
    let (k0, k1, q0) = wire::parse_coordinate_id(&c.coordinate)
        .with_context(|| format!("middle-out: claim {}", c.claim_id))?;
    ensure!(
        (64..=70).contains(&c.base),
        "middle-out: claim {}: base {} has no device path",
        c.claim_id,
        c.base
    );
    let coord = Coord::with_digits(c.base, k0, k1, q0)?;
    let known = Coord::for_base(c.base)?;
    ensure!(
        coord == known,
        "middle-out: claim {}: coordinate '{}' of base {} is not one this client knows (it searches '{}')",
        c.claim_id,
        c.coordinate,
        c.base,
        wire::coordinate_id(known.k0, known.k1, known.q0)
    );
    let v_size = c
        .range_end
        .checked_sub(c.range_start)
        .ok_or_else(|| anyhow!("middle-out: claim {}: range_end < range_start", c.claim_id))?;
    coord.field_digits(c.range_start, v_size)?;
    let n = coord.n_count(c.range_start, v_size)?;
    ensure!(
        n == c.range_size,
        "middle-out: claim {}: range_size {} but the field holds {n} n",
        c.claim_id,
        c.range_size
    );
    Ok((coord, c.range_start, v_size))
}

/// The test switch (`midout-fault` builds only): `NICE_MIDOUT_FAULT` =
/// `accounts` | `sample` (library fault bits) | `panic` (a thread of this
/// process panics during the field).
fn fault_switch() -> Option<String> {
    if cfg!(feature = "midout-fault") {
        std::env::var("NICE_MIDOUT_FAULT")
            .ok()
            .filter(|s| !s.is_empty())
    } else {
        None
    }
}

/// Run the route until the coordinator has no field left (with `--repeat`)
/// or after one field.
///
/// # Errors
/// Any guard (above), a claim or submission failure, or a device error: the
/// client exits non-zero with the reason.
pub async fn run(cli: &Cli, url: &str) -> Result<()> {
    wire::check_coordinator_url(url)?;
    if cli.validate || cli.benchmark {
        bail!("middle-out: --midout-coordinator cannot be combined with --validate or --benchmark");
    }
    let url = url.to_string();
    let cli = cli.clone();
    tokio::task::spawn_blocking(move || run_blocking(&cli, &url))
        .await
        .map_err(|e| anyhow!("middle-out: the route's thread ended: {e}"))?
}

#[cfg(feature = "cubecl")]
fn run_blocking(cli: &Cli, url: &str) -> Result<()> {
    use nice_common::cubecl_backend::CubeclContext;
    let ctx = match cli.gpu_backend {
        #[cfg(feature = "cubecl-cuda")]
        crate::GpuBackend::Auto | crate::GpuBackend::CubeclCuda => {
            CubeclContext::new_cuda(cli.gpu_device)?
        }
        crate::GpuBackend::Cubecl => CubeclContext::new_default()?,
        #[cfg(not(feature = "cubecl-cuda"))]
        crate::GpuBackend::Auto => CubeclContext::new_default()?,
        other => bail!("middle-out: backend {other:?} has no middle-out path"),
    };
    let device = ctx.device_name();
    install_panic_hook();
    info!("middle-out route: coordinator {url}, device {device}");
    match &ctx {
        CubeclContext::Wgpu { client, .. } => drive(cli, url, &device, client),
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => drive(cli, url, &device, client),
        #[allow(unreachable_patterns)]
        _ => bail!("middle-out: unsupported runtime"),
    }
}

#[cfg(not(feature = "cubecl"))]
fn run_blocking(_cli: &Cli, _url: &str) -> Result<()> {
    bail!("middle-out: this build carries no CubeCL backend (build with --features cubecl-cuda)")
}

#[cfg(feature = "cubecl")]
fn drive<R: nice_common::midout::route::DeviceRuntime>(
    cli: &Cli,
    url: &str,
    device: &str,
    client: &nice_common::midout::route::Client<R>,
) -> Result<()> {
    use nice_common::midout::route::FieldJoin;
    let rt = tokio::runtime::Handle::current();
    let http = Client::builder()
        .timeout(std::time::Duration::from_secs(
            nice_common::CLIENT_REQUEST_TIMEOUT_SECS,
        ))
        .build()?;
    let fault = fault_switch();
    if let Some(f) = &fault {
        warn!("middle-out: TEST FAULT '{f}' is on");
    }
    let mut join: Option<FieldJoin<R>> = None;
    let mut done = 0u64;
    loop {
        no_panic_so_far()?;
        let Some(c) = rt.block_on(claim(&http, url))? else {
            info!("middle-out: the coordinator has no field left ({done} done)");
            return Ok(());
        };
        let (coord, v_start, v_size) = field_of(&c)?;
        let q = coord.quantum();
        let t0 = (v_start - coord.start) / q;
        info!(
            "middle-out: claim {} base {} fields t [{t0}, {}) v [{v_start}, +{v_size})",
            c.claim_id,
            c.base,
            t0 + v_size / q
        );
        let began = Instant::now();
        // one join at a time on the card: a change of base drops the old one first
        if join.as_ref().is_some_and(|j| j.base() != c.base) {
            join = None;
        }
        if join.is_none() {
            #[allow(unused_mut)]
            let mut j = FieldJoin::new(client.clone(), c.base)?;
            #[cfg(feature = "midout-fault")]
            if let Some(f) = fault.as_deref().filter(|f| *f != "panic") {
                j.set_test_fault(f)?;
            }
            join = Some(j);
        }
        let j = join.as_ref().expect("set above");
        let cpu_check = j.cpu_check_default();
        if fault.as_deref() == Some("panic") {
            // stands in for the runtime's stream thread panicking mid-field
            let _ = std::thread::Builder::new()
                .name("midout-test-fault".into())
                .spawn(|| panic!("middle-out test fault: a runtime thread panics"))?
                .join();
        }
        let searched = j.search(&coord, v_start, v_size, cpu_check);
        let wall = began.elapsed().as_secs_f64();
        let (o, route_tel) = match searched {
            Ok(x) => x,
            Err(e) => {
                error!("middle-out: claim {} NOT submitted: {e:#}", c.claim_id);
                return Err(e.context(format!("middle-out: claim {} not submitted", c.claim_id)));
            }
        };
        if let Err(e) = no_panic_so_far() {
            error!("middle-out: claim {} NOT submitted: {e:#}", c.claim_id);
            return Err(e);
        }
        let nice_numbers: Vec<NiceNumberSimple> = o
            .nice
            .iter()
            .map(|&n| NiceNumberSimple {
                number: n,
                num_uniques: c.base,
            })
            .collect();
        let telemetry: Value = json!({
            "build_sha": BUILD_SHA,
            "client_version": CLIENT_VERSION,
            "device": device,
            "processing_secs": wall,
            "pipeline": {
                "route": wire::ROUTE,
                "coordinate": c.coordinate,
                "field": {"base": c.base, "v_start": v_start.to_string(), "v_size": v_size.to_string(),
                          "t0": t0.to_string(), "quanta": (v_size / q).to_string(),
                          "range_size": c.range_size.to_string()},
                "join": route_tel,
                "test_fault": fault,
            },
        });
        info!(
            "middle-out: claim {} searched in {wall:.2} s: survivors {} checked {} slices {} nice {:?}",
            c.claim_id, o.survivors, o.checked, o.slices, o.nice
        );
        let data = DataToServer {
            claim_id: c.claim_id,
            username: cli.username.clone(),
            client_version: CLIENT_VERSION.to_string(),
            unique_distribution: None,
            nice_numbers,
            telemetry: Some(telemetry),
        };
        rt.block_on(submit_field_to_server_async(
            &http,
            url.trim_end_matches('/'),
            data,
            cli.api_max_retries,
        ))?;
        done += 1;
        if !cli.repeat {
            return Ok(());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::Parser;

    fn cli() -> Cli {
        Cli::try_parse_from(["nice", "niceonly"]).expect("parse")
    }

    /// The route refuses the production API before it touches a device or the network.
    #[tokio::test]
    async fn refuses_the_production_api() {
        for u in [
            "https://api.nicenumbers.net",
            "http://API.nicenumbers.net.:80/",
            "nicenumbers.net",
        ] {
            let e = run(&cli(), u).await.expect_err("must refuse");
            assert!(e.to_string().contains("middle-out"), "{e}");
        }
    }

    fn claim(base: u32, start: u128, size: u128, n: u128, coordinate: &str) -> CoordClaim {
        CoordClaim {
            claim_id: 9,
            base,
            range_start: start,
            range_end: start + size,
            range_size: n,
            coordinate: coordinate.into(),
        }
    }

    /// A claim must be a whole-quanta field of a base with a device path, with the coordinate's count.
    #[test]
    fn claims_are_checked_before_work() {
        let c64 = Coord::for_base(64).unwrap();
        let q = c64.quantum();
        let s = c64.start + 77_777 * q;
        assert!(field_of(&claim(64, s, q, q, "midout:4,9,6")).is_ok());
        assert!(field_of(&claim(64, s, 2 * q, 2 * q, "midout:4,9,6")).is_ok());
        // a coordinate this client does not know is refused, even one midout::coord can express
        // (the field-structure review's base-64 proposal fixes digits 5-7: midout:4,8,5)
        for unknown in [
            "midout:4,8,5",
            "midout:4,9,7",
            "midout:3,9,6",
            "midout",
            "midout:4,9",
        ] {
            let e = field_of(&claim(64, s, q, q, unknown)).unwrap_err();
            assert!(format!("{e:#}").contains("coordinate"), "{unknown}: {e:#}");
        }
        assert!(
            field_of(&claim(64, s, q, q, "n")).is_err(),
            "other coordinate"
        );
        assert!(
            field_of(&claim(64, s + 1, q, q, "midout:4,9,6")).is_err(),
            "misaligned"
        );
        assert!(
            field_of(&claim(64, s, q / 2, q / 2, "midout:4,9,6")).is_err(),
            "part of a quantum"
        );
        assert!(
            field_of(&claim(64, s, q, q - 1, "midout:4,9,6")).is_err(),
            "wrong range_size"
        );
        assert!(
            field_of(&claim(64, c64.v_end(), q, q, "midout:4,9,6")).is_err(),
            "past the end"
        );
        let c65 = Coord::for_base(65).unwrap();
        let q65 = c65.quantum();
        let s65 = c65.start + 13_731 * q65;
        let n65 = c65.n_count(s65, q65).unwrap();
        assert!(field_of(&claim(65, s65, q65, n65, "midout:4,9,6")).is_ok());
        assert!(field_of(&claim(65, s65, q65, n65 + 1, "midout:4,9,6")).is_err());
        // base 65 is padded: a field holds fewer n than its v_size
        assert!(n65 <= q65);
        assert!(
            field_of(&claim(62, 0, 1, 1, "midout:4,9,6")).is_err(),
            "no coordinate"
        );
    }
}

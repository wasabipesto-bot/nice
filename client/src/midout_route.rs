//! The midout mode (`nice_client midout`): claim fields of the middle-out
//! coordinate from the API (`GET /claim/midout`), search them on the GPU with
//! `nice_common::midout::route`, submit them (`POST /submit/midout`). The
//! wire is `nice_common::midout::wire`; the device path needs a `CubeCL`
//! backend (feature `cubecl`), and a build without one refuses the mode.
//!
//! The options ([`Options::from_cli`]): `--api-base`, `--username`,
//! `--repeat`, `--api-max-retries`, `--gpu-backend` (auto, cubecl,
//! cubecl-cuda), `--gpu-device`, `--gpu-wgpu-device` and `--threads` (the
//! sampled CPU check's threads) apply; `--gpu` is implied (the join has no
//! CPU form for a real field); `--validate` and `--benchmark*` are refused;
//! `--prefetch-*` are ignored with a warning (the mode holds exactly one
//! field ahead); telemetry is always sent (it carries the sampled check).
//!
//! The loop ([`run_loop`], generic over the search so that tests drive it
//! with the CPU reference): while a field is searched, the next one is
//! claimed (under `--repeat`; at most one field held ahead, as a claim
//! expires on the server) and the previous one's submission finishes in the
//! background (at most one in flight). Without `--repeat`: one field, and
//! "nothing claimable" (204) ends the run with success. With it, 204 waits
//! and asks again ([`Idle`]).
//!
//! Guards (each refuses with a reason and a non-zero exit, and submits
//! nothing for the field at hand):
//! - an Apple Metal device is refused: the join has never been checked on
//!   one;
//! - a claim must name a middle-out coordinate this build knows
//!   (`"coordinate": "midout:K0,K1,Q0"`, one of the base's known
//!   coordinates, `Coord::is_known`), of a base with a device path, whole
//!   quanta, with the `range_size` the coordinate gives;
//! - a field whose accounts fail or whose sampled CPU check differs is not
//!   submitted (the library returns an error);
//! - a panic on any thread of the process (the GPU runtime's stream thread
//!   above all: `CubeCL` panics there on a failed allocation and the caller
//!   sees nothing) is recorded by a panic hook, installed before the device
//!   context is made;
//! - after any of these, or a refused submission, **nothing more is
//!   submitted**: the loop stops, finishes (or reports) the one submission
//!   still in flight, and the process exits non-zero.

// Without a `CubeCL` backend the mode only reads its options and refuses;
// the loop is still built, for its tests (which search with the CPU).
#![cfg_attr(not(feature = "cubecl"), allow(dead_code))]

use crate::{Cli, GpuBackend};
use anyhow::{Context, Result, anyhow, bail, ensure};
use log::{error, info, warn};
use nice_common::client_api_async::{Client, claim_midout_async, submit_midout_async};
use nice_common::midout::coord::coord_digits;
use nice_common::midout::wire::{
    self, ClaimAnswer, CoordClaim, FieldId, Reply, ReplyStatus, Submission,
};
use nice_common::midout::{Coord, FieldOutcome, Shape};
use nice_common::{BUILD_SHA, CLIENT_VERSION};
use serde_json::{Value, json};
use std::future::Future;
use std::pin::Pin;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, Instant};
use tokio::runtime::Handle;
use tokio::task::JoinHandle;

/// The first wait after "nothing claimable" under `--repeat`; each further
/// empty answer doubles it up to [`IDLE_CAP`]. The same ladder the API
/// retries climb (1 s, 2 s, 4 s, ...), never giving up: a midout box keeps
/// asking, as a server with nothing claimable is a normal state.
pub const IDLE_FIRST: Duration = Duration::from_secs(1);
/// The longest wait between two claims while nothing is claimable (the
/// longest wait of the default retry ladder, 2^8 s).
pub const IDLE_CAP: Duration = Duration::from_secs(256);

/// What the mode takes from the command line.
#[derive(Debug, Clone)]
pub struct Options {
    pub api_base: String,
    pub username: String,
    pub max_retries: u32,
    pub repeat: bool,
    /// The sampled CPU check's threads (0: the library's default).
    pub cpu_threads: usize,
    pub gpu_backend: GpuBackend,
    pub gpu_device: usize,
    pub gpu_wgpu_device: Option<String>,
}

impl Options {
    /// The mode's options, or the refusal of one that does not apply.
    /// `prefetch_set`: a `--prefetch-*` option was given (on the command
    /// line or in the environment).
    ///
    /// # Errors
    /// `--validate`, `--benchmark*`, or a GPU backend without a middle-out
    /// path.
    pub fn from_cli(cli: &Cli, prefetch_set: bool) -> Result<Self> {
        if cli.validate {
            bail!(
                "midout: --validate is not available in the midout mode (the server has no validation data for \
                 middle-out fields; every field gets the sampled CPU check instead)"
            );
        }
        if cli.benchmark {
            bail!(
                "midout: --benchmark measures the n-range modes; the middle-out join's benchmark is the \
                 midout_bench example of nice_common"
            );
        }
        if matches!(cli.gpu_backend, GpuBackend::Cuda | GpuBackend::CubeclHip) {
            let name = clap::ValueEnum::to_possible_value(&cli.gpu_backend).map_or_else(
                || format!("{:?}", cli.gpu_backend),
                |v| v.get_name().to_string(),
            );
            bail!(
                "midout: --gpu-backend {name} has no middle-out path (use auto, cubecl or cubecl-cuda)"
            );
        }
        if prefetch_set {
            warn!(
                "midout: --prefetch-* options are ignored: the midout mode holds exactly one field ahead"
            );
        }
        Ok(Self {
            api_base: cli.api_base.trim_end_matches('/').to_string(),
            username: cli.username.clone(),
            max_retries: cli.api_max_retries,
            repeat: cli.repeat,
            cpu_threads: cli.threads,
            gpu_backend: cli.gpu_backend,
            gpu_device: cli.gpu_device,
            gpu_wgpu_device: cli.gpu_wgpu_device.clone(),
        })
    }
}

/// The refusal of a build without a `CubeCL` backend.
///
/// # Errors
/// Always.
#[cfg(not(feature = "cubecl"))]
pub fn no_backend() -> Result<()> {
    bail!(
        "midout: this build carries no CubeCL backend, and the middle-out join has no CPU form for a real field \
         (use a GPU release binary, or build with --features gpu)"
    )
}

// ---------------------------------------------------------------- the loop

/// What the loop does when nothing is claimable (204) under `--repeat`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Idle {
    /// Wait, doubling from `first` up to `cap`, and ask again.
    Wait { first: Duration, cap: Duration },
    /// End the run (the tests' runs to "nothing left").
    #[cfg_attr(not(test), allow(dead_code))]
    Stop,
}

/// The loop's settings.
#[derive(Debug, Clone)]
pub struct LoopConfig {
    pub repeat: bool,
    pub idle: Idle,
    pub username: String,
}

/// A searched field: what a submission reports.
#[derive(Debug, Clone)]
pub struct Searched {
    pub outcome: FieldOutcome,
    pub shape: Shape,
    /// The route's telemetry (`pipeline.join`).
    pub join: Value,
    /// Telemetry keys of the searcher (device, ...), merged at the top level.
    pub extra: Value,
}

/// A search of claimed fields: the device path in the mode, the CPU
/// reference in the tests.
pub trait FieldSearcher {
    /// Every check a claim must pass before any work starts: the field
    /// `(coord, v_start, v_size)`.
    ///
    /// # Errors
    /// A claim this searcher must not search.
    fn accept(&mut self, c: &CoordClaim) -> Result<(Coord, u128, u128)>;
    /// Search the field.
    ///
    /// # Errors
    /// Any failure (a failed account, a sampled check that differs, a device
    /// error): the field is not submitted.
    fn search(
        &mut self,
        c: &CoordClaim,
        coord: &Coord,
        v_start: u128,
        v_size: u128,
    ) -> Result<Searched>;
}

type BoxFut<T> = Pin<Box<dyn Future<Output = Result<T>> + Send + 'static>>;

/// The two calls the loop makes (the HTTP API in the mode; a stand-in in
/// the tests). Each returns a future the loop runs in the background.
pub trait Api {
    fn claim(&self) -> BoxFut<ClaimAnswer>;
    fn submit(&self, s: Submission) -> BoxFut<Reply>;
}

/// The HTTP API at `api_base` (`midout::wire`), with the client's retries.
#[derive(Clone)]
pub struct HttpApi {
    pub http: Client,
    pub api_base: String,
    pub max_retries: u32,
}

impl HttpApi {
    /// # Errors
    /// The HTTP client cannot be built.
    pub fn new(api_base: &str, max_retries: u32) -> Result<Self> {
        let http = Client::builder()
            .timeout(Duration::from_secs(
                nice_common::CLIENT_REQUEST_TIMEOUT_SECS,
            ))
            .build()?;
        Ok(Self {
            http,
            api_base: api_base.trim_end_matches('/').to_string(),
            max_retries,
        })
    }
}

impl Api for HttpApi {
    fn claim(&self) -> BoxFut<ClaimAnswer> {
        let me = self.clone();
        Box::pin(async move { claim_midout_async(&me.http, &me.api_base, me.max_retries).await })
    }

    fn submit(&self, s: Submission) -> BoxFut<Reply> {
        let me = self.clone();
        Box::pin(
            async move { submit_midout_async(&me.http, &me.api_base, &s, me.max_retries).await },
        )
    }
}

/// What a run did.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct Summary {
    /// Fields searched and handed to the API.
    pub searched: u64,
    /// The replies, in order.
    pub replies: Vec<ReplyStatus>,
}

/// The submission of a searched field. Telemetry above the server's limit
/// loses its `pipeline.join` part (the counters stay in the body).
#[must_use]
pub fn submission(
    c: &CoordClaim,
    field: FieldId,
    s: &Searched,
    username: &str,
    wall: f64,
) -> Submission {
    let mut telemetry = json!({
        "build_sha": BUILD_SHA,
        "client_version": CLIENT_VERSION,
        "processing_secs": wall,
        "pipeline": {"route": wire::ROUTE, "coordinate": c.coordinate, "join": s.join},
    });
    if let (Some(t), Some(extra)) = (telemetry.as_object_mut(), s.extra.as_object()) {
        for (k, v) in extra {
            t.insert(k.clone(), v.clone());
        }
    }
    if serde_json::to_vec(&telemetry).map_or(0, |v| v.len()) > wire::TELEMETRY_MAX_BYTES {
        warn!(
            "middle-out: claim {}: telemetry over {} bytes, sent without its join part",
            c.claim_id,
            wire::TELEMETRY_MAX_BYTES
        );
        telemetry["pipeline"]["join"] = json!({"trimmed": true});
    }
    Submission {
        claim_id: c.claim_id,
        username: username.to_string(),
        client_version: CLIENT_VERSION.to_string(),
        field,
        nice_numbers: s.outcome.nice.clone(),
        shape: format!("{},{}", s.shape.f0, s.shape.k),
        survivors: s.outcome.survivors,
        checked: s.outcome.checked,
        slices: s.outcome.slices,
        telemetry,
    }
}

#[allow(clippy::needless_pass_by_value)] // map_err hands it over by value
fn join_err(e: tokio::task::JoinError) -> anyhow::Error {
    anyhow!("middle-out: a background request ended: {e}")
}

/// Wait for the submission in flight, if any, and log its reply.
fn finish(
    rt: &Handle,
    in_flight: &mut Option<(u128, JoinHandle<Result<Reply>>)>,
    sum: &mut Summary,
) -> Result<()> {
    let Some((claim_id, h)) = in_flight.take() else {
        return Ok(());
    };
    let r = rt
        .block_on(h)
        .map_err(join_err)?
        .with_context(|| format!("middle-out: claim {claim_id} not recorded"))?;
    match r.status {
        ReplyStatus::Canon => info!(
            "middle-out: claim {claim_id} recorded (submission {}, canon)",
            r.submission_id
        ),
        ReplyStatus::Check => info!(
            "middle-out: claim {claim_id} recorded as a check of a field searched before (submission {})",
            r.submission_id
        ),
        ReplyStatus::AlreadyRecorded => info!(
            "middle-out: claim {claim_id} was already recorded (submission {}): a reply had been lost",
            r.submission_id
        ),
    }
    sum.replies.push(r.status);
    Ok(())
}

/// Run the loop: claim, search, submit, as the module documentation says.
/// `healthy` is asked before each claim is used and after each search (the
/// mode passes the panic record).
///
/// # Errors
/// A guard, a refused claim or submission, a failed search, an unhealthy
/// process: the run stops, nothing more is submitted, and the submission
/// still in flight is finished first (its own failure joins the error).
pub fn run_loop<S: FieldSearcher, A: Api>(
    rt: &Handle,
    api: &A,
    searcher: &mut S,
    cfg: &LoopConfig,
    healthy: &dyn Fn() -> Result<()>,
) -> Result<Summary> {
    let mut sum = Summary::default();
    let mut ahead: Option<JoinHandle<Result<ClaimAnswer>>> = Some(rt.spawn(api.claim()));
    let mut in_flight: Option<(u128, JoinHandle<Result<Reply>>)> = None;
    let mut wait = match cfg.idle {
        Idle::Wait { first, .. } => first,
        Idle::Stop => Duration::ZERO,
    };
    let result = (|| -> Result<()> {
        loop {
            healthy()?;
            let answer = rt
                .block_on(ahead.take().expect("a claim is always asked for here"))
                .map_err(join_err)??;
            let c = match answer {
                ClaimAnswer::Field(c) => c,
                ClaimAnswer::Empty => {
                    // "nothing left" is said only once everything searched is recorded
                    finish(rt, &mut in_flight, &mut sum)?;
                    let Idle::Wait { cap, .. } = cfg.idle else {
                        info!("middle-out: nothing claimable ({} searched)", sum.searched);
                        return Ok(());
                    };
                    if !cfg.repeat {
                        info!("middle-out: the server has no middle-out field to hand out now");
                        return Ok(());
                    }
                    info!(
                        "middle-out: nothing claimable; asking again in {} s",
                        wait.as_secs_f64()
                    );
                    std::thread::sleep(wait);
                    wait = (wait * 2).min(cap);
                    ahead = Some(rt.spawn(api.claim()));
                    continue;
                }
            };
            if let Idle::Wait { first, .. } = cfg.idle {
                wait = first;
            }
            let (coord, v_start, v_size) = searcher.accept(&c)?;
            let field = FieldId::of_claim(&c)?;
            // one field ahead: the next claim runs while this one is searched
            if cfg.repeat {
                ahead = Some(rt.spawn(api.claim()));
            }
            // a submission refused meanwhile stops the run before more work
            if in_flight.as_ref().is_some_and(|(_, h)| h.is_finished()) {
                finish(rt, &mut in_flight, &mut sum)?;
            }
            let q = coord.quantum();
            let t0 = (v_start - coord.start()) / q;
            info!(
                "middle-out: claim {} base {} fields t [{t0}, {}) v [{v_start}, +{v_size})",
                c.claim_id,
                c.base,
                t0 + v_size / q
            );
            let began = Instant::now();
            let outcome = searcher
                .search(&c, &coord, v_start, v_size)
                .and_then(|s| healthy().map(|()| s));
            let wall = began.elapsed().as_secs_f64();
            let s = match outcome {
                Ok(s) => s,
                Err(e) => {
                    error!("middle-out: claim {} NOT submitted: {e:#}", c.claim_id);
                    return Err(
                        e.context(format!("middle-out: claim {} not submitted", c.claim_id))
                    );
                }
            };
            info!(
                "middle-out: claim {} searched in {wall:.2} s: survivors {} checked {} slices {} nice {:?}",
                c.claim_id,
                s.outcome.survivors,
                s.outcome.checked,
                s.outcome.slices,
                s.outcome.nice
            );
            let body = submission(&c, field, &s, &cfg.username, wall);
            // at most one submission in flight
            finish(rt, &mut in_flight, &mut sum)?;
            in_flight = Some((c.claim_id, rt.spawn(api.submit(body))));
            sum.searched += 1;
            if !cfg.repeat {
                return Ok(());
            }
        }
    })();
    // whatever ended the run, the submission in flight is finished or reported
    let tail = finish(rt, &mut in_flight, &mut sum);
    if let Some(h) = ahead {
        // a claim held ahead and never searched expires on the server
        h.abort();
    }
    match (result, tail) {
        (Ok(()), Ok(())) => Ok(sum),
        (Err(e), Ok(())) | (Ok(()), Err(e)) => Err(e),
        (Err(e), Err(t)) => {
            error!("middle-out: {t:#}");
            Err(e.context(format!("and the submission in flight failed: {t:#}")))
        }
    }
}

// ---------------------------------------------------------- the device path

static PANICKED: AtomicBool = AtomicBool::new(false);
static PANICS: Mutex<Vec<String>> = Mutex::new(Vec::new());

/// Record every panic of the process (then run the previous hook, which
/// prints it). Installed once by the mode; the other modes never install it.
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
        let v = PANICS
            .lock()
            .map_or_else(|_| String::new(), |v| v.join("; "));
        bail!("middle-out: a thread of this process panicked ({v}): nothing more is submitted");
    }
    Ok(())
}

/// The claim's field `(coord, v_start, v_size)`, after every check a claim
/// must pass before the device path searches it.
///
/// # Errors
/// An unknown coordinate, a base without a device path, a field that is not
/// whole quanta, or a `range_size` that is not the field's count.
pub fn field_of(c: &CoordClaim) -> Result<(Coord, u128, u128)> {
    // the claim names its coordinate; build it from the claim, then refuse it
    // unless it is the one this build's device path for the base searches
    let (k0, k1, q0) = wire::parse_coordinate_id(&c.coordinate)
        .with_context(|| format!("middle-out: claim {}", c.claim_id))?;
    ensure!(
        (64..=65).contains(&c.base),
        "middle-out: claim {}: base {} has no device path",
        c.claim_id,
        c.base
    );
    let coord = Coord::with_digits(c.base, k0, k1, q0)?;
    ensure!(
        coord.is_known(),
        "middle-out: claim {}: coordinate '{}' of base {} is not one this client knows (the base's is '{}', and '{}' at bases 64 and 65)",
        c.claim_id,
        c.coordinate,
        c.base,
        coord_digits(c.base).map_or_else(String::new, |(a, b, q)| wire::coordinate_id(a, b, q)),
        wire::coordinate_id(4, 9, 6)
    );
    field_in(&coord, c)
}

/// The claim's range as a field of `coord`, with its count checked.
///
/// # Errors
/// Not whole quanta, outside the coordinate, or a `range_size` that is not
/// the field's count.
pub fn field_in(coord: &Coord, c: &CoordClaim) -> Result<(Coord, u128, u128)> {
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
    Ok((coord.clone(), c.range_start, v_size))
}

/// Whether a device, by the name `CubeclContext::device_name` gives it, is
/// an Apple Metal device: a wgpu adapter on the Metal graphics API (the name
/// ends in `(Metal, <compiler>)`), or `CubeCL`'s own Metal compiler
/// (`wgpu<msl>`). The middle-out kernels have never run on one.
fn is_metal(device: &str) -> bool {
    device.contains("(Metal, ") || device.contains("wgpu<msl>")
}

/// The test switch (`midout-fault` builds only): `NICE_MIDOUT_FAULT` =
/// `accounts` | `sample` (library fault bits) | `panic` (a thread of this
/// process panics during the field).
#[cfg(feature = "cubecl")]
fn fault_switch() -> Option<String> {
    if cfg!(feature = "midout-fault") {
        std::env::var("NICE_MIDOUT_FAULT")
            .ok()
            .filter(|s| !s.is_empty())
    } else {
        None
    }
}

/// Run the mode.
///
/// # Errors
/// A refused option, any guard (above), a claim or submission failure, or a
/// device error: the client exits non-zero with the reason.
#[cfg(feature = "cubecl")]
pub async fn run(options: Result<Options>) -> Result<()> {
    let options = options?;
    tokio::task::spawn_blocking(move || run_blocking(&options))
        .await
        .map_err(|e| anyhow!("middle-out: the mode's thread ended: {e}"))?
}

#[cfg(feature = "cubecl")]
fn run_blocking(o: &Options) -> Result<()> {
    use nice_common::cubecl_backend::CubeclContext;
    // before the device context: a runtime thread can panic while it is made
    install_panic_hook();
    if let Some(spec) = &o.gpu_wgpu_device {
        // the CubeCL wgpu runtime reads its adapter from this variable (as the
        // other modes set it in init_gpu); no other thread of ours runs yet
        unsafe { std::env::set_var("CUBECL_WGPU_DEFAULT_DEVICE", spec) };
        info!("CubeCL wgpu adapter pinned to {spec}");
    }
    let ctx = match o.gpu_backend {
        #[cfg(feature = "cubecl-cuda")]
        GpuBackend::Auto | GpuBackend::CubeclCuda => CubeclContext::new_cuda(o.gpu_device)?,
        GpuBackend::Cubecl => wgpu_context(o)?,
        #[cfg(not(feature = "cubecl-cuda"))]
        GpuBackend::Auto => wgpu_context(o)?,
        other => bail!("middle-out: backend {other:?} has no middle-out path"),
    };
    let device = ctx.device_name();
    no_panic_so_far()?;
    if is_metal(&device) {
        bail!(
            "middle-out: the join has never been checked on an Apple Metal device ({device}), so this mode refuses it"
        );
    }
    info!(
        "Nice Client v{CLIENT_VERSION} started in midout mode: API {}, device {device}",
        o.api_base
    );
    match &ctx {
        CubeclContext::Wgpu { client, .. } => drive(o, &device, client),
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => drive(o, &device, client),
        #[allow(unreachable_patterns)]
        _ => bail!("middle-out: unsupported runtime"),
    }
}

/// The wgpu context (`--gpu-wgpu-device` picks its adapter, not `--gpu-device`).
#[cfg(feature = "cubecl")]
fn wgpu_context(o: &Options) -> Result<nice_common::cubecl_backend::CubeclContext> {
    if o.gpu_device != 0 {
        warn!(
            "midout: --gpu-device {} selects a CUDA device; a wgpu adapter is chosen with --gpu-wgpu-device",
            o.gpu_device
        );
    }
    nice_common::cubecl_backend::CubeclContext::new_default()
}

/// The device path as a [`FieldSearcher`].
#[cfg(feature = "cubecl")]
struct DeviceSearch<'a, R: nice_common::midout::route::DeviceRuntime> {
    client: &'a nice_common::midout::route::Client<R>,
    join: Option<nice_common::midout::route::FieldJoin<R>>,
    device: String,
    fault: Option<String>,
    cpu_threads: usize,
}

#[cfg(feature = "cubecl")]
impl<R: nice_common::midout::route::DeviceRuntime> FieldSearcher for DeviceSearch<'_, R> {
    fn accept(&mut self, c: &CoordClaim) -> Result<(Coord, u128, u128)> {
        field_of(c)
    }

    fn search(
        &mut self,
        c: &CoordClaim,
        coord: &Coord,
        v_start: u128,
        v_size: u128,
    ) -> Result<Searched> {
        use nice_common::midout::route::FieldJoin;
        // one join at a time on the card: a change of base drops the old one first
        if self.join.as_ref().is_some_and(|j| j.base() != c.base) {
            self.join = None;
        }
        if self.join.is_none() {
            #[allow(unused_mut)]
            let mut j = FieldJoin::new(self.client.clone(), c.base)?;
            #[cfg(feature = "midout-fault")]
            if let Some(f) = self.fault.as_deref().filter(|f| *f != "panic") {
                j.set_test_fault(f)?;
            }
            self.join = Some(j);
        }
        let j = self.join.as_ref().expect("set above");
        if self.fault.as_deref() == Some("panic") {
            // stands in for the runtime's stream thread panicking mid-field
            let _ = std::thread::Builder::new()
                .name("midout-test-fault".into())
                .spawn(|| panic!("middle-out test fault: a runtime thread panics"))?
                .join();
        }
        let (outcome, join) = j.search(
            coord,
            v_start,
            v_size,
            j.cpu_check_default(),
            self.cpu_threads,
        )?;
        Ok(Searched {
            outcome,
            shape: Shape::for_coord(coord),
            join,
            extra: json!({"device": self.device, "test_fault": self.fault}),
        })
    }
}

#[cfg(feature = "cubecl")]
fn drive<R: nice_common::midout::route::DeviceRuntime>(
    o: &Options,
    device: &str,
    client: &nice_common::midout::route::Client<R>,
) -> Result<()> {
    let rt = Handle::current();
    let fault = fault_switch();
    if let Some(f) = &fault {
        warn!("middle-out: TEST FAULT '{f}' is on");
    }
    let mut searcher = DeviceSearch {
        client,
        join: None,
        device: device.to_string(),
        fault,
        cpu_threads: o.cpu_threads,
    };
    let api = HttpApi::new(&o.api_base, o.max_retries)?;
    let cfg = LoopConfig {
        repeat: o.repeat,
        idle: Idle::Wait {
            first: IDLE_FIRST,
            cap: IDLE_CAP,
        },
        username: o.username.clone(),
    };
    let sum = run_loop(&rt, &api, &mut searcher, &cfg, &no_panic_so_far)?;
    info!(
        "middle-out: {} field(s) searched and recorded",
        sum.searched
    );
    Ok(())
}

#[cfg(test)]
mod tests;

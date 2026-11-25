//! Tests of the midout mode: the options, the claim checks, the loop with a
//! stand-in API and search (the stop rule, the overlap), and the loop end to
//! end against the development server (`scripts/midout_coordinator.py`) on
//! 127.0.0.1, searching with the CPU reference on small bases.

use super::*;
use clap::{CommandFactory, FromArgMatches};
use nice_common::midout::cpu;
use std::collections::VecDeque;
use std::sync::Arc;
use std::sync::atomic::AtomicUsize;

/// A local address nothing listens on: no test may fall back to the default API.
const NOWHERE: &str = "http://127.0.0.1:9";

fn parse(args: &[&str]) -> Result<Cli, clap::Error> {
    let mut v = vec!["nice_client"];
    v.extend_from_slice(args);
    let m = Cli::command().try_get_matches_from(v)?;
    Cli::from_arg_matches(&m)
}

#[test]
fn the_mode_is_on_the_command_line() {
    let cli = parse(&["midout", "--api-base", NOWHERE]).unwrap();
    assert_eq!(cli.mode, crate::ClientMode::Midout);
    let help = Cli::command().render_long_help().to_string();
    assert!(
        help.contains("midout") && help.contains("middle-out fields"),
        "{help}"
    );
    // the development flag is gone
    assert!(parse(&["niceonly", "--midout-coordinator", NOWHERE]).is_err());
    // the two n-range modes keep their SearchMode
    assert_eq!(
        parse(&["niceonly"]).unwrap().mode.search(),
        nice_common::SearchMode::Niceonly
    );
    assert_eq!(
        parse(&["detailed"]).unwrap().mode.search(),
        nice_common::SearchMode::Detailed
    );
}

#[test]
fn options_that_do_not_apply_are_refused() {
    let o = Options::from_cli(
        &parse(&[
            "midout",
            "--api-base",
            "http://127.0.0.1:8470/",
            "-r",
            "-u",
            "me",
            "-t",
            "3",
        ])
        .unwrap(),
        false,
    )
    .unwrap();
    assert_eq!(
        (
            o.api_base.as_str(),
            o.username.as_str(),
            o.repeat,
            o.cpu_threads
        ),
        ("http://127.0.0.1:8470", "me", true, 3)
    );
    for (args, word) in [
        (&["--validate"][..], "--validate"),
        (&["-b"][..], "--benchmark"),
        (&["--gpu-backend", "cuda"][..], "no middle-out path"),
        (&["--gpu-backend", "cubecl-hip"][..], "no middle-out path"),
    ] {
        let mut v = vec!["midout", "--api-base", NOWHERE];
        v.extend_from_slice(args);
        let e = Options::from_cli(&parse(&v).unwrap(), false)
            .unwrap_err()
            .to_string();
        assert!(e.contains(word), "{args:?}: {e}");
    }
    // a prefetch option is reported, not refused
    assert!(Options::from_cli(&parse(&["midout", "--api-base", NOWHERE]).unwrap(), true).is_ok());
    for ok in ["auto", "cubecl", "cubecl-cuda"] {
        let cli = parse(&["midout", "--api-base", NOWHERE, "--gpu-backend", ok]).unwrap();
        assert!(Options::from_cli(&cli, false).is_ok(), "{ok}");
    }
}

/// Apple Metal devices are told apart by the names the client's device
/// contexts give them; Vulkan, DX12, CUDA and HIP devices are not refused.
#[test]
fn metal_devices_are_refused() {
    for metal in [
        "Apple M4 (Metal, wgpu<wgsl>)",
        "Apple Paravirtual device (Metal, wgpu<wgsl>)",
        "Apple M1 Max (Metal, wgpu<msl>)",
    ] {
        assert!(is_metal(metal), "{metal}");
    }
    for other in [
        "AMD Radeon RX 9070 XT (RADV GFX1201) (Vulkan, wgpu<spirv>)",
        "llvmpipe (LLVM 20.1.2, 256 bits) (Vulkan, wgpu<wgsl>)",
        "NVIDIA GeForce RTX 3080 (Dx12, wgpu<wgsl>)",
        "NVIDIA GeForce RTX 3080",
        "AMD Radeon RX 7900 XTX",
    ] {
        assert!(!is_metal(other), "{other}");
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
    let c64 = Coord::with_digits(64, 4, 9, 6).unwrap();
    let q = c64.quantum();
    let s = c64.start() + 77_777 * q;
    assert!(field_of(&claim(64, s, q, q, "midout:4,9,6")).is_ok());
    assert!(field_of(&claim(64, s, 2 * q, 2 * q, "midout:4,9,6")).is_ok());
    // both known coordinates of base 64 are accepted, each giving its own coordinate
    for id in ["midout:4,9,6", "midout:4,8,5"] {
        let (k0, k1, q0) = wire::parse_coordinate_id(id).unwrap();
        let c = Coord::with_digits(64, k0, k1, q0).unwrap();
        let (got, vs, vz) = field_of(&claim(64, s, q, q, id)).unwrap();
        assert_eq!((got, vs, vz), (c, s, q), "{id}");
    }
    assert_eq!(Coord::with_digits(64, 4, 8, 5).unwrap().quantum(), q);
    // a coordinate this client does not know is refused, even one midout::coord can express
    for unknown in [
        "midout:4,8,6",
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
    let c65 = Coord::with_digits(65, 4, 9, 6).unwrap();
    let q65 = c65.quantum();
    let s65 = c65.start() + 13_731 * q65;
    let n65 = c65.n_count(s65, q65).unwrap();
    assert!(field_of(&claim(65, s65, q65, n65, "midout:4,9,6")).is_ok());
    assert!(field_of(&claim(65, s65, q65, n65 + 1, "midout:4,9,6")).is_err());
    // base 65 under (4, 8, 5): its own quantum and padded count
    let c65b = Coord::with_digits(65, 4, 8, 5).unwrap();
    let q65b = c65b.quantum();
    let s65b = c65b.start() + 13_731 * q65b;
    let n65b = c65b.n_count(s65b, q65b).unwrap();
    assert!(field_of(&claim(65, s65b, q65b, n65b, "midout:4,8,5")).is_ok());
    assert!(field_of(&claim(65, s65b, q65b, n65b + 1, "midout:4,8,5")).is_err());
    assert!(
        field_of(&claim(65, s65b, q65b, n65b, "midout:4,9,6")).is_err(),
        "a (4, 8, 5) field read as (4, 9, 6)"
    );
    assert!(
        field_of(&claim(68, 0, 1, 1, "midout:4,8,5")).is_err(),
        "(4, 8, 5) is not known at base 68"
    );
    // base 65 is padded: a field holds fewer n than its v_size
    assert!(n65 <= q65);
    assert!(
        field_of(&claim(62, 0, 1, 1, "midout:4,9,6")).is_err(),
        "no coordinate"
    );
}

// ------------------------------------------------------------- the CPU search

/// The fields `ts` of a small base's coordinate, as claims (ids from 1).
fn small_claims(b: u32, d: (u32, u32, u32), ts: &[u128]) -> Vec<CoordClaim> {
    let coord = Coord::with_digits(b, d.0, d.1, d.2).unwrap();
    let q = coord.quantum();
    ts.iter()
        .zip(1..)
        .map(|(&t, id)| {
            let s = coord.start() + t * q;
            CoordClaim {
                claim_id: id,
                base: b,
                range_start: s,
                range_end: s + q,
                range_size: coord.n_count(s, q).unwrap(),
                coordinate: wire::coordinate_id(d.0, d.1, d.2),
            }
        })
        .collect()
}

/// The CPU reference as the loop's search, for any coordinate of a base up
/// to 64; `fail_on` makes the k-th search (from 1) fail, `tamper` reports
/// one slice too many.
#[derive(Default)]
struct CpuSearch {
    fail_on: Option<u64>,
    tamper: bool,
    done: u64,
    /// The claims asked of the stand-in API when each search began.
    asked_at_start: Vec<usize>,
    asked: Option<Arc<AtomicUsize>>,
    began: Vec<Instant>,
}

impl FieldSearcher for CpuSearch {
    fn accept(&mut self, c: &CoordClaim) -> Result<(Coord, u128, u128)> {
        let (k0, k1, q0) = wire::parse_coordinate_id(&c.coordinate)?;
        field_in(&Coord::with_digits(c.base, k0, k1, q0)?, c)
    }

    fn search(
        &mut self,
        _c: &CoordClaim,
        coord: &Coord,
        v_start: u128,
        v_size: u128,
    ) -> Result<Searched> {
        self.done += 1;
        self.began.push(Instant::now());
        if let Some(a) = &self.asked {
            self.asked_at_start.push(a.load(Ordering::SeqCst));
        }
        if self.fail_on == Some(self.done) {
            bail!("stand-in search failure (an account that does not close)");
        }
        let shape = Shape::for_coord(coord);
        let (mut outcome, _) = cpu::search_field::<u64>(coord, shape, v_start, v_size, 1)?;
        if self.tamper {
            outcome.slices += 1;
        }
        Ok(Searched {
            outcome,
            shape,
            join: json!({"path": "cpu"}),
            extra: json!({"device": "the CPU reference"}),
        })
    }
}

// ------------------------------------------------------------ a stand-in API

/// Claims from a script (then 204 for ever), submissions recorded, replies
/// from `reply`, each submission taking `delay`.
struct StandIn {
    claims: Mutex<VecDeque<Result<ClaimAnswer>>>,
    asked: Arc<AtomicUsize>,
    submitted: Arc<Mutex<Vec<(Submission, Instant)>>>,
    reply: fn(&Submission) -> Result<Reply>,
    delay: Duration,
}

impl StandIn {
    fn new(claims: Vec<CoordClaim>, reply: fn(&Submission) -> Result<Reply>) -> Self {
        Self {
            claims: Mutex::new(
                claims
                    .into_iter()
                    .map(|c| Ok(ClaimAnswer::Field(c)))
                    .collect(),
            ),
            asked: Arc::new(AtomicUsize::new(0)),
            submitted: Arc::new(Mutex::new(Vec::new())),
            reply,
            delay: Duration::ZERO,
        }
    }

    fn submitted(&self) -> Vec<u128> {
        self.submitted
            .lock()
            .unwrap()
            .iter()
            .map(|(s, _)| s.claim_id)
            .collect()
    }
}

impl Api for StandIn {
    fn claim(&self) -> BoxFut<ClaimAnswer> {
        self.asked.fetch_add(1, Ordering::SeqCst);
        let next = self
            .claims
            .lock()
            .unwrap()
            .pop_front()
            .unwrap_or(Ok(ClaimAnswer::Empty));
        Box::pin(async move { next })
    }

    fn submit(&self, s: Submission) -> BoxFut<Reply> {
        let (reply, delay, log) = (self.reply, self.delay, self.submitted.clone());
        Box::pin(async move {
            tokio::time::sleep(delay).await;
            let r = reply(&s);
            log.lock().unwrap().push((s, Instant::now()));
            r
        })
    }
}

#[allow(clippy::unnecessary_wraps)] // the stand-in's reply function returns a Result
fn canon(s: &Submission) -> Result<Reply> {
    Ok(Reply {
        submission_id: u64::try_from(s.claim_id).unwrap(),
        status: ReplyStatus::Canon,
    })
}

fn cfg(repeat: bool) -> LoopConfig {
    LoopConfig {
        repeat,
        idle: Idle::Stop,
        username: "test".into(),
    }
}

#[allow(clippy::unnecessary_wraps)] // the loop's health check returns a Result
fn ok() -> Result<()> {
    Ok(())
}

fn runtime() -> tokio::runtime::Runtime {
    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .unwrap()
}

#[test]
fn a_run_to_nothing_left() {
    let rt = runtime();
    let api = StandIn::new(
        small_claims(10, (0, 1, 0), &[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        canon,
    );
    let mut s = CpuSearch {
        asked: Some(api.asked.clone()),
        ..Default::default()
    };
    let sum = run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).unwrap();
    assert_eq!(sum.searched, 10);
    assert_eq!(sum.replies, vec![ReplyStatus::Canon; 10]);
    assert_eq!(api.submitted(), (1..=10).collect::<Vec<_>>());
    // exactly one field held ahead: the k-th search began with k + 1 claims asked
    assert_eq!(s.asked_at_start, (2..=11).collect::<Vec<_>>());
    // base 10's one nice number, 69, is in the field of its last digit
    let subs = api.submitted.lock().unwrap();
    let with: Vec<_> = subs
        .iter()
        .filter(|(x, _)| !x.nice_numbers.is_empty())
        .collect();
    assert_eq!(with.len(), 1);
    assert_eq!(with[0].0.nice_numbers, vec![69]);
    assert_eq!(with[0].0.shape, "0,2");
}

#[test]
fn without_repeat_one_field_and_no_claim_ahead() {
    let rt = runtime();
    let api = StandIn::new(small_claims(10, (0, 1, 0), &[3, 4]), canon);
    let sum = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(false),
        &ok,
    )
    .unwrap();
    assert_eq!((sum.searched, api.asked.load(Ordering::SeqCst)), (1, 1));
    assert_eq!(api.submitted(), vec![1]);
    // nothing claimable: success, nothing searched
    let api = StandIn::new(vec![], canon);
    let sum = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(false),
        &ok,
    )
    .unwrap();
    assert_eq!(sum, Summary::default());
}

#[test]
fn a_failed_search_stops_and_the_submission_in_flight_finishes() {
    let rt = runtime();
    let mut api = StandIn::new(small_claims(10, (0, 1, 0), &[0, 1, 2, 3, 4]), canon);
    api.delay = Duration::from_millis(300);
    let mut s = CpuSearch {
        fail_on: Some(3),
        ..Default::default()
    };
    let e = run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).unwrap_err();
    assert!(format!("{e:#}").contains("claim 3 not submitted"), "{e:#}");
    // fields 1 and 2 recorded (2 was in flight when 3 failed), nothing after
    assert_eq!(api.submitted(), vec![1, 2]);
    assert_eq!(s.done, 3);
}

#[test]
fn an_unhealthy_process_submits_nothing_more() {
    let rt = runtime();
    let api = StandIn::new(small_claims(10, (0, 1, 0), &[0, 1, 2]), canon);
    let calls = AtomicUsize::new(0);
    // healthy for the first claim and its search, then a panic is "recorded"
    let healthy = || -> Result<()> {
        if calls.fetch_add(1, Ordering::SeqCst) >= 2 {
            bail!("a thread of this process panicked");
        }
        Ok(())
    };
    let e = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(true),
        &healthy,
    )
    .unwrap_err();
    assert!(format!("{e:#}").contains("panicked"), "{e:#}");
    assert_eq!(api.submitted(), vec![1]);
    // a panic seen right after a search: that field is not submitted either
    let api = StandIn::new(small_claims(10, (0, 1, 0), &[0, 1, 2]), canon);
    let calls = AtomicUsize::new(0);
    let healthy = || -> Result<()> {
        if calls.fetch_add(1, Ordering::SeqCst) >= 1 {
            bail!("a thread of this process panicked");
        }
        Ok(())
    };
    assert!(
        run_loop(
            rt.handle(),
            &api,
            &mut CpuSearch::default(),
            &cfg(true),
            &healthy
        )
        .is_err()
    );
    assert_eq!(api.submitted(), Vec::<u128>::new());
}

#[test]
fn a_refused_submission_stops_the_run() {
    let rt = runtime();
    let api = StandIn::new(small_claims(10, (0, 1, 0), &[0, 1, 2, 3]), |s| {
        wire::submit_answer(422, b"slices 5, but the field has 4 slices", s.claim_id)
    });
    let mut s = CpuSearch::default();
    let e = run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).unwrap_err();
    assert!(format!("{e:#}").contains("disagree"), "{e:#}");
    // the refusal of 1 is seen before 2 is submitted
    assert_eq!(api.submitted(), vec![1]);
    assert!(s.done <= 2);
    // already_recorded is success
    let api = StandIn::new(small_claims(10, (0, 1, 0), &[0, 1]), |s| {
        Ok(Reply {
            submission_id: u64::try_from(s.claim_id).unwrap(),
            status: ReplyStatus::AlreadyRecorded,
        })
    });
    let sum = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(true),
        &ok,
    )
    .unwrap();
    assert_eq!(sum.replies, vec![ReplyStatus::AlreadyRecorded; 2]);
}

#[test]
fn the_card_does_not_wait_for_a_submission() {
    let rt = runtime();
    let mut api = StandIn::new(small_claims(10, (0, 1, 0), &[0, 1]), canon);
    api.delay = Duration::from_millis(400);
    let mut s = CpuSearch::default();
    run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).unwrap();
    let subs = api.submitted.lock().unwrap();
    // the second search began before the first submission came back
    assert!(
        s.began[1] < subs[0].1,
        "the search waited for the submission"
    );
}

#[test]
fn nothing_claimable_waits_and_asks_again() {
    let rt = runtime();
    let api = StandIn::new(vec![], canon);
    {
        let mut q = api.claims.lock().unwrap();
        q.push_back(Ok(ClaimAnswer::Empty));
        q.push_back(Ok(ClaimAnswer::Empty));
        q.push_back(Ok(ClaimAnswer::Field(
            small_claims(10, (0, 1, 0), &[5]).remove(0),
        )));
        q.push_back(Err(anyhow!("stand-in: the server went away")));
    }
    let c = LoopConfig {
        repeat: true,
        idle: Idle::Wait {
            first: Duration::from_millis(5),
            cap: Duration::from_millis(10),
        },
        username: "test".into(),
    };
    let e = run_loop(rt.handle(), &api, &mut CpuSearch::default(), &c, &ok).unwrap_err();
    assert!(e.to_string().contains("went away"), "{e:#}");
    // two waits, the field, its submission finished before the run ended
    assert_eq!(api.asked.load(Ordering::SeqCst), 4);
    assert_eq!(api.submitted(), vec![1]);
}

#[test]
fn submissions_carry_the_field_and_small_telemetry() {
    let c = small_claims(10, (0, 1, 0), &[9]).remove(0);
    let s = Searched {
        outcome: FieldOutcome {
            nice: vec![69],
            survivors: 3,
            checked: 1,
            slices: 1,
        },
        shape: Shape { f0: 0, k: 2 },
        join: json!({"path": "cpu"}),
        extra: json!({"device": "x"}),
    };
    let b = submission(&c, FieldId::of_claim(&c).unwrap(), &s, "me", 1.5);
    assert_eq!(
        (b.claim_id, b.shape.as_str(), b.nice_numbers.clone()),
        (1, "0,2", vec![69])
    );
    assert_eq!(b.field.v_size, c.range_end - c.range_start);
    assert_eq!(b.telemetry["pipeline"]["route"], "midout");
    assert_eq!(b.telemetry["device"], "x");
    // telemetry over the server's limit loses its join part, not the field
    let big = Searched {
        join: json!({"blob": "x".repeat(wire::TELEMETRY_MAX_BYTES)}),
        ..s
    };
    let b = submission(&c, FieldId::of_claim(&c).unwrap(), &big, "me", 1.5);
    assert!(serde_json::to_vec(&b.telemetry).unwrap().len() <= wire::TELEMETRY_MAX_BYTES);
    assert_eq!(b.telemetry["pipeline"]["join"]["trimmed"], true);
}

// ------------------------------------------- end to end: the development server
//
// Unix only: the development server takes its state directory's lock with
// `fcntl`, which Windows' Python does not have.

#[cfg(unix)]
fn repo(path: &str) -> String {
    format!("{}/../{path}", env!("CARGO_MANIFEST_DIR"))
}

#[cfg(unix)]
/// A development server on 127.0.0.1 with its own state directory, stopped
/// (by its PID) and removed on drop.
struct Server {
    child: std::process::Child,
    base: String,
    dir: std::path::PathBuf,
}

#[cfg(unix)]
impl Server {
    /// `None` if this machine has no `python3` (the test is then skipped, loudly).
    fn start(name: &str, work: &[CoordClaim], extra: &[&str]) -> Option<Self> {
        let python = std::process::Command::new("python3")
            .arg("--version")
            .output();
        if !python.is_ok_and(|o| o.status.success()) {
            eprintln!("SKIPPED: no python3 for the development server");
            return None;
        }
        let dir = std::env::temp_dir().join(format!("nice-midout-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let list: Vec<Value> = work
            .iter()
            .map(|c| {
                json!({"base": c.base, "coordinate": c.coordinate, "range_start": c.range_start,
                       "range_end": c.range_end, "range_size": c.range_size})
            })
            .collect();
        let wl = dir.join("work.json");
        std::fs::write(&wl, serde_json::to_string(&list).unwrap()).unwrap();
        let port = std::net::TcpListener::bind("127.0.0.1:0")
            .unwrap()
            .local_addr()
            .unwrap()
            .port();
        let child = std::process::Command::new("python3")
            .arg(repo("scripts/midout_coordinator.py"))
            .args([
                "--worklist",
                wl.to_str().unwrap(),
                "--port",
                &port.to_string(),
            ])
            .args(["--state", dir.join("state").to_str().unwrap()])
            .args(extra)
            .stderr(std::fs::File::create(dir.join("server.log")).unwrap())
            .spawn()
            .unwrap();
        let s = Self {
            child,
            base: format!("http://127.0.0.1:{port}"),
            dir,
        };
        for _ in 0..200 {
            if std::net::TcpStream::connect(("127.0.0.1", port)).is_ok() {
                return Some(s);
            }
            std::thread::sleep(Duration::from_millis(50));
        }
        panic!(
            "the development server did not start: {}",
            std::fs::read_to_string(s.dir.join("server.log")).unwrap_or_default()
        );
    }

    fn status(&self, rt: &tokio::runtime::Runtime) -> Value {
        let url = format!("{}/status", self.base);
        rt.block_on(async {
            Client::new()
                .get(&url)
                .send()
                .await
                .unwrap()
                .json::<Value>()
                .await
                .unwrap()
        })
    }

    fn audit(&self) -> std::process::Output {
        std::process::Command::new("python3")
            .arg(repo("scripts/midout_audit.py"))
            .args(["--worklist", self.dir.join("work.json").to_str().unwrap()])
            .args(["--state", self.dir.join("state").to_str().unwrap()])
            .output()
            .unwrap()
    }
}

#[cfg(unix)]
impl Drop for Server {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
        let _ = std::fs::remove_dir_all(&self.dir);
    }
}

#[cfg(unix)]
/// Every field of base 10 under (0, 1, 0) and of base 20 under (2, 3, 2).
fn e2e_work() -> Vec<CoordClaim> {
    let mut w = small_claims(10, (0, 1, 0), &(0..10).collect::<Vec<_>>());
    w.extend(small_claims(20, (2, 3, 2), &(0..20).collect::<Vec<_>>()));
    w
}

#[cfg(unix)]
#[test]
fn end_to_end_against_the_development_server() {
    let rt = runtime();
    let work = e2e_work();
    let Some(srv) = Server::start("normal", &work, &[]) else {
        return;
    };
    let api = HttpApi::new(&srv.base, 3).unwrap();
    let mut s = CpuSearch::default();
    let sum = run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).unwrap();
    assert_eq!(sum.searched, 30);
    assert_eq!(sum.replies, vec![ReplyStatus::Canon; 30]);
    let st = srv.status(&rt);
    assert_eq!(
        (st["searched"].as_u64(), st["claimed"].as_u64()),
        (Some(30), Some(30)),
        "{st}"
    );
    let audit = srv.audit();
    assert!(
        audit.status.success(),
        "the audit of the state: {}{}",
        String::from_utf8_lossy(&audit.stdout),
        String::from_utf8_lossy(&audit.stderr)
    );
    // the same submission again: already recorded, under its first id
    let claims = std::fs::read_to_string(srv.dir.join("state/claims.jsonl")).unwrap();
    let first: Value = serde_json::from_str(claims.lines().next().unwrap()).unwrap();
    let subs = std::fs::read_to_string(srv.dir.join("state/submissions.jsonl")).unwrap();
    let rec: Value = serde_json::from_str(subs.lines().next().unwrap()).unwrap();
    assert_eq!(rec["claim_id"], first["claim_id"]);
    let body: Submission = serde_json::from_value(rec["submission"].clone()).unwrap();
    let again = rt
        .block_on(submit_midout_async(&api.http, &api.api_base, &body, 1))
        .unwrap();
    assert_eq!(again.status, ReplyStatus::AlreadyRecorded);
    assert_eq!(Some(again.submission_id), rec["submission_id"].as_u64());
    // the same claim with another result: 409, and the client stops on it
    let mut other = body.clone();
    other.survivors += 1;
    let e = rt
        .block_on(submit_midout_async(&api.http, &api.api_base, &other, 1))
        .unwrap_err();
    assert!(e.to_string().contains("409"), "{e:#}");
    // nothing claimable: a run without --repeat says so and succeeds
    let sum = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(false),
        &ok,
    )
    .unwrap();
    assert_eq!(sum, Summary::default());
}

#[cfg(unix)]
#[test]
fn end_to_end_a_lost_reply_is_already_recorded() {
    let rt = runtime();
    let work = small_claims(20, (2, 3, 2), &[4, 5]);
    let Some(srv) = Server::start("lost", &work, &["--drop-replies", "1"]) else {
        return;
    };
    let api = HttpApi::new(&srv.base, 3).unwrap();
    let sum = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(true),
        &ok,
    )
    .unwrap();
    assert_eq!(sum.searched, 2);
    assert_eq!(
        sum.replies,
        vec![ReplyStatus::AlreadyRecorded, ReplyStatus::Canon]
    );
    assert_eq!(srv.status(&rt)["submissions"].as_u64(), Some(2));
    assert!(srv.audit().status.success());
}

#[cfg(unix)]
#[test]
fn end_to_end_a_422_stops_the_client() {
    let rt = runtime();
    let work = small_claims(20, (2, 3, 2), &[1, 2, 3]);
    let Some(srv) = Server::start("422", &work, &[]) else {
        return;
    };
    let api = HttpApi::new(&srv.base, 3).unwrap();
    let mut s = CpuSearch {
        tamper: true,
        ..Default::default()
    };
    let e = run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).unwrap_err();
    let msg = format!("{e:#}");
    assert!(msg.contains("422") && msg.contains("slices"), "{msg}");
    assert_eq!(srv.status(&rt)["submissions"].as_u64(), Some(0));
    assert!(
        s.done <= 2,
        "the client went on searching after the refusal"
    );
}

#[cfg(unix)]
#[test]
fn end_to_end_a_failed_search_submits_nothing() {
    let rt = runtime();
    let work = small_claims(20, (2, 3, 2), &[7, 8, 9]);
    let Some(srv) = Server::start("fail", &work, &[]) else {
        return;
    };
    let api = HttpApi::new(&srv.base, 3).unwrap();
    let mut s = CpuSearch {
        fail_on: Some(1),
        ..Default::default()
    };
    assert!(run_loop(rt.handle(), &api, &mut s, &cfg(true), &ok).is_err());
    let st = srv.status(&rt);
    assert_eq!(st["submissions"].as_u64(), Some(0), "{st}");
    assert_eq!(s.done, 1);
}

#[test]
fn a_server_without_the_endpoint_is_one_clear_error() {
    let rt = runtime();
    // the development server answers 404 to every path but its own; a 404 on the claim path is what a server
    // without the endpoint answers
    let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let base = format!("http://{}", l.local_addr().unwrap());
    std::thread::spawn(move || {
        use std::io::{Read, Write};
        let (mut s, _) = l.accept().unwrap();
        let mut buf = [0u8; 4096];
        let _ = s.read(&mut buf);
        let _ = s.write_all(
            b"HTTP/1.1 404 Not Found\r\nContent-Length: 9\r\nConnection: close\r\n\r\nNot Found",
        );
    });
    let api = HttpApi::new(&base, 3).unwrap();
    let e = run_loop(
        rt.handle(),
        &api,
        &mut CpuSearch::default(),
        &cfg(true),
        &ok,
    )
    .unwrap_err();
    assert!(
        e.to_string().contains("does not offer middle-out fields"),
        "{e:#}"
    );
}

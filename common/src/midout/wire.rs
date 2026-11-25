//! The wire of the middle-out mode (`nice_client midout`): two endpoints of
//! their own, beside production's `/claim/{detailed,niceonly}` and `/submit`,
//! as the server proposal for the mode has them (not yet built on the
//! server; `scripts/midout_coordinator.py` serves them for development).
//! Every path, key and status the mode speaks is named here, and only here.
//!
//! - **Claim**: `GET /claim/midout` ([`CLAIM_PATH`]). `200` with a
//!   [`CoordClaim`]: `claim_id`, `base`, `coordinate` (an id
//!   `midout:K0,K1,Q0` naming the coordinate's digit positions,
//!   [`coordinate_id`]; `midout::coord`: digits `[K0, K1)` go on top of v, a
//!   field fixes digits `[Q0, K1)`), `range_start`/`range_end` =
//!   `v_start`/`v_start + v_size` in that coordinate, and `range_size` = the
//!   field's count of `n` (`Coord::n_count`), all as JSON numbers. `204`:
//!   nothing claimable now. `503`: the server cannot serve (retried). Any
//!   other status is an error; `404` means the server does not offer
//!   middle-out fields ([`claim_answer`]).
//! - **Submit**: `POST /submit/midout` ([`SUBMIT_PATH`]) with a
//!   [`Submission`]: the claim id, the user, the field the client searched,
//!   repeated by value ([`FieldId`]), the nice numbers, the join's `shape`
//!   and its three counters, and telemetry. Integers that can pass 2^64
//!   (`v_start`, `v_size`, `range_size`, the nice numbers) are decimal
//!   strings. The reply is a [`Reply`]: `{"submission_id": N, "status":
//!   "canon" | "check" | "already_recorded"}`; `already_recorded` is the
//!   answer to a resubmission of the same body under the same claim (a lost
//!   reply) and counts as success. `400`/`413`: a body the server cannot
//!   take; `404`: an unknown claim; `409`: the same claim submitted before
//!   with another body; `422`: a body that is not a search of the claim's
//!   field (another field, a number outside the field or not nice, a wrong
//!   slice count). Each of those stops the client with the server's message
//!   ([`submit_answer`]): it means the client and the server disagree about
//!   a field, and retrying cannot help. `5xx` and network errors are retried.
//!
//! A claim that carries the `coordinate` key is a field of a coordinate
//! space: every route that searches ranges of `n` must refuse it
//! ([`refuse_coordinate_space`], called by the client's ordinary claim).

use anyhow::{Result, anyhow, bail};
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use serde_json::Value;

/// The claim key that marks a field as a range of a coordinate, not of `n`.
pub const COORDINATE_KEY: &str = "coordinate";
/// The family of the middle-out coordinate ids: an id is `midout:K0,K1,Q0`
/// ([`coordinate_id`]).
pub const MIDOUT: &str = "midout";
/// The middle-out claim path (relative to the API address).
pub const CLAIM_PATH: &str = "/claim/midout";
/// The middle-out submit path (relative to the API address).
pub const SUBMIT_PATH: &str = "/submit/midout";
/// The telemetry route name of a middle-out submission.
pub const ROUTE: &str = "midout";
/// The largest telemetry the server takes (serialized, in bytes); larger is
/// refused with 413, not dropped.
pub const TELEMETRY_MAX_BYTES: usize = 16 * 1024;

/// A middle-out claim (`GET /claim/midout`, 200).
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct CoordClaim {
    pub claim_id: u128,
    pub base: u32,
    /// `v_start`.
    pub range_start: u128,
    /// `v_start + v_size`.
    pub range_end: u128,
    /// The `n` the field holds.
    pub range_size: u128,
    pub coordinate: String,
}

/// A field named by value, as a submission repeats it: the server compares
/// it with the claim's row.
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct FieldId {
    pub base: u32,
    pub coordinate: String,
    #[serde(with = "dec")]
    pub v_start: u128,
    #[serde(with = "dec")]
    pub v_size: u128,
    /// The `n` the field holds (`n_count`).
    #[serde(with = "dec")]
    pub range_size: u128,
}

impl FieldId {
    /// The field a claim hands out, by value.
    ///
    /// # Errors
    /// `range_end < range_start`.
    pub fn of_claim(c: &CoordClaim) -> Result<Self> {
        let v_size = c
            .range_end
            .checked_sub(c.range_start)
            .ok_or_else(|| anyhow!("middle-out: claim {}: range_end < range_start", c.claim_id))?;
        Ok(Self {
            base: c.base,
            coordinate: c.coordinate.clone(),
            v_start: c.range_start,
            v_size,
            range_size: c.range_size,
        })
    }
}

/// A middle-out submission (`POST /submit/midout`).
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Submission {
    pub claim_id: u128,
    pub username: String,
    pub client_version: String,
    pub field: FieldId,
    /// The field's nice numbers, ascending, as decimal strings.
    #[serde(with = "dec_vec")]
    pub nice_numbers: Vec<u128>,
    /// The join's shape `f0,k` (`Shape`): the counters are properties of
    /// (shape, field).
    pub shape: String,
    pub survivors: u64,
    pub checked: u64,
    pub slices: u64,
    pub telemetry: Value,
}

/// What the server recorded a submission as.
#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ReplyStatus {
    /// The field's first accepted search.
    Canon,
    /// A further search of a field already searched (compared with the canon).
    Check,
    /// This claim's submission, recorded before (a resubmission after a lost reply).
    AlreadyRecorded,
}

/// The reply to an accepted submission (`POST /submit/midout`, 200).
#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
pub struct Reply {
    pub submission_id: u64,
    pub status: ReplyStatus,
}

/// What a claim request came back with.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ClaimAnswer {
    /// A field to search.
    Field(CoordClaim),
    /// Nothing claimable now (204).
    Empty,
}

/// The meaning of a claim answer that was not retried (any status but a
/// 5xx): the claim, "nothing claimable", or why the client stops.
///
/// # Errors
/// 404 (the server has no middle-out endpoint), any other status but 200
/// and 204, or a 200 body that is not a claim.
pub fn claim_answer(status: u16, body: &[u8]) -> Result<ClaimAnswer> {
    match status {
        200 => serde_json::from_slice(body)
            .map(ClaimAnswer::Field)
            .map_err(|e| {
                anyhow!(
                    "middle-out: the claim is not a middle-out claim ({e}): {}",
                    String::from_utf8_lossy(body)
                )
            }),
        204 => Ok(ClaimAnswer::Empty),
        404 => bail!(
            "middle-out: this server does not offer middle-out fields (GET {CLAIM_PATH} answered 404)"
        ),
        s => bail!(
            "middle-out: the claim was refused: {s} {}",
            String::from_utf8_lossy(body)
        ),
    }
}

/// The meaning of a submit answer that was not retried (any status but a
/// 5xx): the reply, or why the client stops.
///
/// # Errors
/// Any status but 200 (each with the server's message), or a 200 body that
/// is not a reply.
pub fn submit_answer(status: u16, body: &[u8], claim_id: u128) -> Result<Reply> {
    let msg = String::from_utf8_lossy(body);
    match status {
        200 => serde_json::from_slice(body).map_err(|e| {
            anyhow!("middle-out: claim {claim_id}: the server's reply is not a submission reply ({e}): {msg}")
        }),
        409 | 422 => bail!(
            "middle-out: claim {claim_id}: the server refused the submission ({status}: {msg}); this client and \
             the server disagree about the field, so the client stops"
        ),
        404 => bail!("middle-out: claim {claim_id}: the server does not know this claim (404: {msg})"),
        400 | 413 => bail!("middle-out: claim {claim_id}: the server cannot take this body ({status}: {msg})"),
        s => bail!("middle-out: claim {claim_id}: submission refused ({s}: {msg})"),
    }
}

/// `u128` as a decimal string (and only a string).
mod dec {
    use super::{Deserialize, Deserializer, Serializer};

    pub fn serialize<S: Serializer>(x: &u128, s: S) -> Result<S::Ok, S::Error> {
        s.serialize_str(&x.to_string())
    }

    pub fn deserialize<'de, D: Deserializer<'de>>(d: D) -> Result<u128, D::Error> {
        let s = String::deserialize(d)?;
        parse(&s).map_err(serde::de::Error::custom)
    }

    /// A canonical decimal: digits only, no sign, no leading zero.
    pub fn parse(s: &str) -> Result<u128, String> {
        let canonical = !s.is_empty()
            && s.bytes().all(|c| c.is_ascii_digit())
            && (s == "0" || !s.starts_with('0'));
        if !canonical {
            return Err(format!("{s:?} is not a decimal integer"));
        }
        s.parse().map_err(|e| format!("{s:?}: {e}"))
    }
}

/// `Vec<u128>` as a list of decimal strings.
mod dec_vec {
    use super::{Deserialize, Deserializer, Serialize, Serializer};

    pub fn serialize<S: Serializer>(v: &[u128], s: S) -> Result<S::Ok, S::Error> {
        v.iter()
            .map(ToString::to_string)
            .collect::<Vec<_>>()
            .serialize(s)
    }

    pub fn deserialize<'de, D: Deserializer<'de>>(d: D) -> Result<Vec<u128>, D::Error> {
        Vec::<String>::deserialize(d)?
            .iter()
            .map(|s| super::dec::parse(s).map_err(serde::de::Error::custom))
            .collect()
    }
}

/// The id of the middle-out coordinate with digit positions
/// `(k0, k1, q0)`: `midout:k0,k1,q0`.
#[must_use]
pub fn coordinate_id(k0: u32, k1: u32, q0: u32) -> String {
    format!("{MIDOUT}:{k0},{k1},{q0}")
}

/// The digit positions `(k0, k1, q0)` a middle-out coordinate id names.
///
/// # Errors
/// Not an id of the form `midout:K0,K1,Q0`.
pub fn parse_coordinate_id(id: &str) -> Result<(u32, u32, u32)> {
    let parsed = id
        .strip_prefix(MIDOUT)
        .and_then(|r| r.strip_prefix(':'))
        .and_then(|r| {
            let v: Vec<u32> = r
                .split(',')
                .map(|x| x.parse().ok())
                .collect::<Option<_>>()?;
            (v.len() == 3).then(|| (v[0], v[1], v[2]))
        });
    match parsed {
        Some(d) if coordinate_id(d.0, d.1, d.2) == id => Ok(d),
        _ => bail!("middle-out: '{id}' is not a middle-out coordinate id (midout:K0,K1,Q0)"),
    }
}

/// The coordinate a claim body names, if any (`None` when the key is
/// absent or null).
///
/// # Errors
/// A body that is not a JSON object.
pub fn claim_coordinate(body: &[u8]) -> Result<Option<String>> {
    #[derive(Deserialize)]
    struct Marker {
        #[serde(default)]
        coordinate: Option<serde_json::Value>,
    }
    let m: Marker = serde_json::from_slice(body)?;
    Ok(match m.coordinate {
        None | Some(serde_json::Value::Null) => None,
        Some(serde_json::Value::String(s)) => Some(s),
        Some(other) => Some(other.to_string()),
    })
}

/// The guard of every route that searches ranges of `n`: a claim marked as
/// a field of a coordinate is refused (searching its `range_start..range_end`
/// as `n` would search the wrong numbers and call the field done). A body
/// that is not a JSON object passes here and fails its own parse.
///
/// # Errors
/// The claim carries [`COORDINATE_KEY`].
pub fn refuse_coordinate_space(body: &[u8]) -> Result<()> {
    if let Ok(Some(c)) = claim_coordinate(body) {
        bail!(
            "refusing a field of the '{c}' coordinate: this route searches ranges of n, and the field's \
             range is a range of a coordinate (only the midout mode may search it)"
        );
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The proposal's claim example, verbatim.
    const PROPOSAL_CLAIM: &str = r#"{"claim_id": 1000000000000417, "base": 64, "coordinate": "midout:4,8,5", "range_start": 37778931862957161709568,
 "range_end": 37779075978145237565440, "range_size": 144115188075855872}"#;

    /// The proposal's submission example, verbatim.
    const PROPOSAL_SUBMIT: &str = r#"{"claim_id": 1000000000000417, "username": "...", "client_version": "3.5.0",
 "field": {"base": 64, "coordinate": "midout:4,8,5", "v_start": "37778931862957161709568",
           "v_size": "144115188075855872", "range_size": "144115188075855872"},
 "nice_numbers": [], "shape": "4,10", "survivors": 0, "checked": 0, "slices": 4096, "telemetry": {}}"#;

    #[test]
    fn the_proposal_examples_read() {
        let c: CoordClaim = serde_json::from_str(PROPOSAL_CLAIM).unwrap();
        assert_eq!(c.claim_id, 1_000_000_000_000_417);
        assert_eq!((c.base, c.coordinate.as_str()), (64, "midout:4,8,5"));
        assert_eq!(c.range_end - c.range_start, 1u128 << 57);
        assert_eq!(c.range_size, 1u128 << 57);
        // the claim's field is one quantum of base 64's default coordinate
        let coord = crate::midout::Coord::for_base(64).unwrap();
        assert_eq!(coord.quantum(), 1u128 << 57);
        assert!(coord.field_digits(c.range_start, 1 << 57).is_ok());
        let f = FieldId::of_claim(&c).unwrap();

        let s: Submission = serde_json::from_str(PROPOSAL_SUBMIT).unwrap();
        assert_eq!(s.claim_id, c.claim_id);
        assert_eq!(s.field, f, "the submission repeats the claim's field");
        assert_eq!(
            (s.shape.as_str(), s.survivors, s.checked, s.slices),
            ("4,10", 0, 0, 4096)
        );
        assert_eq!(s.nice_numbers, Vec::<u128>::new());
        assert_eq!(s.telemetry, serde_json::json!({}));
        // what the client writes reads back the same, and big integers stay strings
        let back = serde_json::to_value(&s).unwrap();
        assert_eq!(
            back,
            serde_json::from_str::<Value>(PROPOSAL_SUBMIT).unwrap()
        );
        assert_eq!(serde_json::from_value::<Submission>(back).unwrap(), s);
    }

    #[test]
    fn big_integers_are_canonical_decimal_strings() {
        let mut body: Value = serde_json::from_str(PROPOSAL_SUBMIT).unwrap();
        body["nice_numbers"] = serde_json::json!(["340282366920938463463374607431768211455", "69"]);
        let sub: Submission = serde_json::from_value(body.clone()).unwrap();
        assert_eq!(sub.nice_numbers, vec![u128::MAX, 69]);
        let written = serde_json::to_value(&sub).unwrap();
        assert_eq!(written["nice_numbers"], body["nice_numbers"]);
        assert_eq!(written["field"]["v_start"], "37778931862957161709568");
        for bad in [
            serde_json::json!(37_778_931_862_957_161_709_568_f64),
            serde_json::json!(5),
            serde_json::json!("-1"),
            serde_json::json!("+5"),
            serde_json::json!("012"),
            serde_json::json!("1e3"),
            serde_json::json!(""),
            serde_json::json!(" 5"),
            serde_json::json!("340282366920938463463374607431768211456"),
        ] {
            let mut x = body.clone();
            x["field"]["v_start"] = bad.clone();
            assert!(serde_json::from_value::<Submission>(x).is_err(), "{bad}");
            let mut y = body.clone();
            y["nice_numbers"] = serde_json::json!([bad.clone()]);
            assert!(serde_json::from_value::<Submission>(y).is_err(), "{bad}");
        }
        assert!(dec::parse("0").is_ok());
    }

    #[test]
    fn replies() {
        for (body, status) in [
            (
                r#"{"submission_id": 7, "status": "canon"}"#,
                ReplyStatus::Canon,
            ),
            (
                r#"{"submission_id": 8, "status": "check"}"#,
                ReplyStatus::Check,
            ),
            (
                r#"{"submission_id": 7, "status": "already_recorded"}"#,
                ReplyStatus::AlreadyRecorded,
            ),
        ] {
            let r = submit_answer(200, body.as_bytes(), 5).unwrap();
            assert_eq!(r.status, status);
        }
        for bad in [
            r#"{"submission_id": 7, "status": "recorded"}"#,
            r#"{"status": "canon"}"#,
            "recorded",
            "",
        ] {
            assert!(submit_answer(200, bad.as_bytes(), 5).is_err(), "{bad}");
        }
        for (code, word) in [
            (409, "disagree"),
            (422, "disagree"),
            (404, "does not know"),
            (400, "cannot take"),
            (413, "cannot take"),
            (403, "refused"),
        ] {
            let e = submit_answer(code, b"the reason", 5)
                .unwrap_err()
                .to_string();
            assert!(
                e.contains(word) && e.contains("the reason") && e.contains("claim 5"),
                "{code}: {e}"
            );
        }
    }

    #[test]
    fn claim_answers() {
        match claim_answer(200, PROPOSAL_CLAIM.as_bytes()).unwrap() {
            ClaimAnswer::Field(c) => assert_eq!(c.base, 64),
            ClaimAnswer::Empty => panic!("a claim"),
        }
        assert_eq!(claim_answer(204, b"").unwrap(), ClaimAnswer::Empty);
        let e = claim_answer(404, b"Not Found").unwrap_err().to_string();
        assert!(e.contains("does not offer middle-out fields"), "{e}");
        assert!(claim_answer(200, br#"{"claim_id": 5}"#).is_err());
        assert!(claim_answer(400, b"no").is_err());
        // a production nice-only claim is not a middle-out claim
        let plain = br#"{"claim_id":5,"base":40,"range_start":1,"range_end":9,"range_size":8}"#;
        assert!(claim_answer(200, plain).is_err());
    }

    #[test]
    fn coordinate_ids() {
        assert_eq!(coordinate_id(4, 9, 6), "midout:4,9,6");
        assert_eq!(parse_coordinate_id("midout:4,9,6").unwrap(), (4, 9, 6));
        assert_eq!(parse_coordinate_id("midout:4,8,5").unwrap(), (4, 8, 5));
        for bad in [
            "midout",
            "midout:",
            "midout:4,9",
            "midout:4,9,6,1",
            "midout:4, 9,6",
            "midout:04,9,6",
            "mo:4,9,6",
            "midout:a,b,c",
            "",
        ] {
            assert!(parse_coordinate_id(bad).is_err(), "{bad:?}");
        }
    }

    #[test]
    fn coordinate_marker() {
        let plain = br#"{"claim_id":5,"base":40,"range_start":1,"range_end":9,"range_size":8}"#;
        assert_eq!(claim_coordinate(plain).unwrap(), None);
        assert!(refuse_coordinate_space(plain).is_ok());
        let null = br#"{"claim_id":5,"base":40,"range_start":1,"range_end":9,"range_size":8,"coordinate":null}"#;
        assert!(refuse_coordinate_space(null).is_ok());
        let marked = br#"{"claim_id":7,"base":64,"range_start":37778931862957161709568,"range_end":37779075978145237565440,"range_size":144115188075855872,"coordinate":"midout"}"#;
        assert_eq!(claim_coordinate(marked).unwrap().as_deref(), Some(MIDOUT));
        let marked_id = br#"{"claim_id":7,"base":64,"range_start":1,"range_end":2,"range_size":1,"coordinate":"midout:4,9,6"}"#;
        assert!(refuse_coordinate_space(marked_id).is_err());
        let e = refuse_coordinate_space(marked).unwrap_err().to_string();
        assert!(e.contains("coordinate"), "{e}");
        // any value of the key is refused, not only the values known now
        let other = br#"{"claim_id":7,"base":64,"range_start":1,"range_end":2,"range_size":1,"coordinate":2}"#;
        assert!(refuse_coordinate_space(other).is_err());
        // not an object: left to the caller's own parse
        assert!(refuse_coordinate_space(b"\"no field\"").is_ok());
        let c: CoordClaim = serde_json::from_slice(marked).unwrap();
        assert!(
            parse_coordinate_id(&c.coordinate).is_err(),
            "a bare family name is not an id"
        );
        assert_eq!(c.range_end - c.range_start, 1u128 << 57);
    }
}

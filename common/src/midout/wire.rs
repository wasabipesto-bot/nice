//! The wire additions of the middle-out route (development; no server
//! speaks them). Everything a claim or a submission of a field of the new
//! kind adds to production's `/claim/niceonly` and `/submit` format is
//! named here, and only here:
//!
//! - **Claim**: `GET /claim/niceonly?coordinate=midout` ([`CLAIM_PATH`]).
//!   The body is production's `DataToClient` plus one key,
//!   `"coordinate": "midout"` ([`COORDINATE_KEY`], [`MIDOUT`]):
//!   `range_start`/`range_end` are `v_start`/`v_start + v_size` in the base's
//!   coordinate (`midout::coord`), and `range_size` is the field's count of
//!   `n` (`Coord::n_count`, what the server sums). `204 No Content`: no
//!   field left.
//! - **Submit**: `POST /submit` with production's `DataToServer`, unchanged;
//!   the telemetry's `pipeline.route` is `"midout"` ([`ROUTE`]).
//!
//! A claim that carries the key is a field of a coordinate space: every
//! route that searches ranges of `n` must refuse it
//! ([`refuse_coordinate_space`], called by the client's ordinary claim).

use anyhow::{Result, bail};
use serde::{Deserialize, Serialize};

/// The claim key that marks a field as a range of a coordinate, not of `n`.
pub const COORDINATE_KEY: &str = "coordinate";
/// The value of [`COORDINATE_KEY`] for the middle-out coordinate of the
/// claim's base.
pub const MIDOUT: &str = "midout";
/// The middle-out claim path (relative to the API address).
pub const CLAIM_PATH: &str = "/claim/niceonly?coordinate=midout";
/// The telemetry route name of a middle-out submission.
pub const ROUTE: &str = "midout";
/// The production API's domain: the middle-out route refuses it and every
/// host under it.
pub const PRODUCTION_DOMAIN: &str = "nicenumbers.net";

/// A middle-out claim: production's claim and the coordinate key.
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
             range is a range of a coordinate (only the middle-out route may search it)"
        );
    }
    Ok(())
}

/// The host of an `http://` or `https://` address, lower case, without a
/// port, user or trailing dot.
fn url_host(url: &str) -> Option<String> {
    let lower = url.trim().to_ascii_lowercase();
    let rest = lower
        .strip_prefix("http://")
        .or_else(|| lower.strip_prefix("https://"))?;
    let authority = rest.split(['/', '?', '#']).next()?;
    let hostport = authority.rsplit('@').next()?;
    let host = if let Some(v6) = hostport.strip_prefix('[') {
        v6.split(']').next()?.to_string()
    } else {
        hostport.split(':').next()?.to_string()
    };
    let host = host.trim_end_matches('.').to_string();
    (!host.is_empty()).then_some(host)
}

/// The middle-out route's first guard: the coordinator's address must be an
/// explicit `http(s)://host[:port]` that is not the production API
/// ([`PRODUCTION_DOMAIN`] or any host under it).
///
/// # Errors
/// No host, another scheme, or a production host.
pub fn check_coordinator_url(url: &str) -> Result<()> {
    let Some(host) = url_host(url) else {
        bail!("middle-out: the coordinator address '{url}' is not an http(s)://host[:port] address");
    };
    if host == PRODUCTION_DOMAIN || host.ends_with(&format!(".{PRODUCTION_DOMAIN}")) {
        bail!(
            "middle-out: refusing the production API ({host}): this route claims only from a local coordinator"
        );
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn production_hosts_are_refused() {
        for u in [
            "https://api.nicenumbers.net",
            "https://api.nicenumbers.net/",
            "HTTPS://API.NICENUMBERS.NET.",
            "http://nicenumbers.net:8080/x",
            "http://user@www.nicenumbers.net",
            "https://data.nicenumbers.net/claim",
            " https://api.nicenumbers.net ",
        ] {
            assert!(check_coordinator_url(u).is_err(), "{u} must be refused");
        }
        for u in ["", "api.nicenumbers.net", "ftp://127.0.0.1", "http://", "http:///x"] {
            assert!(check_coordinator_url(u).is_err(), "{u:?} is not an address");
        }
        for u in [
            "http://127.0.0.1:8470",
            "http://[::1]:8470/",
            "http://localhost:8470",
            "http://notnicenumbers.net",
            "https://nicenumbers.network",
        ] {
            assert!(check_coordinator_url(u).is_ok(), "{u} must be allowed");
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
        let e = refuse_coordinate_space(marked).unwrap_err().to_string();
        assert!(e.contains("coordinate"), "{e}");
        // any value of the key is refused, not only today's
        let other = br#"{"claim_id":7,"base":64,"range_start":1,"range_end":2,"range_size":1,"coordinate":2}"#;
        assert!(refuse_coordinate_space(other).is_err());
        // not an object: left to the caller's own parse
        assert!(refuse_coordinate_space(b"\"no field\"").is_ok());
        let c: CoordClaim = serde_json::from_slice(marked).unwrap();
        assert_eq!(c.range_end - c.range_start, 1u128 << 57);
    }
}

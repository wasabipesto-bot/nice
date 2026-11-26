//! Asynchronous client-server connection utilities with proper error handling.

use crate::{DataToClient, DataToServer, SearchMode, ValidationData};
use anyhow::{Context, Result, anyhow};
use log::warn;
use std::time::Duration;

// Reexport tokio and reqwest for async functions
pub use reqwest::Client;
pub use tokio;

/// Helper function to determine if an error is retry-able
/// - `is_timeout()` catches typical network timeouts
/// - `is_connect()` catches typical connection failures
/// - `is_request()` catches DNS resolution failures and other transient request errors
fn is_retryable_error(e: &reqwest::Error) -> bool {
    e.is_timeout() || e.is_connect() || e.is_request()
}

/// Helper function to classify reqwest error types
fn error_type_str(e: &reqwest::Error) -> &'static str {
    if e.is_timeout() {
        "timeout"
    } else if e.is_connect() {
        "connection"
    } else if e.is_request() {
        "request/DNS"
    } else if e.is_body() {
        "body"
    } else if e.is_decode() {
        "decode"
    } else {
        "unknown"
    }
}

/// Generic retry logic for async HTTP requests with exponential backoff.
/// Handles both network errors and 5xx server errors.
async fn retry_request_async<F, Fut, P, FutP, T>(
    request_fn: F,
    process_response: P,
    max_retries: u32,
) -> Result<T>
where
    F: Fn() -> Fut,
    Fut: std::future::Future<Output = Result<reqwest::Response, reqwest::Error>>,
    P: Fn(reqwest::Response) -> FutP,
    FutP: std::future::Future<Output = Result<T>>,
{
    let mut attempts = 0;

    loop {
        attempts += 1;

        match request_fn().await {
            Ok(response) => {
                // Check if it's a 5xx server error
                if response.status().is_server_error() {
                    if attempts < max_retries {
                        let sleep_secs = 2_u64.pow(attempts.saturating_sub(1));
                        let status = response.status();
                        let error_msg = response.text().await.unwrap_or_default();
                        warn!(
                            "Server error ({status} {error_msg}), retrying in {sleep_secs} seconds... (attempt {attempts}/{max_retries})"
                        );
                        tokio::time::sleep(Duration::from_secs(sleep_secs)).await;
                        continue;
                    }
                    let status = response.status();
                    return Err(anyhow!("Server error after {attempts} attempts: {status}"));
                }

                // Process the successful response
                return process_response(response).await;
            }
            Err(e) => {
                if is_retryable_error(&e) && attempts < max_retries {
                    let sleep_secs = 2_u64.pow(attempts.saturating_sub(1));
                    warn!(
                        "Network error ({}), retrying in {} seconds... (attempt {}/{}): {}",
                        error_type_str(&e),
                        sleep_secs,
                        attempts,
                        max_retries,
                        e
                    );
                    tokio::time::sleep(Duration::from_secs(sleep_secs)).await;
                    continue;
                }
                return Err(anyhow!(
                    "Network error ({}) after {attempts} attempts: {e}",
                    error_type_str(&e)
                ));
            }
        }
    }
}

/// Async version: Request a field from the server and returns the deserialized data.
/// Retries for 5xx errors or network timeouts.
///
/// # Errors
///
/// Returns an error if:
/// - The server returns an error after all retry attempts
/// - A network error occurs after all retry attempts
/// - The response cannot be deserialized
pub async fn get_field_from_server_async(
    client: &reqwest::Client,
    mode: &SearchMode,
    api_base: &str,
    max_retries: u32,
) -> Result<DataToClient> {
    let url = match mode {
        SearchMode::Detailed => format!("{api_base}/claim/detailed"),
        SearchMode::Niceonly => format!("{api_base}/claim/niceonly"),
    };

    retry_request_async(
        || async { client.get(&url).send().await },
        |response| async move {
            let body = response
                .bytes()
                .await
                .context("Failed to read server response")?;
            field_of_claim_body(&body)
        },
        max_retries,
    )
    .await
}

/// The field of an ordinary claim's answer (both modes). A field of a
/// coordinate space (the middle-out route's) is not a range of n: no route
/// that claims here may search it, so it is refused.
fn field_of_claim_body(body: &[u8]) -> Result<DataToClient> {
    crate::midout::wire::refuse_coordinate_space(body)?;
    serde_json::from_slice::<DataToClient>(body).context("Failed to deserialize server response")
}

/// Async version: Submit field results to the server. Returns an error if there is a problem.
/// Retries for 5xx errors or network timeouts.
///
/// # Errors
///
/// Returns an error if:
/// - The server returns an error (4xx, 5xx) after all retry attempts
/// - A network error occurs after all retry attempts
/// - The response indicates a failure
pub async fn submit_field_to_server_async(
    client: &reqwest::Client,
    api_base: &str,
    submit_data: DataToServer,
    max_retries: u32,
) -> Result<reqwest::Response> {
    let url = format!("{api_base}/submit");

    retry_request_async(
        || async { client.post(&url).json(&submit_data).send().await },
        |response| async move {
            // Check for other client/server errors (4xx, etc.)
            if !response.status().is_success() {
                let status = response.status();
                let msg = response
                    .text()
                    .await
                    .unwrap_or_else(|_| "Unknown error".to_string());
                return Err(anyhow!("Server returned an error ({status}): {msg}"));
            }
            Ok(response)
        },
        max_retries,
    )
    .await
}

/// Async version: Request validation data from the server for a specific claim.
/// Returns the deserialized `ValidationData` which includes the expected results.
/// Retries for 5xx errors or network timeouts.
///
/// # Errors
///
/// Returns an error if:
/// - The server returns an error after all retry attempts
/// - A network error occurs after all retry attempts
/// - The response cannot be deserialized
pub async fn get_validation_data_from_server_async(
    client: &reqwest::Client,
    api_base: &str,
    max_retries: u32,
) -> Result<ValidationData> {
    let url = format!("{api_base}/claim/validate");

    retry_request_async(
        || async { client.get(&url).send().await },
        |response| async move {
            response
                .json::<ValidationData>()
                .await
                .context("Failed to deserialize validation response")
        },
        max_retries,
    )
    .await
}

/// Claim a middle-out field (`GET /claim/midout`, `midout::wire`): the
/// claim, or [`ClaimAnswer::Empty`](crate::midout::wire::ClaimAnswer) when
/// nothing is claimable. Retries 5xx and network errors.
///
/// # Errors
/// After all retries; a 404 (the server offers no middle-out fields); any
/// other refusal; a body that is not a claim.
pub async fn claim_midout_async(
    client: &reqwest::Client,
    api_base: &str,
    max_retries: u32,
) -> Result<crate::midout::wire::ClaimAnswer> {
    use crate::midout::wire;
    let url = format!("{}{}", api_base.trim_end_matches('/'), wire::CLAIM_PATH);
    retry_request_async(
        || async { client.get(&url).send().await },
        |response| async move {
            let status = response.status().as_u16();
            let body = response
                .bytes()
                .await
                .context("middle-out: failed to read the claim")?;
            wire::claim_answer(status, &body)
        },
        max_retries,
    )
    .await
}

/// Submit a middle-out field (`POST /submit/midout`, `midout::wire`): the
/// server's reply (`already_recorded` included). Retries 5xx and network
/// errors with the same body, so a reply lost after the server recorded it
/// comes back `already_recorded`.
///
/// # Errors
/// After all retries; any refusal (409 and 422 included, with the server's
/// message); a reply that does not read.
pub async fn submit_midout_async(
    client: &reqwest::Client,
    api_base: &str,
    submission: &crate::midout::wire::Submission,
    max_retries: u32,
) -> Result<crate::midout::wire::Reply> {
    use crate::midout::wire;
    let url = format!("{}{}", api_base.trim_end_matches('/'), wire::SUBMIT_PATH);
    let claim_id = submission.claim_id;
    retry_request_async(
        || async { client.post(&url).json(submission).send().await },
        |response| async move {
            let status = response.status().as_u16();
            let body = response
                .bytes()
                .await
                .context("middle-out: failed to read the submission reply")?;
            wire::submit_answer(status, &body, claim_id)
        },
        max_retries,
    )
    .await
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The ordinary claim (every route but the middle-out one; both modes read
    /// the answer with [`field_of_claim_body`]) refuses a field marked as a
    /// coordinate space, and still takes a plain one. No socket is needed: the
    /// refusal is in how the answer is read, not in the request.
    #[test]
    fn ordinary_claims_refuse_a_coordinate_field() {
        let marked = br#"{"claim_id":7,"base":64,"range_start":37778931862957161709568,"range_end":37779075978145237565440,"range_size":144115188075855872,"coordinate":"midout"}"#;
        let e = field_of_claim_body(marked).expect_err("a coordinate field must be refused");
        assert!(e.to_string().contains("coordinate"), "{e}");
        let plain =
            br#"{"claim_id":8,"base":40,"range_start":100,"range_end":200,"range_size":100}"#;
        let d = field_of_claim_body(plain).unwrap();
        assert_eq!((d.claim_id, d.base, d.range_size), (8, 40, 100));
    }
}

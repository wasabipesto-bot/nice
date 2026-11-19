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
            // A field of a coordinate space (the middle-out route's) is not a
            // range of n: no route that claims here may search it.
            crate::midout::wire::refuse_coordinate_space(&body)?;
            serde_json::from_slice::<DataToClient>(&body)
                .context("Failed to deserialize server response")
        },
        max_retries,
    )
    .await
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{Read, Write};

    /// Serve `body` once on a loopback port (HTTP/1.1, 200); returns the address.
    fn serve_once(body: &'static str) -> String {
        let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let addr = format!("http://{}", l.local_addr().unwrap());
        std::thread::spawn(move || {
            let (mut s, _) = l.accept().unwrap();
            let mut buf = [0u8; 4096];
            let _ = s.read(&mut buf);
            let r = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            );
            s.write_all(r.as_bytes()).unwrap();
        });
        addr
    }

    /// The ordinary claim (every route but the middle-out one) refuses a field
    /// marked as a coordinate space, in both modes, and still takes a plain one.
    #[tokio::test]
    async fn ordinary_claims_refuse_a_coordinate_field() {
        let client = Client::new();
        let marked = r#"{"claim_id":7,"base":64,"range_start":37778931862957161709568,"range_end":37779075978145237565440,"range_size":144115188075855872,"coordinate":"midout"}"#;
        for mode in [SearchMode::Niceonly, SearchMode::Detailed] {
            let e = get_field_from_server_async(&client, &mode, &serve_once(marked), 1)
                .await
                .expect_err("a coordinate field must be refused");
            assert!(e.to_string().contains("coordinate"), "{e}");
        }
        let plain =
            r#"{"claim_id":8,"base":40,"range_start":100,"range_end":200,"range_size":100}"#;
        let d = get_field_from_server_async(&client, &SearchMode::Niceonly, &serve_once(plain), 1)
            .await
            .unwrap();
        assert_eq!((d.claim_id, d.base, d.range_size), (8, 40, 100));
    }
}

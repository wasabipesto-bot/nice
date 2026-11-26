# Sourced by every research script on mayalaran. Everything of the research agent lives under ~/claude:
# sources, cargo's registry and build output, binaries, runs. Nothing here may reach the production API.
export R=$HOME/claude
export NICE_API_BASE=http://127.0.0.1:9
export CARGO_HOME=$R/cargo-home            # registry and git checkouts inside the folder (the toolchains are rustup's, read only)
export PATH=$HOME/.cargo/bin:/opt/homebrew/bin:$PATH

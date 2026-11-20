set -x
apt-get update -qq && apt-get install -y -qq build-essential pkg-config libssl-dev curl python3 >/dev/null
curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.100.0
. $HOME/.cargo/env
git clone -q https://github.com/wasabipesto-bot/nice.git /w/ceil && cd /w/ceil && git checkout -q c2152084 && git checkout -b exp/mo-ceiling
git clone -q https://github.com/wasabipesto-bot/nice.git /w/mut && cd /w/mut && git checkout -q c2152084
cd /w/ceil && rustup show && echo SETUP_DONE

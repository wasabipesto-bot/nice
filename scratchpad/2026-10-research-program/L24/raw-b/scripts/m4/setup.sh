#!/bin/sh
# Node + Playwright 1.62.0 + Chromium inside $D, nothing outside it.
. "$HOME/claude-exp-2026-11-01-webfd/scripts/env.sh"
set -e
cd "$D"
V=v24.14.1
curl -sSfO "https://nodejs.org/dist/$V/node-$V-darwin-arm64.tar.gz"
curl -sSf "https://nodejs.org/dist/$V/SHASUMS256.txt" | grep " node-$V-darwin-arm64.tar.gz\$" > node.sha
shasum -a 256 -c node.sha
tar xzf "node-$V-darwin-arm64.tar.gz" && mv "node-$V-darwin-arm64" node && rm "node-$V-darwin-arm64.tar.gz"
node --version
cd "$D/harness"
npm i --no-save --no-audit --no-fund --omit=optional --ignore-scripts playwright@1.62.0
npx playwright install --no-shell chromium
ls "$PLAYWRIGHT_BROWSERS_PATH"
echo SETUP_DONE

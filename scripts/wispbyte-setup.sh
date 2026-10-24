#!/usr/bin/env bash
# One-time setup for a Pterodactyl-style Node host (Wispbyte and friends).
# Run from the panel console or over SFTP's terminal:
#   bash scripts/wispbyte-setup.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Node $(node -v)"
major="$(node -p "process.versions.node.split('.')[0]")"
if [ "$major" -lt 22 ]; then
  echo "Node 22.18+ is required. Pick a newer Node image in the panel."
  exit 1
fi

if [ ! -f vendor/pokemon-showdown/package.json ]; then
  echo "==> Fetching the Showdown engine"
  mkdir -p vendor
  git clone --depth 1 https://github.com/smogon/pokemon-showdown \
    vendor/pokemon-showdown
fi

if [ ! -f vendor/pokemon-showdown/dist/sim/index.js ]; then
  echo "==> Building Showdown"
  (
    cd vendor/pokemon-showdown
    # npm 12 blocks dependency install scripts by default. That skips
    # esbuild's postinstall, which downloads the platform binary used by
    # Showdown's build. Install without scripts, then fetch it explicitly.
    npm install --ignore-scripts --no-audit --no-fund
    node node_modules/esbuild/install.js
    node build
  )
fi

echo "==> Installing the game server"
(
  cd server
  # Panels sometimes set NODE_ENV=production; tsx is needed at runtime.
  npm install --include=dev --ignore-scripts --no-audit --no-fund
  # tsx also bundles esbuild; keep it usable on npm 12.
  node node_modules/esbuild/install.js
)

echo
echo "Ready. Set the startup command to:"
echo "  bash scripts/wispbyte-start.sh"
echo "Then open the allocated port in the panel; the app needs that host:port"
echo "as API_BASE_URL."

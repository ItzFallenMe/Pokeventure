#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

node_major="$(node -p "process.versions.node.split('.')[0]")"
if [ "$node_major" -lt 22 ]; then
  echo "Node 22.18+ is required by pokemon-showdown (found $(node -v))."
  echo "Install Node 22, then rerun this script."
  exit 1
fi

echo "==> Showdown engine"
git submodule update --init --recursive
(
  cd vendor/pokemon-showdown
  # npm 12 blocks dependency install scripts by default; esbuild's platform
  # binary has to be fetched before Showdown's build can run.
  npm install --ignore-scripts --no-audit --no-fund
  node node_modules/esbuild/install.js
  node build
)

echo "==> Game server"
(
  cd server
  # Panels sometimes set NODE_ENV=production; tsx is needed at runtime.
  npm install --include=dev --ignore-scripts --no-audit --no-fund
  node node_modules/esbuild/install.js
)

echo "==> Flutter app"
(cd app && flutter pub get)

echo
echo "Ready."
echo "  Server:  cd server && npm start"
echo "  App:     cd app && flutter run"

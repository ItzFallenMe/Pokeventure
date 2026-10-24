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
  npm install --no-audit --no-fund
  node build
)

echo "==> Game server"
(cd server && npm install --no-audit --no-fund)

echo "==> Flutter app"
(cd app && flutter pub get)

echo
echo "Ready."
echo "  Server:  cd server && npm start"
echo "  App:     cd app && flutter run"

#!/usr/bin/env bash
# Startup command for a Pterodactyl-style host:
#   bash scripts/wispbyte-start.sh
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f vendor/pokemon-showdown/dist/sim/index.js ] ||
  [ ! -d server/node_modules ]; then
  bash scripts/wispbyte-setup.sh
fi

echo "Starting Pokéventure on port ${SERVER_PORT:-${PORT:-8787}}"
exec npm start --prefix server

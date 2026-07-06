#!/usr/bin/env bash
# One-command setup + launch for the Ghost ⇄ iMessage bridge.
#
# Usage:
#   bash setup.sh <PROJECT_ID> <PROJECT_SECRET>   # writes .env for you, then starts
#   bash setup.sh                                  # uses an existing .env
#
# Run this ON the Ghost Hermes VM (it needs `hermes` and `node` on PATH).
set -euo pipefail
cd "$(dirname "$0")"

# 1) Credentials -------------------------------------------------------------
if [ "${1:-}" != "" ] && [ "${2:-}" != "" ]; then
  printf 'PROJECT_ID=%s\nPROJECT_SECRET=%s\n' "$1" "$2" > .env
  echo "✓ wrote .env"
fi
if [ ! -f .env ]; then
  echo "✗ No .env found."
  echo "  Run:  bash setup.sh <PROJECT_ID> <PROJECT_SECRET>"
  echo "  or:   cp .env.example .env   then edit it."
  exit 1
fi

# 2) Prerequisites -----------------------------------------------------------
command -v node   >/dev/null || { echo "✗ node not found.";   exit 1; }
command -v npm    >/dev/null || { echo "✗ npm not found.";    exit 1; }
command -v hermes >/dev/null || { echo "✗ 'hermes' not found on PATH — run this on a Ghost Hermes VM."; exit 1; }
echo "✓ node $(node -v), hermes present"

# 3) Install -----------------------------------------------------------------
echo "→ installing dependencies (first run only)..."
npm install --no-fund --no-audit

# 4) (Re)start the bridge, detached so it survives the SSH session -----------
echo "→ starting bridge..."
pkill -f "index.mjs" 2>/dev/null || true
sleep 1
: > bridge.log
setsid bash -c 'node index.mjs >> bridge.log 2>&1' < /dev/null &
sleep 6

echo "===== bridge.log ====="
cat bridge.log
echo "======================"
echo
echo "✓ Bridge running. Text your Photon line to talk to the agent."
echo "  Logs:  tail -f $(pwd)/bridge.log"
echo "  Stop:  bash stop.sh   (or: pkill -f index.mjs)"

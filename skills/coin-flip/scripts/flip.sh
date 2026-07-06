#!/usr/bin/env bash
# coin-flip: flip a fair coin N times (default 1) using the system CSPRNG.
# Usage: bash flip.sh [count]
set -euo pipefail

count="${1:-1}"

# Validate count is a positive integer.
case "$count" in
  ''|*[!0-9]*) echo "ERROR: count must be a positive integer, got '$count'" >&2; exit 1 ;;
esac
[ "$count" -lt 1 ] && { echo "ERROR: count must be >= 1" >&2; exit 1; }

for _ in $(seq 1 "$count"); do
  # Read one unsigned byte from the cryptographic RNG; even -> Heads, odd -> Tails.
  # Unbiased because 256 is even, so the two classes are exactly equal in size.
  byte=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
  if [ $(( byte % 2 )) -eq 0 ]; then
    echo "Heads"
  else
    echo "Tails"
  fi
done

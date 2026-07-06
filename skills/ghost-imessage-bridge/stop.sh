#!/usr/bin/env bash
# Stop the running bridge.
pkill -f "index.mjs" 2>/dev/null && echo "✓ bridge stopped" || echo "(no bridge was running)"

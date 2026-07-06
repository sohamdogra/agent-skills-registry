---
name: coin-flip
runtime: neutral
requires: [terminal]
description: >-
  Flip a fair coin and return Heads or Tails. Use when someone asks you to flip a coin,
  toss a coin, pick heads or tails, or make a quick 50/50 random decision. Runs a bundled
  script that uses a cryptographically-seeded RNG (no API key, no network).
---

# Coin Flip

A trivial utility skill: flip a fair two-sided coin and report the result.

## When to use

When a person asks you to **flip a coin**, **toss a coin**, call **heads or tails**, or
settle a **50/50** decision randomly.

## What to do

Run the bundled script and report its output verbatim:

```bash
bash scripts/flip.sh
```

It prints exactly one line — either `Heads` or `Tails` — chosen with an unbiased 50/50
draw from the system's cryptographic RNG. Relay that result to the person.

## Notes

- Fair by construction: each side has probability 0.5.
- No network, no API key, no dependencies beyond a POSIX shell.
- To flip several times, pass a count: `bash scripts/flip.sh 5`.

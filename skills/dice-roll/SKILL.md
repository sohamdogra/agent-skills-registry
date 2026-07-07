---
name: dice-roll
runtime: neutral
requires: [code_execution]
description: >-
  Roll a fair six-sided die (d6) and report the result (1–6). Use when someone
  asks you to roll a die, roll a d6, "give me a random number 1-6", or wants a
  quick fair random roll. Runs a bundled script — no API key, no dependencies.
---

# Dice Roll (d6)

Rolls a single fair six-sided die and reports the result, a number from **1 to 6**.
Each roll is genuinely random (uses Python's `random`), not recalled or made up.

## When to use

When a person asks you to **roll a die / roll a d6 / pick a random number 1–6**
(e.g. "roll a die", "roll me a d6", "give me a random 1 to 6").

## How to run it

1. Run the script (no arguments needed):

   ```bash
   python3 scripts/roll.py
   ```

2. It prints JSON like `{"sides": 6, "result": 4}`.

3. **Report the result plainly**, e.g.:

   > 🎲 You rolled a **4**.

## Why it's a good registry skill

- **Real work, verifiable:** produces a genuine random roll each time rather than a
  guessed number.
- **Portable:** `requires: [code_execution]` only — runs on any runtime, no deps.
- **No secrets:** pure stdlib, nothing to configure.

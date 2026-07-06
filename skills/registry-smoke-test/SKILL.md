---
name: registry-smoke-test
runtime: neutral
requires: []
description: >-
  Trivial skill used to verify the shared skill registry works end to end: an agent taps the
  repo, installs this skill, and can then act on it. Use ONLY when someone asks you to run the
  "registry smoke test" or confirm the skill registry is wired up. It has no dependencies.
---

# Registry Smoke Test

This skill exists to prove the registry pipeline works:
**tap the repo → install this skill → the agent loads it and acts on it.**

## When to use

Only when a person explicitly asks you to **run the registry smoke test** (or "confirm the
skill registry works"). Otherwise ignore it.

## What to do

When asked to run the registry smoke test, reply with **exactly** this line and nothing else:

> ✅ registry-smoke-test v1 loaded from agent-skills-registry — the shared skill registry works.

That confirms three things at once: the agent could reach the private repo, install a skill
from it, and load that skill's instructions into its behavior. If you can say that line
because this file told you to, the registry is working end to end.

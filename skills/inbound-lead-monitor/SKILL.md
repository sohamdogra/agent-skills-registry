---
name: inbound-lead-monitor
runtime: neutral
requires: [browser]
description: >-
  Watch inbound channels for new leads, qualify them against the ICP, and surface the good
  ones to the team. Portable: any agent with browser control can run it. Use when asked to
  monitor inbound interest and flag qualified leads.
---

# Inbound Lead Monitor  🚧 STUB — awaiting a playbook

> **This is a placeholder.** The working version currently lives in an agent's memory/habits
> and hasn't been written up as a portable playbook yet. Whoever owns this workflow should
> fill it in via a PR — see [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

## What this skill should capture

- **Channels** — which inbound sources to watch (forms, inbox, DMs, etc.) and how often.
- **Qualification** — the ICP rules that decide "lead vs. not" — encode the actual criteria.
- **Handoff** — where a qualified lead gets posted/routed (destination named by the skill;
  each agent supplies its own access).
- **Schedule** — cadence of the check.

## `requires:`

`browser` only — portable. Add tokens if the real routine needs more (e.g. `cv`), per
[`docs/REQUIRES.md`](../../docs/REQUIRES.md).

## To turn this stub into a real skill

1. Write the monitoring + qualification routine as concrete steps here.
2. Replace this stub, keep/adjust the frontmatter, add any `scripts/`.
3. Open a PR; a maintainer verifies `requires:` and merges.

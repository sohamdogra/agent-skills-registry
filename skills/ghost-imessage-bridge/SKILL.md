---
name: ghost-imessage-bridge
runtime: hermes
requires: [hermes, node, photon]
description: >-
  Connect a Ghost/Hermes agent to iMessage via Photon/Spectrum so people can text the
  agent from a normal phone and get replies, with per-contact memory. No Mac and no Hermes
  upgrade required. Use when asked to put a Hermes agent on iMessage / give it a phone line.
  Capability-gated: runs only on a Hermes VM (calls `hermes chat`) and needs a Photon project.
---

# Ghost ⇄ iMessage Bridge

A bridge that wires **iMessage ⇄ `hermes chat`** using [Photon/Spectrum](https://photon.codes).
Each conversation gets its own Hermes session, so the agent has persistent per-contact memory.

```
iMessage  ─▶  Spectrum (Photon)  ─▶  hermes chat (this VM)  ─▶  reply  ─▶  iMessage
```

## When to use this

- Someone wants to **text a Hermes agent** from a normal phone and get agent replies.
- You're on a **Ghost Hermes VM** and have (or can create) a **Photon project**.

## Why it's capability-gated (`runtime: hermes`)

The bridge shells out to `hermes chat -q "<text>" -Q --yolo`, which only exists on a Hermes
runtime. An OpenClaw or browser-only agent can't run it — hence `runtime: hermes` and
`requires: [hermes, node, photon]`. This is the canonical example of a **runtime-specific**
skill in the registry: the playbook is shared, but only Hermes agents load it.

## Prerequisites

- A **Ghost Hermes VM** with `hermes` and `node` ≥ 20.6 on PATH, and model credits.
- A **Photon project** (iMessage) → gives a phone line + `PROJECT_ID` and `PROJECT_SECRET`.
  Create one at [app.photon.codes](https://app.photon.codes). **These two keys are the only
  per-user input, and they never go in this repo** — they live in the VM's `.env`.

## Setup

From a machine with the `inferenceai` CLI, copy this folder onto the VM, then:

```bash
bash setup.sh <PROJECT_ID> <PROJECT_SECRET>
# -> writes .env, installs deps, starts the bridge:
#    [bridge] up. ... waiting for messages...
```

Or the single-file path — hand someone `deploy.sh` and they answer three prompts (VM id +
the two Photon keys); it carries the whole bridge, copies it to their VM, and starts it.

See [README.md](README.md) for day-to-day commands, options, and troubleshooting.

## For an agent invoking this skill

1. Confirm you're on a Hermes VM (`hermes` on PATH) — if not, this skill doesn't apply.
2. Ensure the two Photon keys are available in the VM environment (never hard-code them).
3. Run `bash setup.sh <PROJECT_ID> <PROJECT_SECRET>`; watch `tail -f bridge.log` for `[IN ]`
   when a text arrives. Reset a contact's memory by deleting its entry in `sessions.json`.

## Secrets

`PROJECT_SECRET`, `.env`, and `sessions.json` are **per-VM and git-ignored** — they must
never be committed. Only the playbook and scripts travel through the registry.

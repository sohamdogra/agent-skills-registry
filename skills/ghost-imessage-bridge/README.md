# Ghost ⇄ iMessage Bridge

Connect **any Hermes (Ghost) agent** to **iMessage** using [Photon/Spectrum](https://photon.codes) —
no Mac, no Hermes upgrade required. Drop in two keys and run.

```
iMessage  ─▶  Spectrum (Photon)  ─▶  hermes chat (this VM)  ─▶  reply  ─▶  iMessage
```

Each iMessage conversation gets its **own Hermes session**, so the agent has persistent,
per-contact memory (saved in `sessions.json`, survives restarts).

---

## What you need
- A **Ghost Hermes VM** (this is where the bridge runs — it needs `hermes` and `node` ≥ 20.6 on PATH).
- Model **credits/balance** on that agent (replies are real model calls).
- A **Photon project** → gives you a phone line + two keys. Create one at
  [app.photon.codes](https://app.photon.codes) and choose **iMessage**.

That's it. The **only** per-user input is the two keys below.

---

## Easiest path — one file, three answers (recommended for testing)

Hand someone the single file **`deploy.sh`** (no folder needed). They run it from their
own computer (Mac/Linux terminal, or WSL/Ubuntu on Windows) and answer three prompts:

```bash
bash deploy.sh
# 1) Your agent VM      (e.g. vm-xxxxxxxx — find it with `inferenceai list`)
# 2) Photon PROJECT_ID
# 3) Photon PROJECT_SECRET
```

It carries the whole bridge inside it, copies it onto their VM, installs, and starts it —
nothing to edit. First-time prerequisites (once per person):
- **inference.ai CLI, logged in:** `curl -fsSL agents.inference.ai/cli | sh` then `inferenceai login`
  (on Windows, run inside WSL/Ubuntu).
- **A Photon project** for the two keys: [app.photon.codes](https://app.photon.codes) →
  create a project → pick **iMessage** → copy `PROJECT_ID` + `PROJECT_SECRET` → add your phone.

---

## Setup (manual / folder method)

1. **Copy this folder onto your Ghost Hermes VM.** For example, from a machine with the
   `inferenceai` CLI:
   ```bash
   inferenceai cp -r ./ghost-imessage-kit :/root/ghost-imessage-kit --vm <your-vm>
   inferenceai ssh <your-vm>
   cd /root/ghost-imessage-kit
   ```
   (Or `git clone`, `scp`, etc. — however you get files onto the VM.)

2. **Run setup with your two Photon keys:**
   ```bash
   bash setup.sh <PROJECT_ID> <PROJECT_SECRET>
   ```
   This writes `.env`, installs dependencies, and starts the bridge. You should see:
   ```
   [bridge] up. ... waiting for messages...
   ```

3. **Text your Photon line** (shown in your Photon dashboard) from a phone you've added.
   You'll get replies from your agent. 🎉

> Prefer to manage the secret yourself? Instead of passing it on the command line:
> `cp .env.example .env`, paste your keys into `.env`, then run `bash setup.sh`.

---

## Day-to-day

| Action | Command |
|---|---|
| Start / restart | `bash setup.sh` |
| Watch live logs | `tail -f bridge.log` |
| Stop | `bash stop.sh` |
| Reset a contact's memory | delete its entry in `sessions.json` (or delete the file) |

---

## Options (`.env`)
| Variable | Purpose |
|---|---|
| `PROJECT_ID` | Photon project id (required) |
| `PROJECT_SECRET` | Photon project secret (required, keep private) |
| `HERMES_MODEL` | Optional — force a specific model, e.g. `anthropic/claude-sonnet-4` |
| `HERMES_BIN` | Optional — path/name of the hermes binary (default `hermes`) |

---

## Running more than one
- **A second number / another project:** make another Photon project, copy this folder to a
  second location, and run `setup.sh` with the new keys. Each instance is independent.
- **Someone else's agent:** they copy this folder onto *their* Ghost Hermes VM and run
  `setup.sh` with *their* keys. Nothing in the code is specific to any one agent or number.

---

## Troubleshooting
- **`⚠️ Ghost agent error`** in iMessage → check `bridge.log`. Usually the agent's model is out
  of credits (402) or `hermes` isn't on PATH.
- **No reply at all** → confirm the bridge is running (`tail -f bridge.log` shows `[IN ]` when
  your text arrives). If nothing arrives, the texting phone isn't on the project's allowed list,
  or the keys are wrong.
- **Empty reply** → the agent ran but produced no text; check the model is configured
  (`hermes chat -q "hi" -Q --yolo` directly on the VM).

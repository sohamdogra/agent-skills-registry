# agent-skills-registry

**One private Git repo that is the single source of truth for what our agents know how to do.**

Playbooks travel through this repo; **credentials never do** — they stay per-VM.

> **Pull to learn, push to teach.** When one agent's skill improves, it opens a PR.
> After review, every other agent inherits it on the next `git pull`.

---

## What's in here

Every skill is a folder under [`skills/`](skills/) containing a `SKILL.md` (the playbook)
plus whatever scripts it needs. An agent "has" a skill when that folder sits in the
directory its runtime loads skills from. This repo is the master copy every VM syncs from.

**New here?** → [`ONBOARDING.md`](ONBOARDING.md) — add your agent in a couple of commands
(Hermes and OpenClaw).

## Skill index

| Skill | What it does | Runtime | `requires:` | Status |
|---|---|---|---|---|
| [linkedin-scraper](skills/linkedin-scraper/) | Scan a company's LinkedIn People tab for warm-intro leads via shared mutuals; export to Excel | neutral | `browser`, `python` | ✅ ready |
| [ghost-imessage-bridge](skills/ghost-imessage-bridge/) | Connect a Hermes agent to iMessage via Photon/Spectrum (per-contact memory) | **hermes** | `hermes`, `node`, `photon` | ✅ ready |
| [ai-news-daily](skills/ai-news-daily/) | Digest of today's top AI/ML stories, pulled live from Hacker News | neutral | `code_execution` | ✅ ready |
| [arxiv-watch](skills/arxiv-watch/) | Latest arXiv research papers on any topic, with links | neutral | `code_execution` | ✅ ready |
| [github-repo-report](skills/github-repo-report/) | Live stats for any public GitHub repo (stars, issues, latest release) | neutral | `code_execution` | ✅ ready |
| [inbound-lead-monitor](skills/inbound-lead-monitor/) | Watch inbound channels and surface qualified leads | neutral | `browser` | 🚧 stub |
| [registry-smoke-test](skills/registry-smoke-test/) | Trivial skill to verify the registry pipeline end to end | neutral | _(none)_ | ✅ ready |

**Runtime** is one of `neutral` (runs on any runtime), `hermes`, or `openclaw`.
See [`docs/REQUIRES.md`](docs/REQUIRES.md) for the full capability vocabulary.

---

## How an agent gets these skills

The repo is the source of truth. Both runtimes have a **native "subscribe to a GitHub repo"**
mechanism — point the agent at this repo once and it pulls skills from it. (Verified load
paths: Hermes `~/.hermes/skills/`, OpenClaw `~/.openclaw/skills/`.)

```bash
# Hermes (v0.18.0+) — tap the registry, then install skills from it
hermes skills tap add sohamdogra/agent-skills-registry
hermes skills install sohamdogra/agent-skills-registry/linkedin-scraper --yes
hermes skills update            # pick up improvements later

# OpenClaw — install a skill straight from the repo
openclaw skills install git:https://github.com/sohamdogra/agent-skills-registry --as linkedin-scraper --global
```

A raw `git clone` + cron `git pull` is the lowest-common-denominator fallback. Full
per-VM setup (deploy keys, auto-sync, older-Hermes fallback) is in
[`docs/SETUP.md`](docs/SETUP.md).

---

## The rules

- **`main` is protected.** Nobody commits straight to it. Every change is a PR reviewed by
  a maintainer, who verifies the `requires:` block before other agents inherit the skill.
- **Secrets never enter the repo.** Only playbooks travel; credentials and access live in
  each VM's environment. Shared know-how, *not* shared secrets.
- **An agent only loads skills whose `requires:` it can meet** — so a Hermes-only or
  CV-dependent skill is never force-fed to an agent that can't run it.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to add or change a skill, and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design and diagrams.

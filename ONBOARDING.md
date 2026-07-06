# Onboarding a new agent

Point your agent at this registry and it can pull any skill here. Two commands for Hermes,
a short clone-and-install for OpenClaw. No account, no token — this repo is public.

> **What you get:** the skill's playbook (`SKILL.md`) + its scripts land in your agent's
> skills directory, and the agent can use it immediately. Credentials never come from the
> repo — your agent supplies its own from its environment.

---

## Hermes (v0.18.0+)

Hermes has a built-in **tap** model — subscribe to the repo once, then install skills by name.

```bash
# 1. subscribe to the registry (once)
hermes skills tap add sohamdogra/agent-skills-registry

# 2. install the skills you want
hermes skills install sohamdogra/agent-skills-registry/github-repo-report --yes
hermes skills install sohamdogra/agent-skills-registry/ai-news-daily --yes
hermes skills install sohamdogra/agent-skills-registry/arxiv-watch --yes

# 3. confirm, and pull improvements later
hermes skills list          # should show Source: skills.sh
hermes skills update        # re-pull updated skills anytime
```

Skills land in `~/.hermes/skills/<skill>/`. If your agent talks on Discord/Telegram/etc.,
restart its gateway (`hermes gateway run`) so it picks up newly-installed skills.

> **Older Hermes (< v0.18.0)** has no `skills tap` — use the OpenClaw-style clone method
> below, cloning into `~/.hermes/skills/`.

---

## OpenClaw

OpenClaw's `git:` installer expects a single-skill repo (a `SKILL.md` at the root), so it
can't pull one skill out of this multi-skill repo directly. Instead, **clone the repo once,
then install the skill subfolders you want as local directories:**

```bash
# 1. clone the registry once
git clone https://github.com/sohamdogra/agent-skills-registry ~/agent-skills-registry

# 2. install the skills you want (each subfolder is a skill)
openclaw skills install ~/agent-skills-registry/skills/github-repo-report --as github-repo-report --global
openclaw skills install ~/agent-skills-registry/skills/ai-news-daily      --as ai-news-daily      --global
openclaw skills install ~/agent-skills-registry/skills/arxiv-watch        --as arxiv-watch        --global

# 3. confirm
openclaw skills list        # each should show ✓ ready
openclaw skills check       # verify requirements are met

# to update later: re-pull the repo, then re-install with --force
cd ~/agent-skills-registry && git pull
openclaw skills install ~/agent-skills-registry/skills/github-repo-report --as github-repo-report --global --force
```

Skills land in `~/.openclaw/skills/<skill>/` (with `--global`, the shared managed dir).

---

## Which skills can my agent run?

Each skill declares a `runtime:` and a `requires:` block. **An agent only loads skills whose
requirements it meets** — so a Hermes-only skill won't install usefully on OpenClaw, and a
skill needing a browser is skipped by an agent without one. See the
[skill index](README.md#skill-index) and [`docs/REQUIRES.md`](docs/REQUIRES.md).

The three `code_execution` skills (**github-repo-report**, **ai-news-daily**, **arxiv-watch**)
are runtime-neutral and need no credentials — the best first installs on any agent.

---

## Test it worked

Ask your agent, in chat:

> **github repo report on `vllm-project/vllm`**

It should run the skill and reply with live repo stats (stars, forks, latest release). If it
does, the skill pulled from this shared registry is working end to end on your agent.

---

## Improving a skill (push to teach)

Found a better way? Don't edit only your local copy — open a PR so **every** agent inherits
it on the next pull. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

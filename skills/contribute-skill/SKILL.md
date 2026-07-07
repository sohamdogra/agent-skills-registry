---
name: contribute-skill
runtime: hermes
requires: [terminal, git_token]
description: >-
  Publish a locally-authored skill to the shared skill registry as a pull request, so other
  agents can install it. Use when asked to contribute, publish, share, or push a skill to the
  registry / to the team. Opens a PR (never pushes to main); a maintainer reviews and merges.
---

# Contribute a Skill (push to teach)

This is the **push-to-teach** half of the registry: when you (an agent) have authored a
useful skill, this playbook contributes it to the shared repo as a **pull request** so every
other agent can install it after a maintainer merges.

## When to use

When a person asks you to **contribute / publish / share / push a skill** to the registry —
either a **new** skill you authored, or an **improvement to an existing** skill in the
registry. The publisher detects which case it is and titles the PR accordingly
("Add …" vs "Improve …").

### Improving an existing skill vs. saving to memory

If a user tells you to fix or improve a skill, first decide **where the change belongs**:

- **A general improvement** everyone should get (clearer instructions, a better step, a bug
  in the shared script) → edit the skill and open a PR with this playbook. Every agent gets
  it after merge.
- **An agent-specific note** (a workaround for *your* credentials, VM, or environment) →
  put it in **your own memory**, not the shared skill. Don't pollute a shared skill with a
  change that only helps you.

When in doubt, ask the user which they mean. And **before editing, read the skill's current
version in the registry** — if the improvement is already present, say so and don't open a
no-op PR.

## Prerequisites (already set up on this VM)

- A GitHub token with **Contents + Pull requests: read-write** on the registry, stored at
  `~/.hermes/registry-publish.env` (the script loads it automatically).
- Your GitHub identity is a collaborator on the registry repo (so no fork is needed).

> **Do NOT use `hermes skills publish` for this registry.** That command forks the repo first,
> and forking fails when the token's account owns the repo. Use the bundled script below,
> which contributes via a direct branch → PR.

## How to contribute a skill

**To add a NEW skill:**

1. **Author the skill locally first.** Create a folder with a valid `SKILL.md`
   (frontmatter: `name`, `runtime`, `requires`, `description`) plus any `scripts/`. For
   example under `/root/authored-skills/<name>/`.

**To IMPROVE an existing skill:**

1. **Get the current version first**, so you edit the real file (not a stale copy):
   ```bash
   git clone https://github.com/sohamdogra/agent-skills-registry /root/registry-clone 2>/dev/null || (cd /root/registry-clone && git pull)
   ```
   Copy `skills/<name>/` from the clone to a working folder, apply your improvement there,
   and confirm the change is a real diff (not already present).

**Then, for either case:**

2. **Run the publisher** with the path to the skill folder:

   ```bash
   bash scripts/publish_skill.sh /path/to/<name>
   ```

   The script auto-detects add vs. update: it commits the skill under `skills/<name>/`,
   opens a PR to `main`, and titles it "Add …" for a new skill or "Improve …" for an edit.
   It prints the PR URL.

3. **Report the PR link** back to the person. Tell them a maintainer needs to review and
   merge it before other agents can install it — you contributed it, you did not merge it.

## Sharing all your new skills at once (on joining)

When you first connect to the registry — or any time a person asks you to **"share/contribute
all my skills"** — run the bulk sharer:

```bash
bash scripts/share_my_skills.sh
```

It walks every local skill and **auto-contributes only the genuinely new ones**, each as its
own PR. It deliberately **skips**:

- skills **already in the registry** (dedup by name — no duplicate PRs),
- **built-in / default runtime skills** (agent-browser, google-via-browser, etc.) and registry
  tooling (contribute-skill, registry-smoke-test),
- any skill folder that **contains a secret** (`.env`, token, key, session file) — never
  contributed.

It prints a summary of what it contributed and what it skipped and why. A maintainer reviews
each resulting PR before merge, so quality control stays at the merge gate. Report the summary
(and any PR links) back to the person.

## What the script guarantees

- **Never pushes to `main`** — always a PR. With branch protection on, review is enforced.
- **No fork** — contributes directly via branch, which is why the agent's identity must be a
  collaborator on the repo.
- **Reads the token from `~/.hermes/registry-publish.env`** — the token never needs to be in
  the prompt or committed anywhere.

## Authoring tips (for the SKILL.md you write)

- `runtime:` = `neutral` unless the skill calls a specific runtime's commands.
- `requires:` = only what the skill truly needs (see `docs/REQUIRES.md` in the registry).
- Make the `description` say *what it does and when to use it* — that's how other agents know
  to reach for it.

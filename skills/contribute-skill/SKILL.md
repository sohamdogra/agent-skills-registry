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

When a person asks you to **contribute / publish / share / push a skill** to the registry.

## Prerequisites (already set up on this VM)

- A GitHub token with **Contents + Pull requests: read-write** on the registry, stored at
  `~/.hermes/registry-publish.env` (the script loads it automatically).
- Your GitHub identity is a collaborator on the registry repo (so no fork is needed).

> **Do NOT use `hermes skills publish` for this registry.** That command forks the repo first,
> and forking fails when the token's account owns the repo. Use the bundled script below,
> which contributes via a direct branch → PR.

## How to contribute a skill

1. **Author the skill locally first.** Create a folder with a valid `SKILL.md`
   (frontmatter: `name`, `runtime`, `requires`, `description`) plus any `scripts/`. For
   example under `/root/authored-skills/<name>/`.

2. **Run the publisher** with the path to that folder:

   ```bash
   bash scripts/publish_skill.sh /root/authored-skills/<name>
   ```

   The script creates a branch `add-skill-<name>`, commits the skill under
   `skills/<name>/`, and opens a PR to `main`. It prints the PR URL.

3. **Report the PR link** back to the person. Tell them a maintainer needs to review and
   merge it before other agents can install it — you contributed it, you did not merge it.

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

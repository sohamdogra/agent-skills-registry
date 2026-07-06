# Contributing a skill

> **Pull to learn, push to teach.** You improve a skill once, open a PR, and after review
> every other agent inherits it on the next `git pull`.

## The golden rules

1. **Never commit to `main`.** It's protected. Everything goes through a PR.
2. **Never commit a secret.** No API keys, tokens, session files, `.env`, cookies, or
   login state. Playbooks travel; credentials stay per-VM. See [`.gitignore`](.gitignore).
3. **Every skill declares a `requires:` block** so agents that can't run it skip it.
   See [`docs/REQUIRES.md`](docs/REQUIRES.md).

## Anatomy of a skill

```
skills/<skill-name>/
  SKILL.md          # required — the playbook + frontmatter
  skill.json        # optional — machine-readable entry/commands/runtime
  scripts/          # optional — code the playbook calls
  README.md         # optional — human setup notes / per-runtime install
  requirements.txt  # optional — deps (python), or package.json (node)
```

### `SKILL.md` frontmatter (required)

```yaml
---
name: <kebab-case-name>
runtime: neutral                 # neutral | hermes | openclaw
requires: [browser, python]      # capability tokens from docs/REQUIRES.md
description: >-
  One paragraph: what it does and when an agent should use it.
---
```

## Adding a new skill

1. Create a branch: `git checkout -b add-<skill-name>`.
2. Add `skills/<skill-name>/` with a `SKILL.md` (frontmatter above) and any scripts.
3. Add a row to the **Skill index** table in the root [`README.md`](README.md).
4. Confirm no secrets are staged: `git diff --cached` and check against `.gitignore`.
5. Open a PR. A maintainer reviews it and **verifies the `requires:` block** before merge.

## Changing an existing skill

Same flow — branch, edit, PR. If you change what the skill depends on, update its
`requires:` block **and** the README index row in the same PR.

## Agents contributing skills (push to teach)

The point of the registry is that **an agent that writes a useful skill can share it with
every other agent** — by opening a PR, never by pushing to `main`. A human still reviews and
merges, so the quality gate holds.

### Hermes — the built-in command

Hermes ships a publish command:

```bash
hermes skills publish <path-to-skill-dir> --to github --repo <owner>/agent-skills-registry
```

It scans the skill, then contributes it as a **pull request**. Requirements:

- A **write-capable GitHub token** in the agent's environment (`GITHUB_TOKEN` / `GH_TOKEN`)
  with **Contents: read-write** and **Pull requests: read-write** on the registry repo.
- The skill exists locally as a folder with a valid `SKILL.md`.

> **Note on `publish` and repo ownership.** The built-in command works by *forking* the
> target repo and opening the PR from the fork. GitHub does not allow an account to fork a
> repo it already owns, so if the agent's GitHub identity **owns** the registry, `publish`
> fails with "token lacks permission to fork." The fix is the collaborator model below —
> which is how a company registry should be set up anyway.

### The collaborator model (recommended for a shared/org registry)

Instead of forking, add each contributing agent's GitHub identity as a **collaborator** on
the registry (or a member of the `inference-ai` org that owns it). The agent then contributes
directly via branch → PR — no fork needed:

1. Create a branch `add-skill-<name>`.
2. Commit the skill folder (`skills/<name>/…`) to that branch.
3. Open a PR to `main`.

With **branch protection on `main`** (see [`docs/SETUP.md`](docs/SETUP.md)), the agent
*cannot* bypass review even with a write token — every contribution lands as a PR a
maintainer approves. This is the safe way to let agents self-contribute.

### OpenClaw

OpenClaw's `skills` CLI has no `publish` equivalent today. An OpenClaw agent (or its
operator) contributes the manual way: write the skill folder, then branch → commit → PR as
above.

### Security note

A publish/write token is more powerful than the read-only token used to *install* skills —
it can open PRs and, without branch protection, push to `main`. Scope it to **only this
repo**, prefer **fine-grained** tokens with just Contents + Pull requests write, set a short
expiry, and **turn on branch protection** so no token can merge without review.

## Review checklist (for maintainers)

- [ ] `requires:` and `runtime:` are present and accurate — does the skill really run on
      every runtime it claims?
- [ ] No secrets, session files, or `.env` in the diff.
- [ ] README index row added/updated (runtime + requires columns match the frontmatter).
- [ ] Playbook is self-contained: an agent could follow it without this conversation.
- [ ] Any new capability token was added to [`docs/REQUIRES.md`](docs/REQUIRES.md) first.

## Ownership

A registry only stays useful if someone curates it. Maintainers (listed in
[`CODEOWNERS`](CODEOWNERS)) own review and keep the index from rotting into stale or
conflicting skills.

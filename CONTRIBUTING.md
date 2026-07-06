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

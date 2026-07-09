# The `requires:` block

A skill only transplants cleanly if the agent that loads it actually has the capability the
skill assumes. So every skill declares its dependencies in a `requires:` block in its
`SKILL.md` frontmatter, and **an agent only loads skills whose requirements it can meet.**

```yaml
---
name: linkedin-scraper
runtime: neutral            # neutral | hermes | openclaw
requires: [browser, python]
---
```

This cleanly separates **portable** skills (pure research/posting, no special tooling) from
**capability-gated** ones (need specific tooling or a specific runtime).

## Capability vocabulary

Keep this list small and shared. Add a new token here (in its own PR) before using it in a
skill, so the vocabulary stays meaningful.

| Token | Means the agent has… |
|---|---|
| `browser` | Controllable browser (Playwright/Chromium or equivalent) |
| `code_execution` | Can run local scripts or sandboxed code snippets non-interactively |
| `cv` | Computer-vision / screen-reading tooling (e.g. an agent's own screen-reader) |
| `python` | Python 3.10+ available to the runtime |
| `node` | Node.js ≥ 20.6 available to the runtime |
| `hermes` | Hermes CLI on PATH (runtime-specific commands) |
| `openclaw` | OpenClaw CLI available (runtime-specific commands) |
| `photon` | A Photon/Spectrum project (iMessage line + keys) |
| `display` | A real screen / visible GUI (not headless-only) |
| `terminal` | Can run shell commands non-interactively |
| `git_token` | A GitHub token with write/PR access to the registry (for contributing skills) |

## `runtime:` vs `requires:`

- **`runtime:`** is the single field that answers "which agent runtimes can run this at all?"
  Most skills are natural-language playbooks and are `neutral`. Only skills that call a
  runtime's own commands are pinned to `hermes` or `openclaw`.
- **`requires:`** lists the *capabilities/tooling* on top of the runtime. `runtime: hermes`
  and `requires: [hermes]` often travel together, but `requires:` is where browser, cv,
  python, credentials-class dependencies, etc. go.

## How loading is decided

```
skill.runtime ∈ {neutral, <this agent's runtime>}   AND
every token in skill.requires is satisfied by this agent
        ⟶ load the skill
otherwise                                             ⟶ skip it
```

Access/credentials are **not** capabilities you list to unlock a skill — a skill can say
"post to Discord," but each agent still supplies its own channel access from its own
environment. `requires:` gates on *tooling/runtime*, never on secrets.

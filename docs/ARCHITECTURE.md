# `agent-skills-registry` — Shared Skill Registry

**One private Git repo is the single source of truth for what our agents know how to do.**
Playbooks travel through the repo; **credentials never do** — they stay per-VM.

> **Pull to learn, push to teach.** When one agent's skill improves, it opens a PR.
> After review, every other agent inherits it on the next `git pull`.

---

## The model

```mermaid
flowchart TB
    subgraph GH["🔒 GitHub — agent-skills-registry (private)"]
        direction TB
        README["README index<br/><i>what our agents already know</i>"]
        S1["SKILL.md · daily AI-news desk<br/><code>requires: [browser]</code>"]
        S2["SKILL.md · inbound-lead monitor<br/><code>requires: [browser]</code>"]
        S3["SKILL.md · &lt;capability-gated&gt;<br/><code>requires: [cv, hermes]</code>"]
        MAIN(["main — protected<br/>PR + maintainer review"])
        README --- S1 --- S2 --- S3 --- MAIN
    end

    subgraph V1["🖥️ VM · Agent A (Hermes)"]
        A1["Agent runtime"]
        L1["skills/ load path"]
        E1["🔑 env / secrets<br/><b>stays here</b>"]
        A1 --- L1
        A1 --- E1
    end

    subgraph V2["🖥️ VM · OpenClaw"]
        A2["Agent runtime"]
        L2["skills/ load path"]
        E2["🔑 env / secrets<br/><b>stays here</b>"]
        A2 --- L2
        A2 --- E2
    end

    subgraph V3["🖥️ VM · new agent"]
        A3["Agent runtime"]
        L3["skills/ load path"]
        E3["🔑 env / secrets<br/><b>stays here</b>"]
        A3 --- L3
        A3 --- E3
    end

    MAIN -->|"git pull<br/>(cron / webhook)"| L1
    MAIN -->|"git pull"| L2
    MAIN -->|"git pull<br/><i>onboards with all prior know-how</i>"| L3

    L1 -.->|"skill improves →<br/>PR to teach"| MAIN

    classDef repo fill:#0d1117,stroke:#58a6ff,color:#e6edf3;
    classDef vm fill:#161b22,stroke:#3fb950,color:#e6edf3;
    classDef secret fill:#2d1215,stroke:#f85149,color:#ffdcd7;
    classDef main fill:#1c2333,stroke:#d29922,color:#f2cc60;
    class README,S1,S2,S3 repo;
    class A1,A2,A3,L1,L2,L3 vm;
    class E1,E2,E3 secret;
    class MAIN main;
```

---

## Why this matters

| Before | After this repo |
| --- | --- |
| Skills are one-off files trapped on whichever VM built them | Skills are **reusable company assets** every agent can inherit |
| Onboarding a new agent = rebuild knowledge from scratch | New agent `git pull`s our **accumulated know-how** on day one |
| A better playbook stays with one agent | One PR → **every agent gets the upgrade** on next sync |
| Sharing capability risks sharing secrets | **Know-how is shared; secrets stay per-VM** |

---

## What is a "skill"?

A skill is a **playbook** plus a `requires:` block declaring its dependencies.
**An agent only loads skills whose requirements it can meet.**

```yaml
# SKILL.md frontmatter
name: daily-ai-news-desk
requires: [browser]          # portable — any agent with a browser can run it
---
# or, capability-gated:
requires: [cv, hermes]       # only Hermes agents with computer-vision load this
```

```mermaid
flowchart LR
    SK["Skill<br/>requires: [cv, hermes]"] --> CHK{"Agent meets<br/>requirements?"}
    CHK -->|"✅ Hermes + CV"| LOAD["Load skill"]
    CHK -->|"❌ missing capability"| SKIP["Skip — not loaded"]

    classDef n fill:#161b22,stroke:#3fb950,color:#e6edf3;
    classDef y fill:#1c2333,stroke:#d29922,color:#f2cc60;
    class SK,LOAD,SKIP n;
    class CHK y;
```

This cleanly separates **portable** skills (news desk, lead monitor — `requires: [browser]`)
from **capability-gated / runtime-specific** ones. The README index tags each so anyone
can see at a glance what travels everywhere vs. what needs a specific runtime.

---

## Governance & security

- **Access control + per-VM credentials** — each VM authenticates independently (read-only token or per-VM key); revoke one without touching the others.
- **`main` is protected.** Nobody commits straight to it. Changes go through a **PR reviewed by a small set of maintainers** who verify the `requires:` block before other agents inherit the skill.
- **Secrets never enter the repo.** Only playbooks travel; credentials and access live in each VM's environment. Shared know-how, *not* shared secrets.

---

## First step

The whole design hinges on **one unknown**: *where each runtime loads skills from on the VM.*
Confirming that load path (per runtime — Hermes, OpenClaw) is task #1; everything else is standard Git.

---

> ### 📌 Note on how capability-gated skills come about
> Some skills only work reliably because the authoring agent built extra tooling to support
> them — for example, writing its own **computer-vision (screen-reading)** helper when the
> off-the-shelf path wasn't robust enough. That CV capability is exactly the kind of thing the
> `requires:` block gates on, and why some skills are capability-tagged rather than universally
> portable.

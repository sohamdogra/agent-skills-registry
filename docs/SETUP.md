# Per-VM setup

Getting the registry's skills onto each agent's VM, into the folder its runtime loads
skills from. GitHub is the master copy; each VM subscribes to it.

Both runtimes have a **native "subscribe to a GitHub repo" mechanism** — prefer it over a
raw `git clone`. The manual clone is documented last as a fallback.

**Confirmed load paths (verified on our live VMs):**

| Runtime | Skills live at | Native subscribe command |
|---|---|---|
| **Hermes** (v0.18.0+) | `~/.hermes/skills/<skill>/SKILL.md` | `hermes skills tap add <owner/repo>` |
| **OpenClaw** | `~/.openclaw/skills/<skill>/` | `openclaw skills install git:<url> --global` |

---

## Hermes (v0.18.0+) — the native way

Hermes has a Homebrew-style **tap** model built in: point it at our GitHub repo once and it
treats every skill in the repo as an installable source.

```bash
# on the Hermes VM — subscribe to the registry
hermes skills tap add sohamdogra/agent-skills-registry
hermes skills tap list                       # confirm it's registered

# install a specific skill from the tapped registry
hermes skills install sohamdogra/agent-skills-registry/linkedin-scraper --yes
hermes skills list                           # confirm it's enabled

# pull improvements later
hermes skills update
```

Installed skills land in `~/.hermes/skills/<skill>/`. Taps are tracked in
`~/.hermes/skills/.hub/taps.json`. Because Hermes manages the checkout, you don't need a
manual clone or a cron `git pull` on Hermes — `hermes skills update` (optionally on a cron)
is the sync step.

> **Older Hermes (< v0.18.0)** has no `skills tap`. Either upgrade the agent, or use the
> manual-clone fallback below into `~/.hermes/skills/`.

## OpenClaw — the native way

```bash
# install a skill straight from the repo (per skill)
openclaw skills install git:https://github.com/sohamdogra/agent-skills-registry --as linkedin-scraper --global
openclaw skills info linkedin-scraper        # expect "✓ Ready"
```

Skills land in `~/.openclaw/skills/<skill>/`.

---

## Auth for a private repo (one-time, per VM)

A company skill repo is **private**, so each VM authenticates independently with its own
read-only deploy key — revoke one VM's access without touching the others.

```bash
# on the VM
ssh-keygen -t ed25519 -C "vm-<id>-skills" -f ~/.ssh/skills_deploy -N ""
cat ~/.ssh/skills_deploy.pub
```

Add that public key in GitHub → repo **Settings → Deploy keys → Add deploy key**
(read-only). For HTTPS-based tools, a fine-grained read-only PAT scoped to just this repo
works too.

---

## Fallback — manual clone (any runtime, incl. older Hermes)

If the native mechanism isn't available, clone the repo directly into the load path.

```bash
cat >> ~/.ssh/config <<'EOF'
Host github-skills
  HostName github.com
  User git
  IdentityFile ~/.ssh/skills_deploy
  IdentitiesOnly yes
EOF

# clone into the runtime's skills dir (Hermes shown; use ~/.openclaw/skills for OpenClaw)
git clone github-skills:sohamdogra/agent-skills-registry.git ~/.hermes/skills-registry
# then symlink or copy the individual skill folders into ~/.hermes/skills/ as needed
```

Auto-sync (set-and-forget) — pick an off-peak minute rather than `:00`:

```bash
# crontab -e  — pull hourly at :17
17 * * * * cd ~/.hermes/skills-registry && git pull --ff-only >> ~/skills-sync.log 2>&1
```

`--ff-only` keeps auto-sync safe: if a VM ever has local edits that would conflict, the pull
refuses rather than making a merge mess. Local skill tweaks should become PRs, not live edits
on the VM.

---

## Protecting `main` (branch protection)

The whole governance model — "nobody commits to `main`, everything is a reviewed PR" — is
only *enforced* if `main` is protected. Otherwise it's just convention, and any write token
(including an agent's publish token) could push straight to `main`.

Turn it on once, in the GitHub UI:

1. Go to the repo → **Settings** → **Branches** (left sidebar).
2. Under **Branch protection rules**, click **Add branch ruleset** (or **Add rule**).
3. **Branch name pattern:** `main`.
4. Enable:
   - ✅ **Require a pull request before merging** — and set **Require approvals: 1**.
   - ✅ **Require review from Code Owners** (uses [`CODEOWNERS`](../CODEOWNERS)).
   - ✅ **Do not allow bypassing the above settings** (so even admins/tokens can't skip it).
   - Optional: ✅ **Require status checks to pass** if you later add CI.
5. **Save changes.**

After this, an agent with a write token can *open* PRs but **cannot merge to `main`** without
a maintainer approving — which is exactly the safety property that makes agent
self-contribution safe. See the agent-contribution section in
[`../CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## Notes

- **Secrets stay on the VM** — in the runtime's environment (`~/.hermes/.env`, etc.), never
  in the repo. A skill says *what* to do; the VM supplies its own credentials.
- **`requires:` gating still applies** — an agent only loads a skill whose `runtime:` and
  `requires:` it can meet, so e.g. `ghost-imessage-bridge` (`runtime: hermes`) never gets
  pulled into an OpenClaw agent. See [`REQUIRES.md`](REQUIRES.md).

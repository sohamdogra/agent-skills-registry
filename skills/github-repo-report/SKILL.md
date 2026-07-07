---
name: github-repo-report
runtime: neutral
requires: [code_execution]
description: >-
  Return a live snapshot of any public GitHub repo — stars, forks, open issues, primary
  language, license, last push, and latest release. Use when someone asks about a GitHub repo,
  wants repo stats, or "how popular/active is <repo>". Runs a bundled script (no API key).
---

# GitHub Repo Report

Given a repo (`owner/name` or a github.com URL), returns a **live snapshot** from the GitHub
API: stars, forks, open issues, language, license, last-push date, and the latest release.
Every figure is current and links back to the real repo — not recalled from memory.

## When to use

When a person asks about a **GitHub repo** — its popularity, activity, stats,
**primary language**, or **license**
(e.g. "how active is vllm-project/vllm?", "give me stats on huggingface/transformers",
"what language is X written in?", "what license does X use?").

## How to run it

1. Run the script with the repo as an argument (accepts `owner/name` or a full URL):

   ```bash
   python3 scripts/repo_report.py "vllm-project/vllm"
   ```

   With no argument it defaults to `pytorch/pytorch`.

2. It prints JSON with: `repo`, `description`, `url`, `stars`, `forks`, `open_issues`,
   `language`, `license`, `last_push`, `created`, and `latest_release` (or null).

3. **Format a short report from the JSON**, e.g.:

   > **📦 [{repo}]({url})** — {description}
   > ⭐ {stars} · 🍴 {forks} · 🐛 {open_issues} open issues · {language}
   > Last push {last_push} · Latest release **{latest_release.tag}** ({latest_release.published})

4. If the JSON has an `"error"` field (e.g. repo not found or rate limited), report it plainly
   — don't invent numbers.

## Why it's a good registry skill

- **Real work, verifiable:** takes a repo name, queries GitHub live, returns exact current
  numbers the person can click through and confirm.
- **Portable:** `requires: [code_execution]` only — runs on any runtime.
- **No secrets:** uses the public GitHub API (unauthenticated 60 req/hr is plenty for a demo;
  set `GITHUB_TOKEN` in the env later if you want a higher limit).

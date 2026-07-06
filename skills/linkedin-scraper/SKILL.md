---
name: linkedin-scraper
runtime: neutral
requires: [browser, python, display]
description: >-
  Scan the "People" tab of LinkedIn company pages to find employees who share
  mutual connections with the logged-in user, classify them as warm-intro leads
  (10+ mutuals, or <10 mutuals where one of those mutuals is "influential" — 20+
  shared with you), and export the results to a formatted Excel file. Use when
  given one or more LinkedIn company URLs and asked to find warm-intro / mutual-
  connection leads, scout a company's team, or build a prospect list from
  LinkedIn. Requires a real LinkedIn login (manual, once) and a visible browser.
---

# LinkedIn Scout

A browser-automation tool (Playwright + Chromium) that, for each company URL you
give it, opens the company's **People** tab, scans everyone visible, and finds
people worth a warm intro based on shared mutual connections. Results are written
to a styled Excel workbook. Progress and scraped data are cached, so re-runs skip
finished companies and never lose past results.

## When to use this

- You have a list of LinkedIn **company** URLs and want to find employees you can
  reach through mutual connections.
- You want a spreadsheet of qualifying leads, not a one-off manual search.

## What "qualifies" means

Each scanned person is classified by how many mutual connections they share
**with the logged-in user**:

- **10+ shared mutuals** → "1st-degree lead", qualifies automatically.
- **1–9 shared mutuals** → "2nd-degree lead". The tool opens each of those
  mutuals to see if any single mutual shares **20+** connections with you
  (an "influential" mutual). If so, the person qualifies.
- **0 shared mutuals** → not a lead.

Thresholds live at the top of `scripts/main.py`:
`MIN_MUTUAL_CONNECTIONS = 10`, `MIN_MUTUAL_FRIEND_CONNECTIONS = 20`.

## Prerequisites

- **Python 3.10+**
- The packages in `requirements.txt`
- A **Chromium** browser for Playwright (installed via `playwright install`)
- A **LinkedIn account**. You log in once via `--login` (see below); the session
  is saved to `linkedin_session.json` and reused, so scans run unattended after.

## Setup (once)

```bash
pip install -r requirements.txt
playwright install chromium
python scripts/main.py --login        # opens a browser; log in to LinkedIn
```

`--login` opens a browser window — sign in to LinkedIn (including any 2FA), wait
for your home feed to appear, and the tool **auto-detects it and saves your
session by itself**. No need to return to the terminal or press anything. After
this one-time step, scans never prompt again.

## Providing the companies to scan

The user supplies LinkedIn **company** URLs. The script takes them directly as
arguments — **no source editing required**. Any of these URL forms works (they're
normalized to the People tab automatically):

```
https://www.linkedin.com/company/acme/
linkedin.com/company/acme
https://www.linkedin.com/company/acme/about/
```

Three ways to pass them:

```bash
# 1. Straight on the command line (best for agent use):
python scripts/main.py "https://www.linkedin.com/company/acme/" "https://www.linkedin.com/company/foo/"

# 2. From a text file, one URL per line (# lines ignored):
python scripts/main.py --urls-file companies.txt

# 3. Fall back to the COMPANY_URLS list inside main.py if no URLs are passed:
python scripts/main.py
```

## For an agent invoking this skill

1. **Extract every LinkedIn company URL from the user's message.** Accept the
   forms above; ignore non-company links (e.g. `/in/` profile links).
2. **Call the script with those URLs as arguments, AND pass `--headless`** so
   the scan runs with no visible browser window:
   `python scripts/main.py --headless "<url1>" "<url2>"`. Headless matters —
   a visible window can be closed mid-run, which breaks the mutual-checking
   step. (The one-time `--login` is the ONLY step that must stay visible.)
   If there are many URLs, write them to a file and use `--urls-file`.
3. **Call the scan once and return the file.** A scan run is fully unattended
   (no prompts). If it reports `Not logged in to LinkedIn`, the one-time
   `--login` step hasn't been done yet — tell the user to run
   `python scripts/main.py --login` (visible browser) and then retry.
4. **Return `linkedin_scout_results.xlsx`** to the user (e.g. upload it to the
   chat). The terminal also prints a clickable `file://` path and a running
   summary (people found / qualifying) after each company.

## Run options

```bash
python scripts/main.py --login          # one-time login (opens browser, auto-saves session)
python scripts/main.py <urls...>        # scan run, browser visible (recommended)
python scripts/main.py <urls...> --headless   # scan with no visible window
python scripts/main.py --reset-session  # forget saved login (then run --login again)
python scripts/main.py --reset-progress # re-scan ALL companies from scratch
```

## Login & sessions

- Run `python scripts/main.py --login` **once** to sign in. The session is saved
  to `linkedin_session.json` and reused; scans after that need no interaction.
- Scans are **non-interactive**: with no valid session they exit immediately with
  a clear "run `--login`" message rather than hanging on a prompt — safe for an
  agent to run.
- Sessions expire eventually. When a scan reports "Not logged in," just run
  `--login` again.
- Results are **relative to the logged-in account** — "mutual connections with
  you" means mutuals with whoever owns `linkedin_session.json`.

## Output files (created in the working directory)

| File | Purpose |
|------|---------|
| `linkedin_scout_results.xlsx` | The deliverable. Two sheets: **People** (one row per person, with lead type, mutual count, whether they qualify and why) and **Mutuals** (per-person detail of each shared mutual and how many they share with you). Rebuilt after every company. |
| `scout_results.json` | Master cache of every company's scraped records across all runs. The spreadsheet is rebuilt from this, so previously-finished companies stay in the sheet even when skipped. |
| `scout_progress.json` | Set of finished company URLs. Finished companies are skipped on re-runs. |
| `linkedin_session.json` | Saved login cookies so you don't log in every run. **Sensitive — never share this file.** |

## Re-run behavior (important)

- Companies already in `scout_progress.json` are **skipped** and re-loaded from
  `scout_results.json` into the spreadsheet — so adding new URLs and re-running
  scans only the new companies while keeping the old data in the sheet.
- Use `--reset-progress` only when you want to re-scrape everything (it clears
  both the progress file and the results cache first).

## Operating notes / safety

- **Run with a visible browser when possible** (the default). Headless is easier
  for LinkedIn to flag.
- This views many profiles. LinkedIn rate-limits and challenges accounts that
  view too many too fast. The tool has built-in human-like delays and detects
  auth-wall / checkpoint / "weekly limit" screens, **pausing the run** to protect
  the account when it sees one. If that happens, resolve it in the browser and
  re-run — progress is saved per company.
- `CHECK_EVERY_MUTUAL = True` (default) opens every listed mutual's profile to
  measure the 20+ rule. This is the slowest, highest-volume part; set it to
  `False` to skip it and rely only on the 10+ rule.

## Troubleshooting

- **"No usable profile cards" / empty scan:** LinkedIn lazy-loads the list; the
  tool retries and re-navigates. If it persists, you may be logged out or
  challenged — check the browser. Debug dumps are saved under `debug/`.
- **Spreadsheet won't update:** if `linkedin_scout_results.xlsx` is open in Excel,
  the tool writes a timestamped copy instead so the run never crashes.
- **Wrong / no company found:** confirm the company slug in the URL resolves to a
  real `/company/<slug>/` page on LinkedIn.

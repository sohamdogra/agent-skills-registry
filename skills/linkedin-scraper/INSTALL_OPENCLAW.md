# Installing LinkedIn Scout as an OpenClaw skill

This skill runs a real browser to scan LinkedIn, so it must run on a computer
with a screen (your own machine), where you can log in once. OpenClaw runs
locally, so it's a perfect fit.

## 0. Requirements (one-time)

- **OpenClaw** (local AI agent). If you don't have it:
  ```
  npm install -g openclaw@latest
  ```
  (needs Node 22.19+ or Node 24)
- **Python 3.10+** with pip on your PATH.

## 1. Install the skill into OpenClaw

**Option A — straight from GitHub (easiest):**
```
openclaw skills install git:https://github.com/sohamdogra/Linkedin-Scraper --as linkedin-scraper --global
```

**Option B — from this unzipped folder:**
```
openclaw skills install "C:\path\to\linkedin-scout-skill" --as linkedin-scraper --global
```

Verify it's recognized:
```
openclaw skills info linkedin-scraper
```
You should see `✓ Ready` and "Visible to model: yes".

## 2. Install the Python dependencies

The skill calls a Python script, so its libraries must be installed in the
Python that OpenClaw will use. From the installed skill folder
(`~/.openclaw/skills/linkedin-scraper` after a `--global` install), run:

```
pip install -r requirements.txt
playwright install chromium
```

## 3. Log in to LinkedIn (one time)

```
python "%USERPROFILE%\.openclaw\skills\linkedin-scraper\scripts\main.py" --login
```
(macOS/Linux: `python ~/.openclaw/skills/linkedin-scraper/scripts/main.py --login`)

A browser window opens — **sign in to LinkedIn** (finish any 2FA) and wait for
your home feed. It detects that automatically and saves your session. You won't
need to do this again until the session eventually expires.

## 4. Use it through OpenClaw

Just give the agent LinkedIn **company** URLs, e.g.:

> Use the linkedin-scraper skill on https://www.linkedin.com/company/viggle/

The agent runs the scan and produces **`linkedin_scout_results.xlsx`** in your
per-user data folder **`~/.linkedin-scraper/`** (on Windows:
`%USERPROFILE%\.linkedin-scraper\`). The script prints the full clickable path
when done. Two sheets: **People** (each person, mutual count, whether they
qualify and why) and **Mutuals** (the shared-connection detail).

Your login session is also stored there, so **updating/reinstalling the skill
never logs you out**, and scans work no matter which folder they run from.

You can also run it directly without the agent (use `--headless` so no browser
window opens that could be closed mid-scan):
```
python "...\scripts\main.py" --headless "https://www.linkedin.com/company/viggle/" "https://www.linkedin.com/company/acme/"
```

## Notes

- **Re-runs are smart:** finished companies are skipped and kept in the
  spreadsheet; new URLs are added. Use `--reset-progress` to redo everything.
- **If a scan says "Not logged in":** the session expired — re-run step 3.
- **Results are relative to the logged-in account** — "mutual connections with
  you" means mutuals with whoever logged in during step 3.
- **Don't share `linkedin_session.json`** — it's your live login.

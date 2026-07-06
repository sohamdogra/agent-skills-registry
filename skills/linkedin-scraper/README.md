# LinkedIn Scout

Finds LinkedIn company employees worth a warm intro (based on shared mutual
connections) and exports them to Excel. Packaged as a Claude Agent Skill — an
agent can read `SKILL.md` to learn how to run it, and a human can follow the same
file as a manual guide.

## Quick start

```bash
pip install -r requirements.txt
playwright install chromium
# edit COMPANY_URLS at the top of scripts/main.py, then:
python scripts/main.py
```

A browser opens on the first run — log in to LinkedIn manually, press Enter, and
the rest is automated. The result is `linkedin_scout_results.xlsx`.

Full instructions, configuration, re-run behavior, and safety notes are in
[`SKILL.md`](SKILL.md).

## What's in this bundle

```
linkedin-scout-skill/
├── SKILL.md           # Skill manifest + complete run instructions
├── README.md          # This file
├── requirements.txt   # Python dependencies
└── scripts/
    └── main.py        # The tool
```

## Before sharing / committing

These files are created at runtime and should **not** be shared — they contain
your login and personal data:

- `linkedin_session.json` (your LinkedIn auth cookies — sensitive)
- `scout_progress.json`, `scout_results.json` (your scraped data + progress)
- `linkedin_scout_results.xlsx`, `debug/`

A `.gitignore` is included that excludes them.

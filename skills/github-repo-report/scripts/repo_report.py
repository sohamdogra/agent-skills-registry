#!/usr/bin/env python3
"""github-repo-report: live stats for a public GitHub repo (auth-free).

Prints a compact JSON summary the agent turns into a report. Uses the public
GitHub REST API (unauthenticated: 60 req/hr, fine for a demo). Every number is
real and current.
"""
import json
import sys
import urllib.request
from datetime import datetime, timezone

REPO = sys.argv[1] if len(sys.argv) > 1 else "pytorch/pytorch"
# Accept a full URL too, e.g. https://github.com/owner/repo
if "github.com/" in REPO:
    REPO = REPO.split("github.com/", 1)[1]
REPO = REPO.strip("/").removesuffix(".git")

API = "https://api.github.com"
HEADERS = {"User-Agent": "github-repo-report/1.0", "Accept": "application/vnd.github+json"}


def _get(path):
    req = urllib.request.Request(API + path, headers=HEADERS)
    return json.load(urllib.request.urlopen(req, timeout=20))


def main() -> int:
    try:
        r = _get(f"/repos/{REPO}")
        # latest release is optional (many repos have none)
        try:
            rel = _get(f"/repos/{REPO}/releases/latest")
            release = {"tag": rel.get("tag_name"), "name": rel.get("name"), "published": (rel.get("published_at") or "")[:10]}
        except Exception:  # noqa: BLE001
            release = None
    except Exception as e:  # noqa: BLE001
        print(json.dumps({"error": f"fetch failed for '{REPO}': {e}"}))
        return 1

    out = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "source": "GitHub REST API",
        "repo": r.get("full_name"),
        "description": r.get("description"),
        "url": r.get("html_url"),
        "stars": r.get("stargazers_count"),
        "forks": r.get("forks_count"),
        "open_issues": r.get("open_issues_count"),
        "language": r.get("language"),
        "license": (r.get("license") or {}).get("spdx_id"),
        "last_push": (r.get("pushed_at") or "")[:10],
        "created": (r.get("created_at") or "")[:10],
        "latest_release": release,
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

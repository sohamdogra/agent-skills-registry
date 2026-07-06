#!/usr/bin/env python3
"""ai-news-daily: fetch today's top AI/ML stories from Hacker News (auth-free).

Prints a compact JSON array the agent turns into a digest. No API key needed —
uses the public HN Algolia endpoint, so the results are real, current, and
independently verifiable (every item has a real HN url).
"""
import json
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone

QUERY = sys.argv[1] if len(sys.argv) > 1 else "AI OR LLM OR \"machine learning\""
HITS = 8
MIN_POINTS = 20
# AI stories, most-relevant first; we filter by points client-side (the API's
# numericFilters param is finicky, and this keeps the fetch URL simple).
URL = (
    "https://hn.algolia.com/api/v1/search"
    f"?query={urllib.parse.quote(QUERY)}"
    "&tags=story"
    f"&hitsPerPage={HITS * 4}"
)


def main() -> int:
    try:
        req = urllib.request.Request(URL, headers={"User-Agent": "ai-news-daily/1.0"})
        with urllib.request.urlopen(req, timeout=20) as r:
            data = json.load(r)
    except Exception as e:  # noqa: BLE001 - surface any fetch failure to the agent
        print(json.dumps({"error": f"fetch failed: {e}"}))
        return 1

    stories = []
    for h in data.get("hits", []):
        title = h.get("title")
        if not title:
            continue
        points = h.get("points", 0) or 0
        if points < MIN_POINTS:
            continue
        stories.append({
            "title": title,
            "url": h.get("url") or f"https://news.ycombinator.com/item?id={h.get('objectID')}",
            "points": points,
            "comments": h.get("num_comments", 0),
            "hn_discussion": f"https://news.ycombinator.com/item?id={h.get('objectID')}",
        })
        if len(stories) >= HITS:
            break

    out = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "source": "Hacker News (hn.algolia.com)",
        "query": QUERY,
        "count": len(stories),
        "stories": stories,
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

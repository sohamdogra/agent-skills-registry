#!/usr/bin/env python3
"""arxiv-watch: fetch the latest arXiv papers on a topic (auth-free).

Prints a compact JSON array the agent turns into a briefing. Uses the public
arXiv API, so results are real, current, and verifiable (every paper has a real
arxiv.org abstract link).
"""
import json
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

TOPIC = sys.argv[1] if len(sys.argv) > 1 else "large language models"
MAX_RESULTS = 6
NS = {"a": "http://www.w3.org/2005/Atom"}

# Sort by most recently submitted so it's genuinely "the latest".
URL = "http://export.arxiv.org/api/query?" + urllib.parse.urlencode({
    "search_query": f"all:{TOPIC}",
    "start": 0,
    "max_results": MAX_RESULTS,
    "sortBy": "submittedDate",
    "sortOrder": "descending",
})


def main() -> int:
    try:
        req = urllib.request.Request(URL, headers={"User-Agent": "arxiv-watch/1.0"})
        body = urllib.request.urlopen(req, timeout=30).read().decode()
        root = ET.fromstring(body)
    except Exception as e:  # noqa: BLE001
        print(json.dumps({"error": f"fetch failed: {e}"}))
        return 1

    papers = []
    for entry in root.findall("a:entry", NS):
        title = (entry.findtext("a:title", default="", namespaces=NS) or "").strip().replace("\n", " ")
        summary = (entry.findtext("a:summary", default="", namespaces=NS) or "").strip().replace("\n", " ")
        published = entry.findtext("a:published", default="", namespaces=NS) or ""
        link = entry.findtext("a:id", default="", namespaces=NS) or ""
        authors = [a.findtext("a:name", default="", namespaces=NS) for a in entry.findall("a:author", NS)]
        papers.append({
            "title": title,
            "authors": ", ".join([x for x in authors if x][:4]) + ("  et al." if len(authors) > 4 else ""),
            "published": published[:10],
            "url": link,
            "summary": (summary[:280] + "…") if len(summary) > 280 else summary,
        })

    out = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "source": "arXiv (export.arxiv.org)",
        "topic": TOPIC,
        "count": len(papers),
        "papers": papers,
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

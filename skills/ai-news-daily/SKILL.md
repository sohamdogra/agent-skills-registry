---
name: ai-news-daily
runtime: neutral
requires: [code_execution]
description: >-
  Produce a short digest of today's top AI/ML news, pulled live from Hacker News (no API key).
  Use when someone asks for the AI news, an AI news digest/briefing, or "what's happening in
  AI today". Runs a bundled script that fetches real, current stories with links.
---

# AI News Daily

Fetches **today's top AI/ML stories from Hacker News** and returns a short, linked digest.
The data is pulled live from a public API, so every item is real and independently
verifiable — this is not the model recalling headlines from memory.

## When to use

When a person asks for **the AI news**, an **AI news digest / briefing**, or **"what's
happening in AI today."**

## How to run it

1. Execute the bundled fetcher (it needs no API key and prints JSON):

   ```bash
   python3 scripts/fetch_news.py
   ```

   Optionally pass a custom topic query, e.g.
   `python3 scripts/fetch_news.py "AI agents OR RAG"`.

2. The script prints JSON like:

   ```json
   {
     "generated_at": "2026-07-06 20:10 UTC",
     "source": "Hacker News (hn.algolia.com)",
     "count": 8,
     "stories": [
       {"title": "...", "url": "...", "points": 240, "comments": 88, "hn_discussion": "..."}
     ]
   }
   ```

3. **Format a digest from the JSON** and send it. For each story show the title as a link,
   with points/comments as a signal. Keep it tight — a heading plus the list. For example:

   > **🗞️ AI News — {generated_at}** _(source: Hacker News)_
   > 1. **[Title](url)** — 240 pts · 88 comments
   > 2. **[Title](url)** — 180 pts · 40 comments
   > …

4. If the JSON has an `"error"` field, say the fetch failed and show the error — don't invent
   stories to fill the gap.

## Why this is a good registry demo

- **It does real work:** takes a topic, calls the internet, returns current results with
  links a person can click to verify.
- **It's portable:** `requires: [code_execution]` only — any agent that can run a script
  loads it, on any runtime. One file in the shared repo; every agent inherits it on install.
- **No secrets:** the source API is public, so nothing per-VM is needed to run it.

## Extending it later

Swap or add sources inside `scripts/fetch_news.py` (arxiv, a newsletter, an RSS feed),
or have the agent post the digest to a channel on a schedule via its cron tool. The playbook
above stays the same — only the fetcher changes.

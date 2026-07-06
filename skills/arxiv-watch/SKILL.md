---
name: arxiv-watch
runtime: neutral
requires: [code_execution]
description: >-
  Fetch the latest arXiv research papers on a topic and return a short briefing with links.
  Use when someone asks for recent papers, new research, or "what's the latest research on
  <topic>". Runs a bundled script that pulls real, current papers from the arXiv API (no key).
---

# arXiv Watch

Pulls the **most recently submitted arXiv papers** on any topic and returns a short briefing.
Data comes live from the public arXiv API, so every paper is real and links to its actual
arxiv.org abstract — not the model recalling papers from memory.

## When to use

When a person asks for **recent/latest papers** or **new research** on a topic
(e.g. "latest research on RAG", "new papers on diffusion models").

## How to run it

1. Run the fetcher with the topic as an argument:

   ```bash
   python3 scripts/fetch_arxiv.py "retrieval augmented generation"
   ```

   With no argument it defaults to "large language models".

2. It prints JSON: `generated_at`, `topic`, `count`, and a `papers` array where each item has
   `title`, `authors`, `published` (date), `url`, and a short `summary`.

3. **Format a briefing from the JSON.** For each paper: title as a link, the date, authors,
   and one line of the summary. Keep it scannable:

   > **📄 Latest on "{topic}"** — as of {generated_at}
   > 1. **[Title](url)** — {published} · {authors}
   >    _{one-line summary}_

4. If the JSON has an `"error"` field, report the fetch failed and show it — don't invent
   papers.

## Why it's a good registry skill

- **Real work, verifiable:** takes a topic, queries arXiv live, returns papers with clickable
  abstract links and submission dates.
- **Portable:** `requires: [code_execution]` only — loads on any runtime that can run a
  script. On-brand for an AI/ML team.
- **No secrets:** the arXiv API is public.

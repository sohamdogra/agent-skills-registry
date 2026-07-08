---
name: daily-digest-cron
runtime: neutral
requires: [cronjob, terminal]
description: >-
  Set up, tune, and manage recurring daily digest cron jobs that ping the user with
  news, briefings, or summaries on a schedule. Use when the user asks to be pinged daily,
  get a morning/evening briefing, receive scheduled news updates, or automate any recurring
  "send me X every day at Y time" workflow. Covers scheduling, format iteration, and test runs.
---

# Daily Digest Cron

Sets up recurring cron jobs that deliver a digest (news, briefings, summaries) to the user
on a schedule via their connected messaging platform.

## When to use

- "Ping me daily with the news at 8 AM"
- "Send me a morning briefing every day"
- "Set up a daily summary at [time]"
- Any recurring "send me X every day at Y time" request

## Scheduling (time zones)

Always convert user-specified local times to UTC for the cron schedule:

| User timezone | Offset | Example: 8 AM local → UTC |
|---|---|---|
| PST (UTC-8) | -8h | 16:00 UTC → `0 16 * * *` |
| PDT (UTC-7) | -7h | 15:00 UTC → `0 15 * * *` |
| EST (UTC-5) | -5h | 13:00 UTC → `0 13 * * *` |
| EDT (UTC-4) | -4h | 12:00 UTC → `0 12 * * *` |

5 PM PST = 01:00 UTC next day → `0 1 * * *`

## Setup workflow

1. Create both jobs (morning + evening if requested) in parallel using `cronjob(action='create')`.
2. Set `deliver='origin'` to deliver back to the current chat/channel automatically.
3. Set `enabled_toolsets` to only what the job needs (e.g. `["terminal", "web"]`) — reduces token overhead.
4. Always do a test run immediately after setup: `cronjob(action='run', job_id=...)`.
5. Iterate on the prompt based on user feedback before the next scheduled run.

## Prompt design for digest jobs

The cron prompt must be fully self-contained (no chat context). Include:
- Exact script path or command to run
- Exactly how many items to return (e.g. "top 3 stories only")
- Full formatting instructions (emoji, heading style, link format)
- Error handling ("if JSON has an error field, say so — don't invent content")

### Format iteration pattern (common request sequence)
Users typically iterate like this — expect it and update the prompt each time:
1. First request: "give me the news" → basic list
2. "Only top 3" → filter count
3. "Add a quick summary" → one-liner per item
4. "Make it more in-depth, like a paragraph" → 3–5 sentence summary per item
5. "Use H1 headings / Discord format" → platform-specific formatting

Update BOTH jobs (morning + evening) simultaneously when the user requests a format change.
Then immediately fire a test run so the user can verify.

## Test runs

```python
cronjob(action='run', job_id='<id>')
```

Fire a test run after every prompt update. Don't wait for the next scheduled run — the user
wants to see the new format immediately.

## Updating jobs

When the user asks for a format change:
1. Update both morning and evening jobs in parallel (`cronjob(action='update')` for each).
2. Immediately fire a test run on one of them.
3. Ask if they want the other one tested too.

## ai-news-daily integration

For news digest jobs, load the `ai-news-daily` skill and use its bundled script:
```bash
python3 /root/.hermes/skills/ai-news-daily/scripts/fetch_news.py
```
Pass a topic argument for non-AI news:
```bash
python3 /root/.hermes/skills/ai-news-daily/scripts/fetch_news.py "rust OR webassembly"
```

## Example cron prompt (paragraph-depth, top 3, Discord-friendly)

```
Fetch and deliver today's top news digest.

Steps:
1. Run: python3 /root/.hermes/skills/ai-news-daily/scripts/fetch_news.py
2. Parse the JSON output and pick ONLY the top 3 stories by points.
3. Format the digest as:

🗞️ **Morning News Digest** — {generated_at} _(source: Hacker News)_

For each of the top 3 stories, show:
**N. [Title](url)**
📊 X pts · Y comments
> A solid paragraph summary (3-5 sentences) explaining what this is about, why it
  matters, and the key takeaway — enough that someone can fully grasp the story
  without clicking the link.

If there's an "error" field in the JSON, say the fetch failed and show the error —
don't invent stories.
```

## Pitfalls

- **Ambiguous skill name for ai-news-daily.** There are two copies of this skill on disk
  (`/root/.hermes/skills/ai-news-daily/SKILL.md` and `.../ai-news-daily/ai-news-daily/SKILL.md`).
  Use the full path when loading: read the file directly rather than `skill_view('ai-news-daily')`.

- **Skills list in cronjob create uses skill names, not paths.** Pass `["ai-news-daily"]`
  in the `skills` array — the scheduler resolves it. Don't pass the full path.

- **Don't forget to update BOTH morning and evening jobs** when format changes are requested.
  Users naturally say "make it more in-depth" and expect both runs to change.

- **Test run is async — result arrives as a separate message.** After calling
  `cronjob(action='run')`, tell the user "it'll appear in a moment" — don't wait inline.

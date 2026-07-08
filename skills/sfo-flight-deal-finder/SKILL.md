---
name: sfo-flight-deal-finder
runtime: neutral
requires: [web, browser]
description: >-
  Scans flights from SFO to one or more destination cities/airports over given dates or date
  ranges, compares cash fares against points/miles redemptions across major airline loyalty
  programs, and surfaces the best options under a target budget — for a single trip or a
  whole list of trips at once. Use whenever the user asks to find, scan, compare, or search
  flights out of SFO to any destination (New York, Chicago, Columbus, or anywhere else),
  especially when they want cash vs. points compared or a "best deal" recommendation, or
  when they give a batch of multiple trips/dates to check in one go. Trigger even if the
  user only gives a city and a date with no other detail — assume sensible defaults
  (economy, all major airports serving that city, $1000 budget) and proceed rather than asking.
---

# SFO Flight Deal Finder

Finds and ranks the best SFO-to-[destination] flight options for one or more trips by
comparing cash prices and points/miles redemptions side by side, using web search/browsing
(Google Flights, Kayak, and individual airline sites) as the data source.

## Trip list (current requests)

Run the full workflow below independently for each trip, then present results as separate
tables (one per trip) followed by an overall summary if there's more than one.

| # | Destination | Airports to check | Dates | Trip type |
|---|---|---|---|---|
| 1 | New York, NY | JFK, EWR, LGA | Aug 13 | One-way |
| 2 | Chicago, IL | ORD, MDW | Sept 3 – Sept 7 | Round-trip |
| 3 | Columbus, OH | CMH | Sept 17 – Sept 21 | Round-trip |

Treat this table as the live list of trips to scan. When the user adds, removes, or edits
a trip in conversation, update this table to match before running the workflow — don't just
bolt the new trip on separately.

## Default parameters (override if the user specifies otherwise)

- **Origin:** SFO
- **Destination:** whichever airport(s) are listed for that trip in the table above.
  If a city isn't in the table yet, check all major commercial airports serving it.
- **Dates:** as given per trip. For a round-trip entry, the first date is departure and the
  second is return, unless stated otherwise. If no year is specified, assume the next
  upcoming occurrence of that date.
- **Trip type:** as specified per trip (one-way vs. round-trip)
- **Cabin:** economy
- **Budget ceiling:** $1000 per ticket (for round-trips, this is the total round-trip price,
  not per-leg)
- **Passengers:** 1 adult, unless specified
- **Carry-on bags:** assume 1 carry-on per passenger unless stated otherwise. Always note
  whether the fare class includes carry-ons — Basic Economy on United, Delta, and American
  does NOT include a carry-on (personal item only). Add ~$35–60/person/leg for carry-on
  fees when comparing Basic Economy fares. JetBlue Blue and Southwest always include carry-ons free.

State any assumption made (year, budget, airports assumed, carry-on count) briefly at the
top of the output rather than blocking on it.

## Workflow

### Step 1 — Scan cash fares

Use **web search** as the primary method (e.g., search "SFO to JFK August 13 2026 one way
economy price"). Cross-check across Google Flights, KAYAK, and Momondo. The browser tool
can be used for Google Flights but is unreliable — see Pitfalls below.

Capture for each viable flight/itinerary:
- Airline + flight number (or "nonstop"/"1-stop, [city]")
- Departure and arrival times (both legs, if round-trip)
- Cash price (economy, one ticket, total for the trip)

### Step 2 — Scan points/miles fares

Check award availability on the airlines that actually serve each route:

- **united.com** (MileagePlus) — SFO hub carrier, worth checking on every route
- **delta.com** (SkyMiles)
- **aa.com** (AAdvantage)
- **jetblue.com** (TrueBlue) — strong on NYC-area routes, less relevant for Chicago/Columbus
- **alaskaair.com** (Mileage Plan) — check partner awards (AA, etc.) where Alaska doesn't
  fly the route directly
- **southwest.com** (Rapid Rewards) — worth checking for Chicago (MDW) and Columbus, since
  Southwest serves both

For each program with availability, check the same date(s) as the cash search (round-trip
award pricing where relevant) and capture:
- Points/miles required
- Cash taxes & fees required alongside points
- Same flight/time details as above

### Step 3 — Normalize points to a dollar value

| Program | Est. value per point |
|---|---|
| United MileagePlus | ~1.3¢ |
| Delta SkyMiles | ~1.1¢ |
| American AAdvantage | ~1.4¢ |
| JetBlue TrueBlue | ~1.3¢ |
| Alaska Mileage Plan | ~1.5¢ |
| Southwest Rapid Rewards | ~1.3¢ |
| Chase Ultimate Rewards (transferable) | ~1.8¢ |
| Amex Membership Rewards (transferable) | ~1.8¢ |
| Capital One Miles (transferable) | ~1.7¢ |

**Formula:** `points-equivalent cost = (points × ¢/point ÷ 100) + taxes & fees`

### Step 4 — Filter and rank

- Keep any option where cash price OR points-equivalent cost is under the budget ceiling.
- Sort by whichever number is lower for that option.
- Flag explicitly:
  - 💰 **Best cash deal** — lowest actual dollar price
  - ⭐ **Best points redemption** — lowest points-equivalent cost, or clearly outperforms
    typical point value (>1.3–1.8¢/point)
  - 🏆 **Best overall** — top pick considering price, nonstop vs. connection, and timing

### Step 5 — Present results

**Format (Discord-friendly):**
- Use `# Trip N: SFO → [City], [Dates]` (H1) as the section header for each trip — this renders as a heading in Discord.
- Present flights as a **bullet list**, not a table — tables render poorly on Discord.
- Each bullet must include: airline, price (per person + total for N passengers), departure time, arrival time, total flight duration, nonstop or layover city + layover duration, and carry-on inclusion status.
- Link each bullet directly to the airline's booking page or an aggregator search pre-filled with exact dates/passengers — never to a homepage.

Example bullet format:
```
# Trip 1: SFO → NYC (Aug 13, one-way, 2 adults)

**To EWR (Newark)**
- [$168 total — United, nonstop, 7:00a→3:30p (5h 30m)](https://united.com/...) — carry-on ✅
- [$178 total — American, 1 stop via PHX, 6:00a→4:45p (8h 45m, 1h 20m layover)](https://aa.com/...) — Basic Economy: NO carry-on ⚠️

**To JFK**
- [$236 total — JetBlue, nonstop, 9:15a→5:50p (5h 35m)](https://jetblue.com/...) — carry-on ✅ ⭐ Best overall
```

For round-trip entries, show both outbound and return times in the bullet.

Close multi-trip results with a short cross-trip summary (total estimated spend if booking
"best overall" for each trip, for all N passengers).

## Pitfalls

- **Google Flights URL pre-filling doesn't work.** Parameterized URLs (e.g. with `tfs=...`)
  do not load pre-filled search results in the browser tool — the form just opens blank.
  Don't waste time constructing or navigating to parameterized Google Flights URLs.
  Use web search snippets instead, which surface KAYAK/Momondo prices directly in results.

- **Google Flights browser form interaction is unreliable.** The origin field combobox often
  fails to register typed input or dropdown selection. Prefer web search for data gathering
  and use the browser as a fallback only.

- **delegate_task for this workflow is prone to context exhaustion.** Each route search
  generates many tool calls. Splitting by route (one subagent per trip) works better than
  one subagent for all routes, but web search subagents (no browser) are more reliable.

- **Award pricing is dynamic — treat ranges as estimates.** United, Delta, and AA all use
  dynamic pricing. Published ranges (e.g. "12,500–25,000 miles one-way") are baselines;
  actual prices only confirmed by logging in and searching.

- **Never present search snippet prices as confirmed fares.** Google search result snippets
  (e.g. "SFO to JFK from $118 — JetBlue") are often cached, approximate, or represent
  a different date/passenger count. If the user asks "where did you see that price?" and
  you can't point to a live booking confirmation, say so explicitly. Always caveat snippet-
  sourced prices as "as low as ~$X (unverified)" rather than stating them flatly.

- **All major aggregators (KAYAK, Google Flights, Expedia) block automated browsers.**
  KAYAK redirects to a bot-detection page. Google Flights times out or opens blank. Expedia
  shows a CAPTCHA. Do not attempt to scrape these with the browser tool. Use web search
  (which surfaces snippet prices from these sites) as the primary data source instead.
  Direct airline sites (united.com, aa.com, southwest.com) are also unreliable for
  form interaction (most return "Access Denied"). JetBlue shows a "Client Challenge" page.

- **FlightAware is the reliable fallback for real flight schedules.**
  When aggregators and airline sites block the browser, use FlightAware to get confirmed
  departure times, arrival times, aircraft type, and nonstop vs. connection status:
  ```
  https://www.flightaware.com/live/findflight?origin=SFO&destination=JFK
  ```
  Replace the destination code as needed. Extract all rows with JavaScript via `browser_console`:
  ```javascript
  const rows = document.querySelectorAll('table tr');
  const flights = [];
  rows.forEach(row => {
    const cells = row.querySelectorAll('td');
    if (cells.length >= 6) {
      flights.push({
        airline: cells[0]?.innerText?.trim(),
        ident: cells[1]?.innerText?.trim(),
        aircraft: cells[2]?.innerText?.trim(),
        depart: cells[4]?.innerText?.trim(),
        arrive: cells[6]?.innerText?.trim(),
        connection: cells[7]?.innerText?.trim()  // present on connecting-flight routes
      });
    }
  });
  JSON.stringify(flights.filter(f => f.depart && f.depart.includes('Thu')));
  ```
  FlightAware does NOT show prices — combine with web search snippets for price data.
  FlightAware shows scheduled flights for the current week; use the recurring daily
  schedule as a proxy for future dates (same flights operate on the same days of the week).

- **SFO→CMH has United nonstop service.** United operates UAL1095 (departs 10:30AM, arrives
  6:24PM EDT, ~5h 54m) and UAL1939 (departs 9:23PM, arrives 5:15AM EDT next day, red-eye).
  Connecting options via ORD, DEN, ATL, DFW, or CLT add ~2–4 hours.

## Edge cases

- If no fares under budget exist on the exact date, show cheapest available options plus
  fares ±1–2 days as a fallback, labeled as such.
- If award availability is sold out at saver level, note "no saver award available" rather
  than omitting the program silently.
- Always end with: *"Fares and award availability change frequently — verify before booking."*

## See also

- `references/route-data-2026.md` — cached price ranges, confirmed FlightAware schedules,
  and points benchmarks from the SFO→NYC/Chicago/Columbus scan (July 2026). Includes
  corrected nonstop data for SFO→CMH (United does fly nonstop) and full EWR/JFK schedules.
- `scripts/flightaware_extract.js` — JS snippet to paste into `browser_console()` after
  navigating to a FlightAware findflight URL. Extracts all flight rows into structured JSON.

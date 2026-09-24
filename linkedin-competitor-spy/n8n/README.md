# LinkedIn Competitor Spy for n8n

The same tool as `spy.py`, built as an n8n workflow you can import. Every Monday
at 9am (or when you click **Test workflow**) it:

1. Reads your competitor list from a Google Sheet
2. Scrapes each competitor's recent LinkedIn posts with Apify
3. Sends them to Claude, which breaks down each post's format, topic, hook, hook type, CTA and why it worked, plus a strategy summary and post ideas for your niche
4. Writes one row per post to the **Posts** tab and one summary per competitor to **Insights**

```
Trigger → Settings → Read Competitors → Loop ─┬→ Apify → Prepare Posts → Any Posts? ─┬→ Claude → Posts tab → Insights tab ─┐
                                               │                                     └→ (none: next competitor)            │
                                               └──────────────────────── next competitor ◄─────────────────────────────────┘
```

Works on n8n Cloud or self-hosted n8n (tested on n8n 2.40).

## 1. Prepare the Google Sheet

Create a sheet with three tabs. The names and header rows must match exactly:

**Competitors**: fill in one row per competitor
```
name	linkedin_url
```

**Posts**: header row only
```
scraped_at	competitor	posted_at	post_url	likes	comments	shares	engagement_score	format	topic	hook	hook_type	cta	why_it_worked	post_text
```

**Insights**: header row only
```
run_at	competitor	posts_analyzed	summary	top_themes	what_to_steal	content_ideas
```

Tip: copy a header line above and paste it into cell A1. Google Sheets splits
it into columns because the words are tab-separated.

Copy the sheet ID from its URL: `docs.google.com/spreadsheets/d/<SHEET_ID>/edit`.

## 2. Import the workflow

In n8n, go to **Workflows → Create → ⋯ menu → Import from File** and pick
`competitor-spy.workflow.json`.

## 3. Fill in Settings

Open the **Settings** node and set:

| Field | Value |
|---|---|
| `sheetId` | The sheet ID from step 1 |
| `niche` | Your niche, so the post ideas fit you |
| `maxPosts` | Posts per competitor (default 10) |
| `days` | Only analyze posts from the last N days (default 30) |
| `model` | Claude model (default `claude-opus-5`) |
| `apifyActor` | Apify scraper (default `harvestapi~linkedin-profile-posts`) |

## 4. Add credentials (three in total)

| Credential | Where it's used | How to create it |
|---|---|---|
| **Google Sheets OAuth2** | The 4 sheet nodes | Open a sheet node → Credential → *Create new* → *Sign in with Google* |
| **Header Auth "Apify token"** | Scrape Posts (Apify) | Create a *Header Auth* credential. Name: `Authorization`, Value: `Bearer YOUR_APIFY_TOKEN` (get the token at console.apify.com → Settings → Integrations) |
| **Header Auth "Anthropic API key"** | Claude Analyze | Create a *Header Auth* credential. Name: `x-api-key`, Value: your key from console.anthropic.com/settings/keys |

Apify's free plan gives $5 of credit a month, which covers about 10 competitors
× 10 posts weekly. Claude costs a few cents per competitor per run.

## 5. Run it

Click **Test workflow**. Once the sheet fills correctly, toggle the workflow to
**Active** so the Monday 9am schedule runs. Change the day or time in the
**Every Monday 9am** node.

Posts are matched on `post_url`, so a post already in the sheet gets updated
instead of duplicated.

## Troubleshooting

- **Posts have empty text or 0 likes.** Different Apify scrapers name fields
  differently. Open the **Scrape Posts (Apify)** node's output after a test run,
  find the field names, and add them to the `pick(...)` lists in **Prepare Posts**.
- **Claude Analyze returns 401.** The Header Auth name must be exactly `x-api-key`.
- **Apify returns 401.** The value must start with `Bearer ` (with a space).
- **"Column names were not found".** A tab's header row doesn't match step 1.
- **Apify times out.** Lower `maxPosts`. The request waits up to 5 minutes per competitor.

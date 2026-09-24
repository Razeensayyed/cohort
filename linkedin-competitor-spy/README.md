# LinkedIn Competitor Spy

A Python version of the "LinkedIn competitor spying tool" idea: pull your
competitors' recent LinkedIn posts, have Claude break down what's working, and
log it all to Google Sheets.

**What you get in your sheet**

| Tab | One row per | Columns |
|---|---|---|
| `Posts` | competitor post | date, URL, likes/comments/shares, engagement score, format, topic, hook, hook type, CTA, why it worked, full text |
| `Insights` | competitor per run | strategy summary, top themes, tactics worth stealing, post ideas for *your* niche |

Re-running skips posts already in the sheet, so you can run it weekly.

## How posts are collected

| Mode | Cost | How |
|---|---|---|
| `--source apify` (default) | Free plan gives $5 of credit each month, no card needed; enough for roughly 10 competitors × 10 posts weekly | Scrapes each profile with the `harvestapi/linkedin-profile-posts` actor (no LinkedIn login or cookies needed) |
| `--source csv` | 100% free | You paste posts into `manual_posts.csv` yourself (copy `manual_posts.example.csv`) |

Claude API usage is billed separately. Expect a few cents per competitor per run.

## Setup (about 10 minutes)

1. **Install**
   ```bash
   cd linkedin-competitor-spy
   python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   cp .env.example .env
   ```

2. **Anthropic API key.** Create one at <https://console.anthropic.com/settings/keys>
   and put it in `.env` as `ANTHROPIC_API_KEY`.

3. **Apify token** (skip for CSV mode). Sign up at <https://apify.com>, then copy
   your token from *Settings → Integrations* into `APIFY_TOKEN`.

4. **Google Sheets**
   1. In <https://console.cloud.google.com>, create a project and enable the
      **Google Sheets API**.
   2. Go to *IAM & Admin → Service Accounts*, create a service account, then
      *Keys → Add key → JSON*. Save the file as `service_account.json` in this folder.
   3. Create a blank Google Sheet and **share it (Editor) with the service
      account's email** (`...@...iam.gserviceaccount.com`).
   4. Copy the sheet ID from its URL (`docs.google.com/spreadsheets/d/<THIS>/edit`)
      into `GOOGLE_SHEET_ID`.

5. **Competitors.** Edit `competitors.csv` with names and LinkedIn profile URLs.
   Set `MY_NICHE` in `.env` so the content ideas fit you.

## Run

```bash
python spy.py --dry-run          # test: prints the analysis, writes nothing
python spy.py                    # full run → Google Sheet
python spy.py --source csv       # free mode
python spy.py --max-posts 20 --days 14
```

To run it weekly, add a cron job (macOS/Linux, `crontab -e`) that runs every Monday at 9am:
```
0 9 * * 1 cd /path/to/linkedin-competitor-spy && venv/bin/python spy.py >> spy.log 2>&1
```
On Windows, use Task Scheduler.

## Troubleshooting

- **Posts come back with empty text or zero likes.** Apify actors differ in their
  output fields. Run `python spy.py --dry-run --dump-raw` to see a raw item, then
  add the field names to `normalize_apify_item()` in `spy.py`.
- **Using a different Apify actor.** Set `APIFY_ACTOR` and `APIFY_INPUT_JSON` in `.env`.
  `{url}` and `{max_posts}` get filled in for each competitor.
- **`PERMISSION_DENIED` from Google.** The sheet isn't shared with the service
  account's email.

Scraping LinkedIn is against LinkedIn's Terms of Service. Keep volumes modest and
only use public post data.

## Prefer n8n?

The same pipeline is available as an importable n8n workflow in [`n8n/`](n8n/README.md).

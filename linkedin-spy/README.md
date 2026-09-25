# LinkedIn competitor tracker

A daily Python job that tracks competitors' LinkedIn company pages and appends the results to a Google Sheet:

| Tab | What goes in it |
|---|---|
| **Digest** | One row per competitor per day: new posts, hot posts, new jobs, open jobs, followers, 7-day follower change, top new post |
| **AI Summary** | Optional daily written analysis (needs an Anthropic API key) |
| **Posts** | Every new post with its engagement, and whether it's "hot" (2x or more the company's usual engagement). The Type column says whether it came from a company page or a tracked person. |
| **Jobs** | Every newly opened job: title, location, link |
| **Followers** | Daily follower count per competitor, ready for a line chart |
| **Winners** | Posts that got 2x or more their account's *usual* engagement, ranked, with a topic each (replaced on every run) |
| **Winning Topics** | Topics ranked by how often they win, with the best post and why it works (replaced on every run) |

**Caution:** LinkedIn's terms forbid automated scraping. This tool keeps the risk low: it runs once a day at human speed and uses your normal account. It reads company pages, plus (optionally) the own public posts of up to 5 people you list. See "Tracking people" below. Don't run it more often, and don't add dozens of companies. Run it from your own computer, not a cloud server.

---

## Setup (about 20 minutes, once)

### 1. Install

```bash
cd linkedin-spy
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
playwright install chromium
cp .env.example .env
```

### 2. Create the Google Sheet and give the script access

1. Go to <https://console.cloud.google.com/>, create a project (any name).
2. **APIs & Services → Library**: enable **Google Sheets API** and **Google Drive API**.
3. **APIs & Services → Credentials → Create credentials → Service account**. Give it any name, then click **Done**.
4. Click the service account, go to **Keys → Add key → Create new key → JSON**. A file downloads.
5. Move that file into this folder as `service_account.json`. It's git-ignored. Never commit or share it.
6. Create an empty Google Sheet. Click **Share** and add the service account's email address (it's the `client_email` value in the JSON, e.g. `something@your-project.iam.gserviceaccount.com`) as an **Editor**.
7. Copy the sheet ID from its URL, `docs.google.com/spreadsheets/d/`**`THIS_PART`**`/edit`, into `.env` as `GOOGLE_SHEET_ID`.

(Optional) Add your `ANTHROPIC_API_KEY` to `.env` to get the AI Summary tab and AI topic labels in Winning Topics. It uses `claude-opus-5` by default; set `ANTHROPIC_MODEL` to override.

### 3. Add your competitors

**Automatically** (after step 4, since it needs the LinkedIn login):
```bash
python discover.py
```
It asks for your niche, finds candidate competitors, opens each one on LinkedIn to check it exists (dropping made-up or dead links), then shows a numbered list. You pick with `1,3,5-7`, `all` or `none`, and it adds your picks to `competitors.yaml`, company IDs included.
- With `ANTHROPIC_API_KEY` in `.env`: Claude searches the web for companies and up to 5 public-facing people in your niche. Cost: a few cents per search.
- Without a key: it uses LinkedIn's company search (companies only).
- Run it again at any time to add more. Existing entries are kept, and the 5-person limit is enforced. The file is rewritten, so comments in it are lost.

**Or by hand:** edit `competitors.yaml`. Replace the placeholders with each competitor's name and the slug from their page URL (`linkedin.com/company/`**`slug`**`/`).

### Tracking people (optional)

You can also track the **own public posts** of up to **5** public-facing people, such as a competitor's founder. Add them to `competitors.yaml`:
```yaml
people:
  - name: Jane Founder
    company: Acme
    slug: jane-founder          # from linkedin.com/in/jane-founder/ (or paste the whole URL)
people_retention_days: 90
```
Limits built into the tool:
- Only their recent-activity page is opened. Profile details (job history, contacts, connections) are never read.
- Only posts they wrote themselves are kept. Reposts and posts they liked are skipped.
- After `people_retention_days` (default 90), their post text and links are erased from `data/spy.db`, and their rows are deleted from the Digest and Posts tabs. The AI Summary tab isn't cleaned automatically.
- More than 5 people is rejected.

Please keep it to people who post publicly as the voice of their company. Personal profiles are **personal data**: privacy laws (e.g. GDPR if the person is in the EU) can apply even though the posts are public, and LinkedIn flags automated visits to profiles faster than visits to company pages. This isn't legal advice. If you're doing this for a company, check with whoever handles legal or compliance.

### 4. Log in to LinkedIn once

```bash
python login.py
```
A browser window opens. Log in yourself (including 2FA), wait for your feed, then press Enter in the terminal. The session is saved in `data/browser_profile/`. Run this again whenever the tracker says the session expired.

### 5. Fill in company IDs

```bash
python find_company_ids.py
```
This fills in the `company_id` values that the jobs tracker needs. Note that it rewrites `competitors.yaml`, so comments in that file are lost.

### 6. Test it, then seed the history

```bash
python main.py --dry-run --show     # watch the browser; prints what would go to the Sheet
python main.py --seed               # stores today's posts/jobs as "already known"
```
Without `--seed`, the first real run would report every existing post and job as new.

### 7. Schedule it daily

**Mac/Linux:** run `crontab -e` and add (use your real path):
```
17 8 * * * cd /full/path/to/linkedin-spy && .venv/bin/python main.py >> data/run.log 2>&1
```
**Windows:** in Task Scheduler, create a daily task. Program: `C:\path\to\linkedin-spy\.venv\Scripts\python.exe`. Arguments: `main.py`. Start in: `C:\path\to\linkedin-spy`.

The computer must be on (and not asleep) at that time.

---

## Winning posts and topics

LinkedIn only shows view counts to a post's author, so the tracker uses **engagement** (reactions + comments + reposts) instead. A post with unusually high reach also collects unusually many reactions.

- A post **wins** when its engagement is at least **2x the median** of that account's other posts. Comparing each account with itself keeps a big account from drowning out a small one.
- Posts less than 2 days old are skipped, because they're still collecting engagement. The exception is posts found on an account's first run, which are older backlog.
- An account needs at least 5 posts before it gets a baseline.
- **Topics:** with `ANTHROPIC_API_KEY` set, Claude labels each post with a topic and explains why the winning topics work. Without a key, the tool lists the words and hashtags that appear far more often in winning posts.

The daily `python main.py` refreshes both tabs. To run just the analysis on the data you already have (it doesn't visit LinkedIn):
```bash
python find_winners.py             # write the Winners and Winning Topics tabs
python find_winners.py --dry-run   # print instead
python find_winners.py --x 3       # stricter: 3x the usual engagement
```

## Commands

| Command | What it does |
|---|---|
| `python main.py` | Normal daily run |
| `python main.py --dry-run` | Prints what would be written; saves nothing |
| `python main.py --seed` | Fills history without writing to the Sheet |
| `python main.py --show` | Shows the browser window |
| `python main.py --debug` | Saves each posts page's HTML to `data/debug/` |
| `python main.py --no-posts` | Jobs only (no login needed) |
| `python main.py --no-winners` | Skip the Winners / Winning Topics refresh |
| `python find_winners.py` | Winners analysis only, from saved data |
| `python discover.py` | Find competitors for your niche and add the ones you pick |
| `python -m pytest` | Runs the tests (no network needed) |

## When something breaks

| Symptom | Fix |
|---|---|
| `0 own posts` for a person | Their activity page layout differs. Run `python main.py --debug --dry-run` and check `data/debug/person_*.html` (update `POST_HEADER` / `POST_ACTOR_LINK` in `spy/parsers.py`). |
| `0 posts` for every company | LinkedIn changed its HTML. Run `python main.py --debug --dry-run`, then update the selectors at the top of `spy/parsers.py` using `data/debug/*.html` (or send that file to whoever maintains this). |
| `STOPPED: LinkedIn redirected to .../checkpoint` or `/authwall` | Run `python login.py` again. If it keeps happening, run less often. |
| Followers show as empty | The "N followers" text changed. See `parse_followers` in `spy/parsers.py`. |
| `[jobs] ... rate limited (429)` | Wait a day. Lower `max_pages` in `spy/collect_jobs.py`. |
| `SpreadsheetNotFound` / `PermissionError` | The sheet isn't shared with the service account email, or `GOOGLE_SHEET_ID` is wrong. |

If writing to the Sheet fails, nothing is marked as seen, so the next run picks everything up again.

## How it works

```
competitors.yaml
   ├─ spy/config.py          validates it (people limit, full URLs accepted)
   ├─ spy/collect_posts.py   Playwright + your saved session → followers, posts, people's own posts
   └─ spy/collect_jobs.py    public jobs endpoint (no login) → open jobs
          ↓ spy/parsers.py   HTML → data (all LinkedIn selectors live here)
   spy/db.py                 SQLite history in data/spy.db → what's new since last run
   spy/analyze.py            hot-post detection, digest rows, optional AI summary
   spy/winners.py            outlier posts vs each account's median, topic labelling
   spy/sheets.py             append rows to the Google Sheet
```

"""LinkedIn Competitor Spy.

Pulls your competitors' recent LinkedIn posts, has Claude break down what is
working (hooks, topics, formats, CTAs), and logs everything to Google Sheets.

Usage:
    python spy.py                     # scrape with Apify, analyze, write to Sheets
    python spy.py --source csv        # free mode: read posts from manual_posts.csv
    python spy.py --dry-run           # print results instead of writing to Sheets
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Literal

import anthropic
from dotenv import load_dotenv
from pydantic import BaseModel, ValidationError

HERE = Path(__file__).parent
load_dotenv(HERE / ".env")

MODEL = os.getenv("CLAUDE_MODEL", "claude-opus-5")
APIFY_ACTOR = os.getenv("APIFY_ACTOR", "harvestapi/linkedin-profile-posts")

POSTS_TAB = "Posts"
INSIGHTS_TAB = "Insights"
POSTS_HEADER = [
    "scraped_at", "competitor", "posted_at", "post_url", "likes", "comments",
    "shares", "engagement_score", "format", "topic", "hook", "hook_type",
    "cta", "why_it_worked", "post_text",
]
INSIGHTS_HEADER = ["run_at", "competitor", "posts_analyzed", "summary", "top_themes",
                   "what_to_steal", "content_ideas"]


# ---------------------------------------------------------------------------
# Data models
# ---------------------------------------------------------------------------

class Post(BaseModel):
    competitor: str
    url: str
    text: str
    posted_at: str = ""
    likes: int = 0
    comments: int = 0
    shares: int = 0

    @property
    def engagement_score(self) -> int:
        # Comments and reshares signal more intent than a like.
        return self.likes + 2 * self.comments + 3 * self.shares


class PostAnalysis(BaseModel):
    post_index: int
    format: Literal["text", "image", "carousel", "video", "poll", "article", "other"]
    topic: str
    hook: str
    hook_type: str
    cta: str
    why_it_worked: str


class CompetitorReport(BaseModel):
    posts: list[PostAnalysis]
    summary: str
    top_themes: list[str]
    what_to_steal: list[str]
    content_ideas: list[str]


# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------

def load_competitors(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as f:
        rows = [r for r in csv.DictReader(f) if (r.get("linkedin_url") or "").strip()]
    if not rows:
        sys.exit(f"No competitors found in {path}. Add rows with name,linkedin_url.")
    return rows


def _to_int(value) -> int:
    try:
        return int(float(str(value).replace(",", "")))
    except (TypeError, ValueError):
        return 0


def _first(item: dict, *paths, default=None):
    """Return the first non-empty value among dotted paths like 'engagement.likes'."""
    for path in paths:
        cur = item
        for key in path.split("."):
            cur = cur.get(key) if isinstance(cur, dict) else None
            if cur is None:
                break
        if cur not in (None, "", [], {}):
            return cur
    return default


def normalize_apify_item(item: dict, competitor: str) -> Post | None:
    """Map a scraped post to our Post model.

    Different Apify LinkedIn actors name fields differently, so this checks the
    common variants. If you switch actors and fields come back empty, run with
    --dump-raw and add the new field names here.
    """
    text = _first(item, "content", "text", "postText", "commentary", "post_text", default="")
    url = _first(item, "linkedinUrl", "postUrl", "url", "post_url", "shareUrl", default="")
    if not text and not url:
        return None
    posted_at = _first(item, "postedAt.date", "postedAt", "posted_at.date", "posted_at",
                       "date", "publishedAt", "timeSincePosted", default="")
    if isinstance(posted_at, dict):
        posted_at = posted_at.get("date") or posted_at.get("timestamp") or ""
    return Post(
        competitor=competitor,
        url=str(url),
        text=str(text),
        posted_at=str(posted_at),
        likes=_to_int(_first(item, "engagement.likes", "stats.total_reactions", "numLikes",
                             "likes", "reactionsCount", "totalReactionCount", default=0)),
        comments=_to_int(_first(item, "engagement.comments", "stats.comments", "numComments",
                                "comments", "commentsCount", default=0)),
        shares=_to_int(_first(item, "engagement.shares", "stats.reposts", "numShares",
                              "shares", "repostsCount", default=0)),
    )


def fetch_posts_apify(competitors: list[dict], max_posts: int, dump_raw: bool) -> list[Post]:
    from apify_client import ApifyClient

    token = os.getenv("APIFY_TOKEN")
    if not token:
        sys.exit("APIFY_TOKEN is not set. Add it to .env, or use --source csv for free mode.")
    client = ApifyClient(token)

    posts: list[Post] = []
    for comp in competitors:
        name, url = comp["name"].strip(), comp["linkedin_url"].strip()
        print(f"Scraping {name} ({url}) ...")
        # Input for harvestapi/linkedin-profile-posts. If you use another actor,
        # set APIFY_INPUT_JSON in .env; "{url}" and "{max_posts}" are filled in.
        template = os.getenv("APIFY_INPUT_JSON")
        if template:
            run_input = json.loads(template.replace("{url}", url).replace('"{max_posts}"', str(max_posts)))
        else:
            run_input = {"targetUrls": [url], "maxPosts": max_posts}
        run = client.actor(APIFY_ACTOR).call(run_input=run_input)
        if run is None:
            print(f"  ! Apify run failed for {name}, skipping")
            continue
        items = list(client.dataset(run["defaultDatasetId"]).iterate_items())
        if dump_raw and items:
            print(json.dumps(items[0], indent=2, default=str)[:3000])
        comp_posts = [p for p in (normalize_apify_item(i, name) for i in items) if p]
        print(f"  got {len(comp_posts)} posts")
        posts.extend(comp_posts[:max_posts])
    return posts


def fetch_posts_csv(path: Path) -> list[Post]:
    """Free mode: paste posts yourself into manual_posts.csv."""
    if not path.exists():
        sys.exit(f"{path} not found. Copy manual_posts.example.csv to {path.name} and fill it in.")
    posts = []
    with path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if not (row.get("text") or "").strip():
                continue
            posts.append(Post(
                competitor=row["competitor"].strip(),
                url=(row.get("post_url") or "").strip(),
                text=row["text"].strip(),
                posted_at=(row.get("posted_at") or "").strip(),
                likes=_to_int(row.get("likes")),
                comments=_to_int(row.get("comments")),
                shares=_to_int(row.get("shares")),
            ))
    return posts


def filter_recent(posts: list[Post], days: int) -> list[Post]:
    """Drop posts older than `days` when the date is parseable; keep the rest."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    kept = []
    for p in posts:
        try:
            dt = datetime.fromisoformat(p.posted_at.replace("Z", "+00:00"))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            if dt < cutoff:
                continue
        except ValueError:
            pass
        kept.append(p)
    return kept


# ---------------------------------------------------------------------------
# Claude analysis
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You are a LinkedIn content strategist doing competitive research.
You will get one competitor's recent posts with engagement numbers. For each post,
identify its format, topic, opening hook (quote the first line), hook type (e.g.
contrarian take, personal story, number/list, question, bold claim), call to action
(or "none"), and in one or two sentences why it performed the way it did relative
to the competitor's other posts.

Then summarize the competitor's overall strategy, the themes that drive the most
engagement, concrete tactics worth borrowing, and specific post ideas the reader
could write. Tailor the ideas to the reader's niche when one is given. Base
everything on the posts provided; do not invent metrics."""


def analyze_competitor(client: anthropic.Anthropic, competitor: str, posts: list[Post],
                       niche: str) -> CompetitorReport:
    posts_block = "\n\n".join(
        f"<post index=\"{i}\" likes=\"{p.likes}\" comments=\"{p.comments}\" "
        f"shares=\"{p.shares}\" posted_at=\"{p.posted_at}\">\n{p.text}\n</post>"
        for i, p in enumerate(posts)
    )
    user_msg = (
        f"Competitor: {competitor}\n"
        f"My niche: {niche or 'not specified'}\n\n"
        f"{posts_block}\n\n"
        f"Analyze every post (indexes 0 to {len(posts) - 1})."
    )

    response = client.messages.create(
        model=MODEL,
        max_tokens=16000,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": user_msg}],
        output_config={
            "effort": "medium",
            "format": {"type": "json_schema", "schema": _strict_schema(CompetitorReport)},
        },
        # If a safety classifier declines the request, retry server-side on
        # Anthropic's recommended fallback model instead of failing the run.
        extra_headers={"anthropic-beta": "server-side-fallback-2026-07-01"},
        extra_body={"fallbacks": "default"},
    )
    if response.stop_reason == "refusal":
        raise RuntimeError(f"Claude declined to analyze {competitor}")
    if response.stop_reason == "max_tokens":
        raise RuntimeError(f"Analysis for {competitor} was cut off; lower --max-posts")
    text = next(b.text for b in response.content if b.type == "text")
    return CompetitorReport.model_validate_json(text)


def _strict_schema(model: type[BaseModel]) -> dict:
    """Pydantic JSON schema with additionalProperties: false everywhere, as structured outputs require."""
    schema = model.model_json_schema()

    def fix(node):
        if isinstance(node, dict):
            if node.get("type") == "object":
                node["additionalProperties"] = False
                node["required"] = list(node.get("properties", {}))
            node.pop("title", None)
            for v in node.values():
                fix(v)
        elif isinstance(node, list):
            for v in node:
                fix(v)

    fix(schema)
    return schema


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def build_rows(posts: list[Post], report: CompetitorReport, run_at: str) -> list[list]:
    by_index = {a.post_index: a for a in report.posts}
    rows = []
    for i, p in enumerate(posts):
        a = by_index.get(i)
        rows.append([
            run_at, p.competitor, p.posted_at, p.url, p.likes, p.comments, p.shares,
            p.engagement_score,
            a.format if a else "", a.topic if a else "", a.hook if a else "",
            a.hook_type if a else "", a.cta if a else "", a.why_it_worked if a else "",
            p.text[:45000],  # Sheets caps a cell at 50k characters
        ])
    return rows


def insight_row(competitor: str, n_posts: int, report: CompetitorReport, run_at: str) -> list:
    bullets = lambda items: "\n".join(f"• {x}" for x in items)  # noqa: E731
    return [run_at, competitor, n_posts, report.summary, bullets(report.top_themes),
            bullets(report.what_to_steal), bullets(report.content_ideas)]


def open_sheet():
    import gspread

    sheet_id = os.getenv("GOOGLE_SHEET_ID")
    creds = os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", str(HERE / "service_account.json"))
    if not sheet_id:
        sys.exit("GOOGLE_SHEET_ID is not set. Add it to .env or run with --dry-run.")
    if not Path(creds).exists():
        sys.exit(f"Google service account file not found at {creds}. See README.md.")
    spreadsheet = gspread.service_account(filename=creds).open_by_key(sheet_id)

    def tab(title: str, header: list[str]):
        try:
            ws = spreadsheet.worksheet(title)
        except gspread.WorksheetNotFound:
            ws = spreadsheet.add_worksheet(title=title, rows=1000, cols=len(header))
        if ws.row_values(1) != header:
            ws.update([header], "A1")
            ws.freeze(rows=1)
        return ws

    return tab(POSTS_TAB, POSTS_HEADER), tab(INSIGHTS_TAB, INSIGHTS_HEADER)


def existing_urls(ws) -> set[str]:
    col = POSTS_HEADER.index("post_url") + 1
    return {u for u in ws.col_values(col)[1:] if u}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", choices=["apify", "csv"], default=os.getenv("SOURCE", "apify"),
                    help="apify = scrape automatically; csv = read manual_posts.csv (free)")
    ap.add_argument("--competitors", type=Path, default=HERE / "competitors.csv")
    ap.add_argument("--posts-file", type=Path, default=HERE / "manual_posts.csv")
    ap.add_argument("--max-posts", type=int, default=int(os.getenv("MAX_POSTS", "10")),
                    help="posts per competitor (default 10)")
    ap.add_argument("--days", type=int, default=int(os.getenv("DAYS", "30")),
                    help="only analyze posts from the last N days (default 30)")
    ap.add_argument("--dry-run", action="store_true", help="print results, don't write to Sheets")
    ap.add_argument("--dump-raw", action="store_true", help="print one raw Apify item per competitor")
    args = ap.parse_args()

    if args.source == "apify":
        posts = fetch_posts_apify(load_competitors(args.competitors), args.max_posts, args.dump_raw)
    else:
        posts = fetch_posts_csv(args.posts_file)
    posts = filter_recent(posts, args.days)
    if not posts:
        sys.exit("No posts to analyze.")

    posts_ws = insights_ws = None
    if not args.dry_run:
        posts_ws, insights_ws = open_sheet()
        seen = existing_urls(posts_ws)
        before = len(posts)
        posts = [p for p in posts if not p.url or p.url not in seen]
        print(f"Skipping {before - len(posts)} posts already in the sheet")
        if not posts:
            print("Nothing new since the last run.")
            return

    by_competitor: dict[str, list[Post]] = {}
    for p in posts:
        by_competitor.setdefault(p.competitor, []).append(p)

    client = anthropic.Anthropic()
    niche = os.getenv("MY_NICHE", "")
    run_at = datetime.now().strftime("%Y-%m-%d %H:%M")
    post_rows, insight_rows = [], []

    for competitor, comp_posts in by_competitor.items():
        comp_posts.sort(key=lambda p: p.engagement_score, reverse=True)
        print(f"Analyzing {len(comp_posts)} posts from {competitor} ...")
        try:
            report = analyze_competitor(client, competitor, comp_posts, niche)
        except (RuntimeError, ValidationError, anthropic.APIError) as e:
            print(f"  ! {e}")
            continue
        post_rows += build_rows(comp_posts, report, run_at)
        insight_rows.append(insight_row(competitor, len(comp_posts), report, run_at))

    if args.dry_run:
        for row in insight_rows:
            print("\n" + "=" * 70)
            for key, val in zip(INSIGHTS_HEADER, row):
                print(f"{key}:\n{val}\n" if "\n" in str(val) else f"{key}: {val}")
        print(f"\n(dry run) {len(post_rows)} post rows would be written.")
        return

    if post_rows:
        posts_ws.append_rows(post_rows, value_input_option="RAW")
    if insight_rows:
        insights_ws.append_rows(insight_rows, value_input_option="RAW")
    print(f"Done: wrote {len(post_rows)} posts and {len(insight_rows)} competitor summaries "
          f"to https://docs.google.com/spreadsheets/d/{os.getenv('GOOGLE_SHEET_ID')}")


if __name__ == "__main__":
    main()

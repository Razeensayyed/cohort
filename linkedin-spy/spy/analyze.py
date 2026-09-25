"""Turn what's new since the last run into rows for the report."""
import os
from datetime import date

from spy import db

HOT_MULTIPLIER = 2.0   # a post is "hot" at 2x the company's usual engagement
MIN_HISTORY = 5        # ...but only once we know at least this many older posts


def engagement(p):
    return p["reactions"] + p["comments"] + p["reposts"]


def mark_hot(c, company, new_posts):
    """Adds p['hot'] (bool) and p['vs_avg'] (e.g. 3.1) to each new post."""
    avg, n = db.avg_engagement(c, company, exclude=[p["urn"] for p in new_posts])
    for p in new_posts:
        p["vs_avg"] = round(engagement(p) / avg, 1) if avg else None
        p["hot"] = bool(n >= MIN_HISTORY and avg and engagement(p) >= HOT_MULTIPLIER * avg)
    return new_posts


def digest_rows(c, changes, run_started, today=None):
    today = (today or date.today()).isoformat()
    rows = []
    for company, ch in changes.items():
        posts = sorted(ch["new_posts"], key=engagement, reverse=True)
        top = posts[0] if posts else None
        change = db.follower_change(c, company)
        rows.append({
            "date": today,
            "company": company,
            "type": "Person" if ch.get("kind") == "person" else "Company",
            "new_posts": len(posts),
            "hot_posts": sum(p.get("hot", False) for p in posts),
            "new_jobs": len(ch["new_jobs"]),
            "open_jobs": db.open_job_count(c, company, run_started) if ch.get("jobs_ok") else "",
            "followers": ch.get("followers") or "",
            "follower_change_7d": "" if change is None else change,
            "top_post": top["text"][:300] if top else "",
            "top_post_url": top["url"] if top else "",
        })
    return rows


def raw_text(changes):
    """Plain-text dump of the day's changes, used as input for the AI summary."""
    lines = []
    for company, ch in changes.items():
        who = " (a person: their own public posts)" if ch.get("kind") == "person" else ""
        lines.append(f"## {company}{who}")
        if ch.get("followers"):
            lines.append(f"Followers: {ch['followers']:,}")
        for p in ch["new_posts"]:
            hot = " [HOT: well above their usual engagement]" if p.get("hot") else ""
            lines.append(f"- NEW POST ({engagement(p)} engagements){hot}: {p['text'][:600]}")
        for j in ch["new_jobs"]:
            lines.append(f"- NEW JOB: {j['title']} | {j['location']}")
        if not ch["new_posts"] and not ch["new_jobs"]:
            lines.append("- no new activity")
    return "\n".join(lines)


def ai_summary(raw):
    """Optional. Returns '' when ANTHROPIC_API_KEY isn't set or the call fails."""
    if not os.getenv("ANTHROPIC_API_KEY"):
        return ""
    try:
        import anthropic
        msg = anthropic.Anthropic().beta.messages.create(
            model=os.getenv("ANTHROPIC_MODEL") or "claude-opus-5",
            max_tokens=16000,
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
            messages=[{"role": "user", "content": (
                "You are a competitive-intelligence analyst. Below is today's new LinkedIn "
                "activity from our competitors. Write a short digest in plain text (no markdown "
                "tables): 1) the top 3 strategic signals, 2) one or two bullets per competitor "
                "(messaging themes; what their hiring suggests they're building or where they're "
                "expanding), 3) one suggested action for us. Only use facts in the data.\n\n"
                + raw)}],
        )
        if msg.stop_reason == "refusal":
            print("[ai] summary declined by the model; skipped")
            return ""
        return "".join(b.text for b in msg.content if b.type == "text").strip()
    except Exception as e:
        print(f"[ai] summary skipped: {e}")
        return ""

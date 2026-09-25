"""Find posts that did far better than usual for their account, and the topics behind them.

LinkedIn doesn't show other people's view counts, so engagement (reactions + comments +
reposts) is used as the stand-in: a post that reached unusually many people also
collects unusually many reactions.

A post "wins" when its engagement is at least WIN_MULTIPLIER x the median of its
account's other posts. Very fresh posts are left out (they are still collecting
engagement), except for posts found on an account's first run, which are older backlog.
"""
import json
import os
import re
import statistics
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

WIN_MULTIPLIER = 2.0
MIN_POSTS = 5            # an account needs this many judged posts before it has a baseline
MIN_AGE_DAYS = 2
LOOKBACK_DAYS = 90
MAX_POSTS_FOR_AI = 200

STOPWORDS = set("""
about above after again against all also always among another any are around because been before
being below between both but by came can cannot come could did does doing done down during each
even ever every few first for from get gets getting give given going good got great had has have
having here how however into its just know last like made make makes making many more most much
must need never next now off often once one only other our ours out over own people really right
said same see should since some still such sure take than that the their them then there these
they thing things think this those though through time today too under until upon very want was
way ways well went were what when where which while who whom why will with within without would
year years yet you your yours new day days let lets it's i'm we're you're don't can't here's
that's what's there's isn't doesn't didn't won't just via per
""".split())


def load_posts(c, lookback_days=LOOKBACK_DAYS, now=None):
    now = now or datetime.now(timezone.utc)
    since = (now - timedelta(days=lookback_days)).isoformat(timespec="seconds")
    rows = c.execute(
        "SELECT urn, company, source, text, url, reactions, comments, reposts, first_seen "
        "FROM posts WHERE text != '' AND first_seen >= ?", (since,)).fetchall()
    first_run = {r["company"]: r["d"] for r in c.execute(
        "SELECT company, MIN(substr(first_seen, 1, 10)) d FROM posts GROUP BY company")}
    mature_before = (now - timedelta(days=MIN_AGE_DAYS)).isoformat(timespec="seconds")
    posts = []
    for r in rows:
        p = dict(r)
        p["engagement"] = p["reactions"] + p["comments"] + p["reposts"]
        p["mature"] = (p["first_seen"] <= mature_before
                       or p["first_seen"][:10] == first_run.get(p["company"]))
        posts.append(p)
    return posts


def score_posts(posts, multiplier=WIN_MULTIPLIER):
    """Adds p['x_usual'] and p['winner'] to every judged (mature) post; returns them."""
    by_account = defaultdict(list)
    for p in posts:
        if p["mature"]:
            by_account[p["company"]].append(p)
    judged = []
    for account, items in by_account.items():
        if len(items) < MIN_POSTS:
            continue
        for p in items:
            others = [o["engagement"] for o in items if o is not p]
            baseline = statistics.median(others) or 1
            p["x_usual"] = round(p["engagement"] / baseline, 1)
            p["winner"] = p["x_usual"] >= multiplier
            judged.append(p)
    return judged


# ---------- topics: Claude when an API key is set, keyword comparison otherwise ----------

_TOPIC_SCHEMA = {
    "type": "object",
    "properties": {
        "topics": {"type": "array", "items": {
            "type": "object",
            "properties": {"name": {"type": "string"}, "why_it_works": {"type": "string"}},
            "required": ["name", "why_it_works"], "additionalProperties": False}},
        "labels": {"type": "array", "items": {
            "type": "object",
            "properties": {"id": {"type": "integer"}, "topic": {"type": "string"}},
            "required": ["id", "topic"], "additionalProperties": False}},
    },
    "required": ["topics", "labels"],
    "additionalProperties": False,
}


def topics_with_ai(judged):
    """Returns ({urn: topic}, {topic: why_it_works}), or None if unavailable/failed."""
    if not os.getenv("ANTHROPIC_API_KEY") or not judged:
        return None
    import anthropic

    sample = sorted(judged, key=lambda p: p["first_seen"], reverse=True)[:MAX_POSTS_FOR_AI]
    lines = [json.dumps({"id": i, "account": p["company"], "x_usual": p["x_usual"],
                         "winner": p["winner"], "text": p["text"][:700]}, ensure_ascii=False)
             for i, p in enumerate(sample)]
    prompt = (
        "These are LinkedIn posts from accounts we watch (competitors and public-facing "
        "leaders). x_usual is the post's engagement divided by that account's typical post; "
        f"winner=true means it got at least {WIN_MULTIPLIER}x the usual engagement.\n\n"
        "1. Pick 5-12 short, specific topic names (2-4 words, e.g. 'AI product launches', "
        "'Personal career stories') that together cover these posts. Label every post with "
        "exactly one of them, using its id.\n"
        "2. For each topic, write one sentence on why posts on it do or don't outperform, "
        "based on the winners vs the rest (hook, format, angle). Only use what's in the data.\n\n"
        "Posts (one JSON object per line):\n" + "\n".join(lines))
    try:
        response = anthropic.Anthropic().beta.messages.create(
            model=os.getenv("ANTHROPIC_MODEL") or "claude-opus-5",
            max_tokens=16000,
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
            output_config={"effort": "low",
                           "format": {"type": "json_schema", "schema": _TOPIC_SCHEMA}},
            messages=[{"role": "user", "content": prompt}],
        )
        if response.stop_reason == "refusal":
            print("[winners] AI topic labelling declined; using keyword topics instead")
            return None
        data = json.loads(next(b.text for b in response.content if b.type == "text"))
    except Exception as e:
        print(f"[winners] AI topic labelling failed ({e}); using keyword topics instead")
        return None
    labels = {sample[x["id"]]["urn"]: x["topic"] for x in data["labels"]
              if 0 <= x["id"] < len(sample)}
    return labels, {t["name"]: t["why_it_works"] for t in data["topics"]}


def _terms(text):
    words = re.findall(r"#?[a-zA-Z][a-zA-Z'-]{3,}", text.lower())
    return {w for w in words if w.lstrip("#") not in STOPWORDS}


def topics_with_keywords(judged, max_topics=12):
    """Words/hashtags that show up far more in winners than in the rest."""
    winners = [p for p in judged if p["winner"]]
    if not winners:
        return {}, {}
    base_rate = len(winners) / len(judged)
    in_posts, in_winners = Counter(), Counter()
    for p in judged:
        terms = _terms(p["text"])
        in_posts.update(terms)
        if p["winner"]:
            in_winners.update(terms)
    lift = {t: (in_winners[t] / in_posts[t]) / base_rate
            for t in in_winners if in_winners[t] >= 2}
    top = sorted(lift, key=lambda t: (lift[t], in_winners[t]), reverse=True)[:max_topics]
    labels = {}
    for p in judged:
        found = [t for t in top if t in _terms(p["text"])]
        labels[p["urn"]] = found[0] if found else "(other)"
    why = {t: f"Posts mentioning '{t}' win {lift[t]:.1f}x as often as the average post"
           for t in top}
    return labels, why


# ---------- report rows ----------

WINNERS_HEADER = ["Rank", "Account", "Type", "x usual", "Engagement", "Topic",
                  "First seen", "Post", "URL"]
TOPICS_HEADER = ["Topic", "Posts", "Winning posts", "Win rate", "Median x usual",
                 "Best post (x usual)", "Best post URL", "Why it works"]


def analyze(c, multiplier=WIN_MULTIPLIER, use_ai=True, top_n=100):
    """Returns (winners_rows, topics_rows, note) ready for the Sheet."""
    judged = score_posts(load_posts(c), multiplier)
    if not judged:
        return [], [], (f"Not enough data yet: each account needs {MIN_POSTS}+ posts "
                        f"older than {MIN_AGE_DAYS} days.")
    result = topics_with_ai(judged) if use_ai else None
    source = "AI" if result else "keywords"
    labels, why = result or topics_with_keywords(judged)

    winners = sorted((p for p in judged if p["winner"]), key=lambda p: p["x_usual"],
                     reverse=True)[:top_n]
    winners_rows = [[i, p["company"], "Person" if p["source"] == "person" else "Company",
                     p["x_usual"], p["engagement"], labels.get(p["urn"], ""),
                     p["first_seen"][:10], p["text"][:500], p["url"]]
                    for i, p in enumerate(winners, start=1)]

    groups = defaultdict(list)
    if source == "AI":
        for p in judged:
            if p["urn"] in labels:
                groups[labels[p["urn"]]].append(p)
    else:  # a keyword topic covers every post containing it (posts can be in several)
        for p in judged:
            terms = _terms(p["text"])
            hits = [t for t in why if t in terms]
            for t in hits or ["(other)"]:
                groups[t].append(p)
    topics_rows = []
    for topic, items in groups.items():
        wins = [p for p in items if p["winner"]]
        best = max(items, key=lambda p: p["x_usual"])
        topics_rows.append([topic, len(items), len(wins), f"{len(wins) / len(items):.0%}",
                            statistics.median(p["x_usual"] for p in items),
                            best["x_usual"], best["url"], why.get(topic, "")])
    topics_rows.sort(key=lambda r: (r[2], r[4]), reverse=True)

    note = (f"{len(winners)} winning posts out of {len(judged)} judged "
            f"(>= {multiplier}x the account's usual engagement); topics by {source}.")
    return winners_rows, topics_rows, note

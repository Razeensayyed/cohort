"""SQLite history. Every run's result is compared against this to find what's new."""
import sqlite3
from datetime import date, datetime, timedelta, timezone

SCHEMA = """
CREATE TABLE IF NOT EXISTS posts(
    urn TEXT PRIMARY KEY, company TEXT, text TEXT, url TEXT,
    reactions INT, comments INT, reposts INT,
    first_seen TEXT, last_seen TEXT, source TEXT DEFAULT 'company');
CREATE TABLE IF NOT EXISTS jobs(
    job_id TEXT PRIMARY KEY, company TEXT, title TEXT, location TEXT,
    posted TEXT, url TEXT, first_seen TEXT, last_seen TEXT);
CREATE TABLE IF NOT EXISTS followers(
    company TEXT, day TEXT, count INT, PRIMARY KEY(company, day));
"""


def connect(path="data/spy.db"):
    c = sqlite3.connect(path)
    c.row_factory = sqlite3.Row
    c.executescript(SCHEMA)
    if "source" not in [r["name"] for r in c.execute("PRAGMA table_info(posts)")]:
        c.execute("ALTER TABLE posts ADD COLUMN source TEXT DEFAULT 'company'")  # older databases
    return c


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def upsert_post(c, p):
    """Insert or refresh a post. Returns True if it was never seen before."""
    t = _now()
    if c.execute("SELECT 1 FROM posts WHERE urn=?", (p["urn"],)).fetchone():
        c.execute("UPDATE posts SET reactions=?, comments=?, reposts=?, last_seen=? WHERE urn=?",
                  (p["reactions"], p["comments"], p["reposts"], t, p["urn"]))
        return False
    c.execute("INSERT INTO posts VALUES(?,?,?,?,?,?,?,?,?,?)",
              (p["urn"], p["company"], p["text"], p["url"], p["reactions"],
               p["comments"], p["reposts"], t, t, p.get("source", "company")))
    return True


def upsert_job(c, j):
    t = _now()
    if c.execute("SELECT 1 FROM jobs WHERE job_id=?", (j["job_id"],)).fetchone():
        c.execute("UPDATE jobs SET last_seen=? WHERE job_id=?", (t, j["job_id"]))
        return False
    c.execute("INSERT INTO jobs VALUES(?,?,?,?,?,?,?,?)",
              (j["job_id"], j["company"], j["title"], j["location"],
               j["posted"], j["url"], t, t))
    return True


def save_followers(c, company, count, day=None):
    c.execute("INSERT OR REPLACE INTO followers VALUES(?,?,?)",
              (company, (day or date.today()).isoformat(), count))


def follower_change(c, company, days=7):
    """Change between the latest count and the oldest one within `days` days."""
    rows = c.execute("SELECT day, count FROM followers WHERE company=? ORDER BY day DESC",
                     (company,)).fetchall()
    if len(rows) < 2:
        return None
    latest_day = date.fromisoformat(rows[0]["day"])
    window = [r for r in rows if (latest_day - date.fromisoformat(r["day"])).days <= days]
    if len(window) < 2:
        return None
    return window[0]["count"] - window[-1]["count"]


def avg_engagement(c, company, exclude=()):
    """Average reactions+comments+reposts of a company's known posts."""
    q = "SELECT AVG(reactions+comments+reposts) a, COUNT(*) n FROM posts WHERE company=?"
    args = [company]
    if exclude:
        q += f" AND urn NOT IN ({','.join('?' * len(exclude))})"
        args += list(exclude)
    r = c.execute(q, args).fetchone()
    return (r["a"] or 0), r["n"]


def open_job_count(c, company, since):
    """Jobs still listed in the current run (seen at or after `since`)."""
    return c.execute("SELECT COUNT(*) n FROM jobs WHERE company=? AND last_seen>=?",
                     (company, since)).fetchone()["n"]


def purge_person_posts(c, days):
    """Erase the text and link of people's posts first seen more than `days` days ago.

    Only the post ID and counts stay, so an old post is never reported as new again.
    Returns how many posts were erased.
    """
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat(timespec="seconds")
    return c.execute("UPDATE posts SET text='', url='' WHERE source='person' "
                     "AND first_seen<? AND (text!='' OR url!='')", (cutoff,)).rowcount


def now():
    return _now()

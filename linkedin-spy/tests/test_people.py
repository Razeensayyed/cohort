from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import pytest

from spy import config, db, sheets
from spy.parsers import parse_posts

FIX = Path(__file__).parent / "fixtures"


def test_person_parser_keeps_only_their_own_posts():
    html = (FIX / "person_activity.html").read_text()
    posts = parse_posts(html, "Jane Founder (Acme)", author_slug="jane-founder", source="person")
    assert [p["urn"][-1] for p in posts] == ["1"]
    assert posts[0]["text"] == "We're opening our Dubai office next month."
    assert (posts[0]["reactions"], posts[0]["comments"]) == (845, 40)
    assert posts[0]["source"] == "person"


def test_company_parser_unchanged_for_company_pages():
    html = (FIX / "company_posts.html").read_text()
    assert all(p["source"] == "company" for p in parse_posts(html, "Acme"))


def write_yaml(tmp_path, text):
    p = tmp_path / "competitors.yaml"
    p.write_text(text)
    return str(p)


def test_config_accepts_urls_and_labels_people(tmp_path):
    path = write_yaml(tmp_path, """
competitors:
  - name: Acme
    slug: https://www.linkedin.com/company/acme-corp/
people:
  - name: Jane Founder
    company: Acme
    slug: https://www.linkedin.com/in/jane-founder/
people_retention_days: 30
""")
    companies, people, retention = config.load(path)
    assert companies[0]["slug"] == "acme-corp" and companies[0]["kind"] == "company"
    assert people == [{"name": "Jane Founder (Acme)", "slug": "jane-founder", "kind": "person"}]
    assert retention == 30


def test_config_without_people_section(tmp_path):
    path = write_yaml(tmp_path, "competitors:\n  - name: Acme\n    slug: acme\n")
    _, people, retention = config.load(path)
    assert people == [] and retention == config.DEFAULT_RETENTION_DAYS


def test_config_rejects_too_many_people(tmp_path):
    people = "".join(f"  - name: P{i}\n    slug: p{i}\n" for i in range(config.MAX_PEOPLE + 1))
    with pytest.raises(SystemExit, match="limit"):
        config.load(write_yaml(tmp_path, "competitors: []\npeople:\n" + people))


def test_config_rejects_profile_url_under_competitors(tmp_path):
    path = write_yaml(tmp_path, "competitors:\n  - name: X\n    slug: https://www.linkedin.com/in/x/\n")
    with pytest.raises(SystemExit, match="wrong section"):
        config.load(path)


def test_purge_erases_old_person_posts_but_remembers_them():
    c = db.connect(":memory:")
    base = {"company": "Jane", "reactions": 1, "comments": 0, "reposts": 0}
    db.upsert_post(c, {**base, "urn": "old", "text": "old text", "url": "u1", "source": "person"})
    db.upsert_post(c, {**base, "urn": "new", "text": "new text", "url": "u2", "source": "person"})
    db.upsert_post(c, {**base, "urn": "co", "text": "company", "url": "u3", "source": "company"})
    long_ago = (datetime.now(timezone.utc) - timedelta(days=200)).isoformat()
    c.execute("UPDATE posts SET first_seen=? WHERE urn IN ('old','co')", (long_ago,))

    assert db.purge_person_posts(c, 90) == 1
    rows = {r["urn"]: (r["text"], r["url"]) for r in c.execute("SELECT * FROM posts")}
    assert rows == {"old": ("", ""), "new": ("new text", "u2"), "co": ("company", "u3")}
    # still known, so it won't come back as "new"
    assert db.upsert_post(c, {**base, "urn": "old", "text": "x", "url": "x", "source": "person"}) is False
    assert db.purge_person_posts(c, 90) == 0


def test_old_person_rows_in_sheet():
    header = sheets.TABS["Posts"]
    values = [header,
              ["2026-01-01", "Jane (Acme)", "Person"] + [""] * 8,    # old person -> delete
              ["2026-01-01", "Acme", "Company"] + [""] * 8,          # old company -> keep
              ["2026-09-20", "Jane (Acme)", "Person"] + [""] * 8,    # recent person -> keep
              ["2026-02-01", "Jane (Acme)", "Person"]]               # old, short row -> delete
    assert sheets.old_person_rows(values, 90, today=date(2026, 9, 25)) == [2, 5]
    assert sheets.old_person_rows([], 90) == []
    assert sheets.old_person_rows([["Date", "Company"]], 90) == []   # tab without Type column

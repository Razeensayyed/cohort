import json
import types
from datetime import datetime, timedelta, timezone

import pytest

from spy import db, winners

NOW = datetime(2026, 9, 25, 12, tzinfo=timezone.utc)
_load = winners.load_posts


def at_now(monkeypatch):
    monkeypatch.setattr(winners, "load_posts", lambda conn: _load(conn, now=NOW))


def add(c, urn, company, eng, text, days_ago, source="company"):
    db.upsert_post(c, {"urn": urn, "company": company, "text": text, "url": f"u/{urn}",
                       "reactions": eng, "comments": 0, "reposts": 0, "source": source})
    t = (NOW - timedelta(days=days_ago)).isoformat(timespec="seconds")
    c.execute("UPDATE posts SET first_seen=?, last_seen=? WHERE urn=?", (t, t, urn))


@pytest.fixture
def c():
    conn = db.connect(":memory:")
    # Acme: backlog found on the first run 10 days ago, then regular posts
    for i, eng in enumerate([100, 110, 90, 105, 95]):
        add(conn, f"a{i}", "Acme", eng, f"weekly product update number {i}", 10)
    add(conn, "a_win", "Acme", 400, "Behind the scenes story of our founder hiring journey", 5)
    add(conn, "a_win2", "Acme", 250, "Another founder story about hiring mistakes", 4)
    add(conn, "a_fresh", "Acme", 900, "founder story posted an hour ago", 0)   # too fresh
    # Small account: not enough posts for a baseline
    add(conn, "s1", "Small", 10, "hello", 10)
    add(conn, "s2", "Small", 99, "hello again", 10)
    return conn


def test_scoring_uses_median_and_skips_fresh_and_small_accounts(c):
    judged = winners.score_posts(winners.load_posts(c, now=NOW))
    by_urn = {p["urn"]: p for p in judged}
    assert "a_fresh" not in by_urn                    # still collecting engagement
    assert not any(u.startswith("s") for u in by_urn)  # < MIN_POSTS
    assert by_urn["a_win"]["winner"] and by_urn["a_win"]["x_usual"] == 3.9  # 400 / median 102.5
    assert by_urn["a_win2"]["winner"]
    assert not by_urn["a0"]["winner"]


def test_first_run_backlog_counts_as_mature_even_if_recent():
    c = db.connect(":memory:")
    for i in range(6):
        add(c, f"p{i}", "Jane", 50 if i else 500, f"post {i} about topic", 0, source="person")
    judged = winners.score_posts(winners.load_posts(c, now=NOW))
    assert len(judged) == 6 and [p["urn"] for p in judged if p["winner"]] == ["p0"]


def test_erased_person_posts_are_ignored():
    c = db.connect(":memory:")
    for i in range(6):
        add(c, f"p{i}", "Jane", 10, "text", 200, source="person")
    db.purge_person_posts(c, 90)
    assert winners.load_posts(c, lookback_days=365, now=NOW) == []


def test_keyword_topics_find_what_winners_share(c):
    judged = winners.score_posts(winners.load_posts(c, now=NOW))
    labels, why = winners.topics_with_keywords(judged)
    assert labels["a_win"] in ("founder", "hiring", "story")
    assert labels["a0"] == "(other)"
    assert all("as often as the average post" in w for w in why.values())


def test_analyze_rows_without_ai(c, monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    at_now(monkeypatch)
    w_rows, t_rows, note = winners.analyze(c)
    assert [r[1] for r in w_rows] == ["Acme", "Acme"] and w_rows[0][0] == 1
    assert all(len(r) == len(winners.WINNERS_HEADER) for r in w_rows)
    assert all(len(r) == len(winners.TOPICS_HEADER) for r in t_rows)
    assert "keywords" in note and "2 winning posts out of 7" in note
    for r in t_rows:  # keyword topics count every post containing the keyword
        if r[0] != "(other)":
            assert r[2] == 2  # both winners mention founder/hiring/story



def test_analyze_with_ai(c, monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test")
    at_now(monkeypatch)
    sent = {}

    def create(**kwargs):
        sent.update(kwargs)
        posts = [json.loads(l) for l in kwargs["messages"][0]["content"].split("\n") if l.startswith("{")]
        labels = [{"id": p["id"], "topic": "Founder stories" if "ounder" in p["text"] else "Product updates"}
                  for p in posts]
        body = {"topics": [{"name": "Founder stories", "why_it_works": "Personal hooks."},
                           {"name": "Product updates", "why_it_works": "Routine."}],
                "labels": labels}
        return types.SimpleNamespace(stop_reason="end_turn",
                                     content=[types.SimpleNamespace(type="text", text=json.dumps(body))])

    fake = types.SimpleNamespace(beta=types.SimpleNamespace(messages=types.SimpleNamespace(create=create)))
    import anthropic
    monkeypatch.setattr(anthropic, "Anthropic", lambda: fake)

    w_rows, t_rows, note = winners.analyze(c)
    assert sent["model"] == "claude-opus-5" and sent["fallbacks"] == "default"
    assert sent["output_config"]["format"]["type"] == "json_schema"
    assert "topics by AI" in note
    assert {r[5] for r in w_rows} == {"Founder stories"}
    top = t_rows[0]
    assert top[0] == "Founder stories" and top[2] == 2 and top[3] == "100%" and top[7] == "Personal hooks."


def test_analyze_falls_back_to_keywords_on_refusal(c, monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test")
    at_now(monkeypatch)
    refusal = types.SimpleNamespace(stop_reason="refusal", content=[])
    fake = types.SimpleNamespace(beta=types.SimpleNamespace(
        messages=types.SimpleNamespace(create=lambda **k: refusal)))
    import anthropic
    monkeypatch.setattr(anthropic, "Anthropic", lambda: fake)
    assert "keywords" in winners.analyze(c)[2]


def test_not_enough_data_message():
    w, t, note = winners.analyze(db.connect(":memory:"), use_ai=False)
    assert w == [] and t == [] and "Not enough data" in note

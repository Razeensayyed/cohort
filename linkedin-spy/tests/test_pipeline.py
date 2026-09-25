from datetime import date, timedelta

from spy import analyze, db, sheets


def post(urn, eng, company="Acme", text="hello"):
    return {"urn": urn, "company": company, "text": text, "url": f"u/{urn}",
            "reactions": eng, "comments": 0, "reposts": 0}


def job(i, company="Acme"):
    return {"job_id": str(i), "company": company, "title": f"Job {i}", "location": "Remote",
            "posted": "", "url": f"j/{i}"}


def test_new_vs_seen():
    c = db.connect(":memory:")
    assert db.upsert_post(c, post("a", 10)) is True
    assert db.upsert_post(c, post("a", 50)) is False
    assert c.execute("SELECT reactions FROM posts WHERE urn='a'").fetchone()[0] == 50
    assert db.upsert_job(c, job(1)) is True
    assert db.upsert_job(c, job(1)) is False


def test_hot_needs_history_and_multiplier():
    c = db.connect(":memory:")
    new = [post("new1", 100), post("new2", 15)]
    for p in new:
        db.upsert_post(c, p)
    # not enough history yet
    analyze.mark_hot(c, "Acme", new)
    assert not any(p["hot"] for p in new)

    for i in range(5):
        db.upsert_post(c, post(f"old{i}", 10))
    analyze.mark_hot(c, "Acme", new)
    assert new[0]["hot"] is True and new[0]["vs_avg"] == 10.0
    assert new[1]["hot"] is False and new[1]["vs_avg"] == 1.5


def test_follower_change_window():
    c = db.connect(":memory:")
    today = date(2026, 9, 25)
    assert db.follower_change(c, "Acme") is None
    db.save_followers(c, "Acme", 900, today - timedelta(days=30))  # outside window
    db.save_followers(c, "Acme", 1000, today - timedelta(days=7))
    db.save_followers(c, "Acme", 1100, today - timedelta(days=1))
    db.save_followers(c, "Acme", 1250, today)
    assert db.follower_change(c, "Acme") == 250


def test_open_jobs_counts_only_current_run():
    c = db.connect(":memory:")
    db.upsert_job(c, job(1))
    c.execute("UPDATE jobs SET last_seen='2020-01-01T00:00:00+00:00'")  # closed long ago
    run_started = db.now()
    db.upsert_job(c, job(2))
    assert db.open_job_count(c, "Acme", run_started) == 1


def test_digest_and_sheet_rows():
    c = db.connect(":memory:")
    run_started = db.now()
    p1, p2 = post("a", 5, text="small"), post("b", 50, text="=HYPERLINK(\"x\")")
    for p in (p1, p2):
        db.upsert_post(c, p)
    db.upsert_job(c, job(1))
    db.save_followers(c, "Acme", 1000)
    changes = {
        "Acme": {"new_posts": analyze.mark_hot(c, "Acme", [p1, p2]), "new_jobs": [job(1)],
                 "followers": 1000, "jobs_ok": True},
        "Globex": {"new_posts": [], "new_jobs": [], "followers": 0, "jobs_ok": False},
    }
    digest = analyze.digest_rows(c, changes, run_started, today=date(2026, 9, 25))
    acme, globex = digest
    assert acme["new_posts"] == 2 and acme["new_jobs"] == 1 and acme["open_jobs"] == 1
    assert acme["top_post_url"] == "u/b"          # highest engagement first
    assert globex["open_jobs"] == "" and globex["followers"] == ""

    rows = sheets.build_rows("2026-09-25", digest, [p1, p2], [job(1)],
                             {"Acme": 1000, "Globex": 0}, summary="")
    assert set(rows) == set(sheets.TABS)
    for tab, data in rows.items():
        assert all(len(r) == len(sheets.TABS[tab]) for r in data), tab
    assert rows["AI Summary"] == []
    assert rows["Followers"] == [["2026-09-25", "Acme", 1000]]
    assert "Acme" in analyze.raw_text(changes) and "no new activity" in analyze.raw_text(changes)


def test_ai_summary_skipped_without_key(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    assert analyze.ai_summary("anything") == ""

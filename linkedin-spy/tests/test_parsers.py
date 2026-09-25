from pathlib import Path

import pytest

from spy.parsers import parse_company_id, parse_followers, parse_jobs, parse_posts, to_int

FIX = Path(__file__).parent / "fixtures"


@pytest.mark.parametrize("raw,expected", [
    ("1,204", 1204), ("2.3K", 2300), ("12k", 12000), ("1.5M", 1500000),
    ("87 comments", 87), ("  5 ", 5), ("", 0), (None, 0), ("no numbers", 0),
    ("2 months ago", 2),
])
def test_to_int(raw, expected):
    assert to_int(raw) == expected


def test_parse_followers():
    assert parse_followers("Software · Berlin · 48,512 followers · 201-500 employees") == 48512
    assert parse_followers("Acme 12K followers") == 12000
    assert parse_followers("nothing here") == 0


def test_parse_posts():
    posts = parse_posts((FIX / "company_posts.html").read_text(), "Acme")
    assert [p["urn"][-1] for p in posts] == ["1", "2", "3"]
    first, second, third = posts
    assert first["text"] == "We just launched AI Copilot for finance teams!"
    assert (first["reactions"], first["comments"], first["reposts"]) == (1204, 87, 12)
    assert first["url"] == "https://www.linkedin.com/feed/update/urn:li:activity:7100000000000000001/"
    assert second["text"].startswith("Hiring in Berlin")
    assert (second["reactions"], second["comments"]) == (2300, 1)
    assert (third["reactions"], third["comments"], third["reposts"]) == (0, 0, 0)
    assert all(p["company"] == "Acme" for p in posts)


def test_parse_jobs():
    jobs = parse_jobs((FIX / "jobs_guest.html").read_text(), "Acme")
    assert [j["job_id"] for j in jobs] == ["3900000001", "3900000002", "3900000003"]
    assert jobs[0]["title"] == "Account Executive, DACH"
    assert jobs[0]["location"] == "Berlin, Germany"
    assert jobs[0]["posted"] == "2026-09-20"
    assert jobs[0]["url"] == "https://www.linkedin.com/jobs/view/account-executive-dach-at-acme-3900000001"
    assert jobs[2]["location"] == ""


def test_parse_company_id():
    assert parse_company_id('..."entityUrn":"urn:li:fsd_company:1441"...') == "1441"
    assert parse_company_id('<a href="/jobs/search?f_C=98765&x=1">') == "98765"
    assert parse_company_id("nothing") == ""

"""Pure HTML -> data parsing. No network here, so everything is unit-testable.

LinkedIn changes its markup often. If a collector starts returning nothing,
the selectors in this file are almost always what needs updating.
"""
import re

from bs4 import BeautifulSoup

# Company posts page (logged in). Several fallbacks per field because
# LinkedIn rotates class names between UI versions.
POST_CONTAINER = 'div[data-urn^="urn:li:activity"]'
POST_TEXT = [
    ".update-components-text",
    ".feed-shared-update-v2__description",
    ".feed-shared-text",
]
POST_REACTIONS = [
    ".social-details-social-counts__reactions-count",
    "[data-test-id='social-actions__reaction-count']",
]

# Public jobs guest endpoint
JOB_CARD = "div.base-card, li div.base-search-card"
JOB_TITLE = ".base-search-card__title"
JOB_LOCATION = ".job-search-card__location"
JOB_LINK = "a.base-card__full-link"
JOB_DATE = "time"

_NUM = re.compile(r"([\d][\d,.]*)\s*([km])?\b", re.I)


def to_int(s):
    """'1,234' -> 1234, '12K' -> 12000, '1.5M' -> 1500000, junk -> 0."""
    if not s:
        return 0
    m = _NUM.search(str(s).strip())
    if not m:
        return 0
    raw, suffix = m.group(1), (m.group(2) or "").lower()
    if suffix:
        n = float(raw.replace(",", ""))
        return int(round(n * {"k": 1_000, "m": 1_000_000}[suffix]))
    return int(float(raw.replace(",", "")))


def _first(el, selectors):
    for sel in selectors:
        found = el.select_one(sel)
        if found:
            return found
    return None


def parse_followers(page_text):
    """Find '12,345 followers' in the visible text of a company page."""
    m = re.search(r"([\d][\d,.]*\s*[KkMm]?)\s+followers", page_text or "")
    return to_int(m.group(1)) if m else 0


def parse_posts(html, company):
    soup = BeautifulSoup(html, "html.parser")
    posts, seen = [], set()
    for el in soup.select(POST_CONTAINER):
        urn = el.get("data-urn", "")
        if not urn or urn in seen:
            continue
        seen.add(urn)
        text_el = _first(el, POST_TEXT)
        react_el = _first(el, POST_REACTIONS)
        comments_txt = el.find(string=re.compile(r"\d[\d,.]*\s*[KkMm]?\s+comments?", re.I))
        reposts_txt = el.find(string=re.compile(r"\d[\d,.]*\s*[KkMm]?\s+reposts?", re.I))
        activity_id = urn.rsplit(":", 1)[-1]
        posts.append({
            "urn": urn,
            "company": company,
            "text": text_el.get_text(" ", strip=True)[:3000] if text_el else "",
            "reactions": to_int(react_el.get_text() if react_el else ""),
            "comments": to_int(comments_txt),
            "reposts": to_int(reposts_txt),
            "url": f"https://www.linkedin.com/feed/update/urn:li:activity:{activity_id}/",
        })
    return posts


def parse_jobs(html, company):
    soup = BeautifulSoup(html, "html.parser")
    jobs, seen = [], set()
    for card in soup.select(JOB_CARD):
        urn = card.get("data-entity-urn", "")
        job_id = urn.rsplit(":", 1)[-1] if urn else ""
        link = card.select_one(JOB_LINK)
        url = link["href"].split("?")[0] if link and link.get("href") else ""
        if not job_id and url:
            m = re.search(r"-(\d+)/?$", url)
            job_id = m.group(1) if m else ""
        if not job_id or job_id in seen:
            continue
        seen.add(job_id)
        title = card.select_one(JOB_TITLE)
        loc = card.select_one(JOB_LOCATION)
        date = card.select_one(JOB_DATE)
        jobs.append({
            "job_id": job_id,
            "company": company,
            "title": title.get_text(" ", strip=True) if title else "",
            "location": loc.get_text(" ", strip=True) if loc else "",
            "posted": date.get("datetime", "") if date else "",
            "url": url,
        })
    return jobs


def parse_company_id(html):
    """Numeric company ID from a logged-in company page's embedded data."""
    for pat in (r"urn:li:fsd_company:(\d+)", r"urn:li:company:(\d+)",
                r"f_C=(\d+)", r"currentCompany=%5B%22(\d+)"):
        m = re.search(pat, html or "")
        if m:
            return m.group(1)
    return ""

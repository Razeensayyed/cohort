"""Find competitors for a niche, check them on LinkedIn, and add the chosen ones to
competitors.yaml.

Candidates come from Claude + web search when ANTHROPIC_API_KEY is set (companies and a
few public-facing people), otherwise from LinkedIn's own company search. Every candidate
is then opened in your logged-in browser, so made-up or dead links are dropped before
you see the list.
"""
import os
import random
import re
import time
from urllib.parse import quote_plus

import yaml
from bs4 import BeautifulSoup

from spy.config import MAX_PEOPLE, _slug
from spy.parsers import parse_company_id, parse_followers, parse_posts

UNAVAILABLE_MARKERS = ("/unavailable", "/404", "/company/setup", "/authwall", "/checkpoint")
NOT_COMPANY_SLUGS = {"unavailable", "setup", "admin", "home"}

# ---------------------------------------------------------------- candidates: Claude

_SUBMIT_TOOL = {
    "name": "submit_candidates",
    "description": "Submit the final list of competitor companies and people with their LinkedIn URLs.",
    "strict": True,
    "input_schema": {
        "type": "object",
        "properties": {
            "companies": {"type": "array", "items": {
                "type": "object",
                "properties": {"name": {"type": "string"},
                               "linkedin_url": {"type": "string"},
                               "why": {"type": "string"}},
                "required": ["name", "linkedin_url", "why"],
                "additionalProperties": False}},
            "people": {"type": "array", "items": {
                "type": "object",
                "properties": {"name": {"type": "string"},
                               "company": {"type": "string"},
                               "linkedin_url": {"type": "string"},
                               "why": {"type": "string"}},
                "required": ["name", "company", "linkedin_url", "why"],
                "additionalProperties": False}},
        },
        "required": ["companies", "people"],
        "additionalProperties": False,
    },
}


def candidates_with_ai(niche, exclude="", max_companies=12, max_people=5, client=None):
    """Returns {'companies': [...], 'people': [...]} or None when unavailable/failed."""
    if not os.getenv("ANTHROPIC_API_KEY") and client is None:
        return None
    import anthropic
    client = client or anthropic.Anthropic()

    prompt = (
        f"My niche: {niche}\n"
        + (f"Exclude (that's me / my own company): {exclude}\n" if exclude else "")
        + f"\nFind up to {max_companies} companies that compete in this niche and are active "
        f"on LinkedIn, and up to {max_people} public-facing people (founders, leaders or "
        "creators) who regularly post publicly on LinkedIn about this niche as the voice of "
        "their business.\n"
        "Use web search to find each one's real LinkedIn URL: linkedin.com/company/<slug>/ "
        "for companies, linkedin.com/in/<slug>/ for people. Only include URLs you actually "
        "saw in search results; skip anyone whose URL you can't find. Prefer direct "
        "competitors over large generic brands. For each, give one short 'why' line.\n"
        "When you're done, call submit_candidates exactly once with the list.")
    messages = [{"role": "user", "content": prompt}]
    tools = [{"type": "web_search_20260209", "name": "web_search", "max_uses": 10},
             _SUBMIT_TOOL]
    try:
        for _ in range(6):  # a few pause_turn continuations at most
            response = client.beta.messages.create(
                model=os.getenv("ANTHROPIC_MODEL") or "claude-opus-5",
                max_tokens=16000,
                betas=["server-side-fallback-2026-07-01"],
                fallbacks="default",
                tools=tools,
                messages=messages,
            )
            if response.stop_reason == "refusal":
                print("[discover] the model declined this search")
                return None
            for block in response.content:
                if block.type == "tool_use" and block.name == "submit_candidates":
                    return {"companies": list(block.input.get("companies", [])),
                            "people": list(block.input.get("people", []))}
            if response.stop_reason != "pause_turn":
                break
            # Server-side search paused: send the turn back as-is and it resumes.
            messages.append({"role": "assistant", "content": response.content})
    except Exception as e:
        print(f"[discover] AI search failed ({e})")
        return None
    print("[discover] AI search finished without a list")
    return None


# ------------------------------------------------------ candidates: LinkedIn search

def parse_company_search(html):
    """Company results from linkedin.com/search/results/companies/ -> [{name, slug}]."""
    soup = BeautifulSoup(html, "html.parser")
    found, seen = [], set()
    for a in soup.select('a[href*="/company/"]'):
        m = re.search(r"/company/([^/?#]+)", a.get("href", ""))
        if not m:
            continue
        slug = m.group(1)
        name = a.get_text(" ", strip=True)
        if slug in NOT_COMPANY_SLUGS or not name:
            continue
        if slug in seen:
            continue
        seen.add(slug)
        found.append({"name": name, "slug": slug})
    return found


def candidates_from_linkedin(page, niche, pages=2):
    companies = []
    for n in range(1, pages + 1):
        page.goto("https://www.linkedin.com/search/results/companies/"
                  f"?keywords={quote_plus(niche)}&page={n}", wait_until="domcontentloaded")
        time.sleep(random.uniform(4, 7))
        for _ in range(2):
            page.mouse.wheel(0, 1800)
            time.sleep(random.uniform(1.5, 3))
        companies += [c for c in parse_company_search(page.content())
                      if c["slug"] not in {x["slug"] for x in companies}]
    return [{"name": c["name"], "linkedin_url": f"https://www.linkedin.com/company/{c['slug']}/",
             "why": "LinkedIn company search"} for c in companies]


# ------------------------------------------------------------------- verification

def slug_or_none(url, kind):
    try:
        slug = _slug(url, kind)
    except SystemExit:
        return None
    if not slug or "linkedin.com" in slug or "/" in slug:
        return None
    return slug


def verify(page, companies, people):
    """Open each candidate; keep the ones that exist. Adds slug/followers/company_id."""
    ok_companies, ok_people = [], []
    for c in companies:
        slug = slug_or_none(c["linkedin_url"], "company")
        if not slug or slug in {x["slug"] for x in ok_companies}:
            continue
        page.goto(f"https://www.linkedin.com/company/{slug}/", wait_until="domcontentloaded")
        time.sleep(random.uniform(3, 6))
        if any(m in page.url for m in UNAVAILABLE_MARKERS):
            print(f"  ✗ {c['name']}: page not found, skipped")
            continue
        html = page.content()
        c = {**c, "slug": slug, "followers": parse_followers(page.inner_text("body")),
             "company_id": parse_company_id(html)}
        ok_companies.append(c)
        print(f"  ✓ {c['name']} ({c['followers']:,} followers)")
    for p in people:
        slug = slug_or_none(p["linkedin_url"], "in")
        if not slug or slug in {x["slug"] for x in ok_people}:
            continue
        # Only the public activity page, the same page the tracker reads later.
        page.goto(f"https://www.linkedin.com/in/{slug}/recent-activity/all/",
                  wait_until="domcontentloaded")
        time.sleep(random.uniform(3, 6))
        if any(m in page.url for m in UNAVAILABLE_MARKERS):
            print(f"  ✗ {p['name']}: profile not found, skipped")
            continue
        recent = len(parse_posts(page.content(), p["name"], author_slug=slug, source="person"))
        ok_people.append({**p, "slug": slug, "recent_posts": recent})
        print(f"  ✓ {p['name']} ({recent} recent own posts)")
    return ok_companies, ok_people


# ---------------------------------------------------------------- choose and save

def parse_selection(text, n):
    """'1,3,5-7' / 'all' / '' -> sorted 0-based indexes within range."""
    text = (text or "").strip().lower()
    if text in ("", "none", "0"):
        return []
    if text == "all":
        return list(range(n))
    picked = set()
    for part in re.split(r"[,\s]+", text):
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            if a.isdigit() and b.isdigit():
                picked.update(range(int(a), int(b) + 1))
        elif part.isdigit():
            picked.add(int(part))
    return sorted(i - 1 for i in picked if 1 <= i <= n)


def merge_into_config(path, niche, companies, people):
    """Add chosen entries to competitors.yaml without duplicating existing ones.
    Returns (added_companies, added_people, skipped_people_over_limit)."""
    try:
        with open(path) as f:
            data = yaml.safe_load(f) or {}
    except FileNotFoundError:
        data = {}
    data["niche"] = niche
    existing_c = data.get("competitors") or []
    existing_p = data.get("people") or []
    have_c = {slug_or_none(x.get("slug"), "company") for x in existing_c}
    have_p = {slug_or_none(x.get("slug"), "in") for x in existing_p}

    added_c = [c for c in companies if c["slug"] not in have_c]
    existing_c += [{"name": c["name"], "slug": c["slug"], "company_id": c.get("company_id", "")}
                   for c in added_c]

    new_p = [p for p in people if p["slug"] not in have_p]
    room = max(0, MAX_PEOPLE - len(existing_p))
    added_p, over = new_p[:room], new_p[room:]
    existing_p += [{"name": p["name"], "company": p.get("company", ""), "slug": p["slug"]}
                   for p in added_p]

    data["competitors"] = existing_c
    if existing_p:
        data["people"] = existing_p
        data.setdefault("people_retention_days", 90)
    ordered = {k: data[k] for k in ("niche", "competitors", "people", "people_retention_days")
               if k in data}
    ordered.update({k: v for k, v in data.items() if k not in ordered})
    with open(path, "w") as f:
        yaml.safe_dump(ordered, f, sort_keys=False, allow_unicode=True)
    return added_c, added_p, over

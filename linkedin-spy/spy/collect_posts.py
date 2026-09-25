"""Company posts + follower count, and the own posts of a few listed people,
using your saved logged-in browser profile.

Runs slowly on purpose: random pauses, a few scrolls, one page at a time.
"""
import random
import time

from spy.parsers import parse_followers, parse_posts

PROFILE_DIR = "data/browser_profile"
BLOCKED_MARKERS = ("/checkpoint", "/authwall", "/login", "/uas/login")


class SessionExpired(Exception):
    pass


def _pause(a=2.0, b=5.0):
    time.sleep(random.uniform(a, b))


def _check_session(page):
    if any(m in page.url for m in BLOCKED_MARKERS):
        raise SessionExpired(
            f"LinkedIn redirected to {page.url}. Run `python login.py` again. "
            "Don't retry in a loop, that makes it worse.")


def scrape_company(page, comp, scrolls=4, debug_dir=None):
    page.goto(f"https://www.linkedin.com/company/{comp['slug']}/", wait_until="domcontentloaded")
    _pause(3, 6)
    _check_session(page)
    followers = parse_followers(page.inner_text("body"))

    page.goto(f"https://www.linkedin.com/company/{comp['slug']}/posts/?feedView=all",
              wait_until="domcontentloaded")
    _pause(3, 6)
    _check_session(page)
    for _ in range(scrolls):
        page.mouse.wheel(0, random.randint(1500, 2500))
        _pause()

    html = page.content()
    if debug_dir:
        with open(f"{debug_dir}/{comp['slug']}_posts.html", "w", encoding="utf-8") as f:
            f.write(html)
    return followers, parse_posts(html, comp["name"])


def scrape_person(page, person, scrolls=3, debug_dir=None):
    """A person's own recent public posts. Only the activity page is opened;
    no profile details are read."""
    page.goto(f"https://www.linkedin.com/in/{person['slug']}/recent-activity/all/",
              wait_until="domcontentloaded")
    _pause(3, 6)
    _check_session(page)
    for _ in range(scrolls):
        page.mouse.wheel(0, random.randint(1500, 2500))
        _pause()

    html = page.content()
    if debug_dir:
        with open(f"{debug_dir}/person_{person['slug']}.html", "w", encoding="utf-8") as f:
            f.write(html)
    return 0, parse_posts(html, person["name"], author_slug=person["slug"], source="person")


def collect_posts(competitors, headless=True, scrolls=4, debug_dir=None):
    """Returns {name: (followers, [posts])} for companies and people (followers is
    always 0 for people). Failed targets are skipped."""
    from playwright.sync_api import sync_playwright  # imported here so tests don't need it

    out = {}
    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(PROFILE_DIR, headless=headless)
        page = ctx.pages[0] if ctx.pages else ctx.new_page()
        try:
            for i, comp in enumerate(competitors):
                if i:
                    _pause(8, 20)
                try:
                    if comp.get("kind") == "person":
                        out[comp["name"]] = scrape_person(page, comp, debug_dir=debug_dir)
                        print(f"[posts] {comp['name']}: {len(out[comp['name']][1])} own posts")
                        continue
                    out[comp["name"]] = scrape_company(page, comp, scrolls, debug_dir)
                    print(f"[posts] {comp['name']}: {len(out[comp['name']][1])} posts, "
                          f"{out[comp['name']][0]:,} followers")
                except SessionExpired:
                    raise
                except Exception as e:
                    print(f"[posts] {comp['name']} failed: {e}")
        finally:
            ctx.close()
    return out

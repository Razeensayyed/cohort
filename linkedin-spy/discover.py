"""Find competitors for your niche and add the ones you pick to competitors.yaml.

    python discover.py                       asks for your niche
    python discover.py --niche "AI tools for recruiters"
    python discover.py --show                watch the browser while it checks candidates

Needs the LinkedIn login from `python login.py`. With ANTHROPIC_API_KEY in .env it also
suggests public-facing people; without it, it uses LinkedIn's company search only.
"""
import argparse
import os
import re

import yaml
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright

from spy.collect_posts import PROFILE_DIR, SessionExpired, _check_session
from spy.config import MAX_PEOPLE
from spy.discover import (candidates_from_linkedin, candidates_with_ai, merge_into_config,
                          parse_selection, verify)

PATH = "competitors.yaml"


def looks_like_command(text):
    t = text.strip().lower()
    return bool(re.match(r"python3?\s+\S+\.py\b", t)
                or re.match(r"(cd|git|source|ls|open|pip)(\s|$)", t)
                or " --" in t)


def ask(question, default=""):
    while True:
        answer = input(f"{question}{f' [{default}]' if default else ''}: ").strip()
        if not looks_like_command(answer):
            return answer or default
        print("  That looks like a Terminal command, not an answer. Type your answer "
              "(run commands one at a time, after this one finishes).")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--niche")
    ap.add_argument("--exclude", help="your own company/name, so it isn't suggested")
    ap.add_argument("--show", action="store_true")
    args = ap.parse_args()
    load_dotenv(".env")

    try:
        with open(PATH) as f:
            saved_niche = (yaml.safe_load(f) or {}).get("niche", "")
    except FileNotFoundError:
        saved_niche = ""
    print("Describe your niche the way a customer would search for it, e.g.")
    print('  "AI automation agency for real-estate brokers in India"')
    niche = args.niche or ask("Your niche", saved_niche)
    if not niche:
        raise SystemExit("A niche is needed.")
    exclude = args.exclude if args.exclude is not None else ask(
        "Your own company or name, to leave out (optional)")

    print("\nSearching for competitors...")
    found = candidates_with_ai(niche, exclude)
    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(PROFILE_DIR, headless=not args.show)
        page = ctx.pages[0] if ctx.pages else ctx.new_page()
        try:
            page.goto("https://www.linkedin.com/feed/", wait_until="domcontentloaded")
            _check_session(page)
            if found is None:
                print("(No Anthropic API key or the AI search failed: using LinkedIn company "
                      "search. Add ANTHROPIC_API_KEY to .env for better matches and people.)")
                found = {"companies": candidates_from_linkedin(page, niche), "people": []}
                if not found["companies"]:
                    os.makedirs("data/debug", exist_ok=True)
                    with open("data/debug/company_search.html", "w", encoding="utf-8") as f:
                        f.write(page.content())
                    print("LinkedIn's company search returned nothing readable; the page was "
                          "saved to data/debug/company_search.html for troubleshooting.")
            print(f"\nChecking {len(found['companies'])} companies and "
                  f"{len(found['people'])} people on LinkedIn...")
            companies, people = verify(page, found["companies"], found["people"])
        except SessionExpired as e:
            raise SystemExit(str(e))
        finally:
            ctx.close()

    exclude_l = exclude.lower()
    if exclude_l:
        companies = [c for c in companies if exclude_l not in c["name"].lower()]
        people = [x for x in people if exclude_l not in x["name"].lower()]
    if not companies and not people:
        raise SystemExit("Nothing found. Try describing the niche differently.")

    chosen_c, chosen_p = [], []
    if companies:
        print("\nCOMPANIES")
        for i, c in enumerate(companies, 1):
            print(f"  {i:>2}. {c['name']}  ({c['followers']:,} followers)  - {c['why']}")
        chosen_c = [companies[i] for i in parse_selection(
            ask("Which companies to track? (e.g. 1,3,5-7 / all / none)", "all"), len(companies))]
    if people:
        print(f"\nPEOPLE (their own public posts only; max {MAX_PEOPLE} tracked in total)")
        for i, x in enumerate(people, 1):
            print(f"  {i:>2}. {x['name']} ({x['company']})  - {x['recent_posts']} recent posts"
                  f"  - {x['why']}")
        chosen_p = [people[i] for i in parse_selection(
            ask("Which people to track? (e.g. 1,2 / all / none)", "none"), len(people))]

    added_c, added_p, over = merge_into_config(PATH, niche, chosen_c, chosen_p)
    print(f"\nAdded {len(added_c)} companies and {len(added_p)} people to {PATH}.")
    if over:
        print(f"Not added (people limit of {MAX_PEOPLE} reached): "
              + ", ".join(x["name"] for x in over))
    print("Next: python main.py --dry-run --show   (then python main.py --seed)")


if __name__ == "__main__":
    main()

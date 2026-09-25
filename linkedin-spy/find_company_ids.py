"""Fill in missing company_id values in competitors.yaml (uses your logged-in session)."""
import random
import time

import yaml
from playwright.sync_api import sync_playwright

from spy.collect_posts import PROFILE_DIR
from spy.config import _slug
from spy.parsers import parse_company_id

PATH = "competitors.yaml"

with open(PATH) as f:
    data = yaml.safe_load(f)

missing = [c for c in data["competitors"] if not c.get("company_id")]
if not missing:
    print("All competitors already have a company_id.")
    raise SystemExit

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(PROFILE_DIR, headless=True)
    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    for comp in missing:
        slug = _slug(comp["slug"], "company")
        page.goto(f"https://www.linkedin.com/company/{slug}/", wait_until="domcontentloaded")
        time.sleep(random.uniform(3, 6))
        comp["company_id"] = parse_company_id(page.content())
        print(f"{comp['name']}: {comp['company_id'] or 'NOT FOUND (check the slug)'}")
    ctx.close()

with open(PATH, "w") as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)
print(f"Updated {PATH}")

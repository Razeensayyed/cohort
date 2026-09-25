"""Open jobs via LinkedIn's public guest endpoint. No login needed."""
import random
import time

import requests

from spy.parsers import parse_jobs

URL = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"
HEADERS = {
    "User-Agent": ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                   "(KHTML, like Gecko) Chrome/128.0 Safari/537.36"),
    "Accept-Language": "en-US,en;q=0.9",
}
PAGE_SIZE = 25


def collect_jobs(comp, max_pages=8, session=None):
    if not comp.get("company_id"):
        print(f"[jobs] {comp['name']}: no company_id, skipping "
              "(run `python find_company_ids.py`)")
        return []
    s = session or requests.Session()
    jobs, seen = [], set()
    for page in range(max_pages):
        r = s.get(URL, headers=HEADERS, timeout=20,
                  params={"f_C": comp["company_id"], "start": page * PAGE_SIZE})
        if r.status_code == 429:
            print(f"[jobs] {comp['name']}: rate limited (429), stopping early")
            break
        if r.status_code != 200 or not r.text.strip():
            break
        batch = [j for j in parse_jobs(r.text, comp["name"]) if j["job_id"] not in seen]
        if not batch:
            break
        seen.update(j["job_id"] for j in batch)
        jobs += batch
        time.sleep(random.uniform(2, 4))
    print(f"[jobs] {comp['name']}: {len(jobs)} open jobs")
    return jobs

"""Daily run: collect -> compare with history -> append to Google Sheets.

    python main.py              normal daily run
    python main.py --dry-run    print what would be written; saves nothing
    python main.py --seed       first run: fill history, write nothing to Sheets
    python main.py --show       show the browser window (good for debugging)
    python main.py --debug      also save each posts page's HTML to data/debug/
"""
import argparse
import os
import sys
from datetime import date

import yaml
from dotenv import load_dotenv

from spy import analyze, db, sheets
from spy.collect_jobs import collect_jobs
from spy.collect_posts import SessionExpired, collect_posts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--seed", action="store_true")
    ap.add_argument("--show", action="store_true")
    ap.add_argument("--debug", action="store_true")
    ap.add_argument("--no-posts", action="store_true", help="skip the logged-in part")
    ap.add_argument("--no-jobs", action="store_true")
    args = ap.parse_args()

    load_dotenv()
    with open("competitors.yaml") as f:
        comps = yaml.safe_load(f)["competitors"]
    c = db.connect()
    run_started = db.now()
    today = date.today().isoformat()
    changes = {x["name"]: {"new_posts": [], "new_jobs": [], "followers": 0, "jobs_ok": False}
               for x in comps}
    all_posts, all_jobs = [], []

    if not args.no_posts:
        debug_dir = None
        if args.debug:
            debug_dir = "data/debug"
            os.makedirs(debug_dir, exist_ok=True)
        try:
            results = collect_posts(comps, headless=not args.show, debug_dir=debug_dir)
        except SessionExpired as e:
            print(f"[posts] STOPPED: {e}")
            results = {}
        for name, (followers, posts) in results.items():
            changes[name]["followers"] = followers
            if followers:
                db.save_followers(c, name, followers)
            new = [p for p in posts if db.upsert_post(c, p)]
            changes[name]["new_posts"] = analyze.mark_hot(c, name, new)
            all_posts += changes[name]["new_posts"]

    if not args.no_jobs:
        for comp in comps:
            try:
                jobs = collect_jobs(comp)
            except Exception as e:
                print(f"[jobs] {comp['name']} failed: {e}")
                continue
            changes[comp["name"]]["jobs_ok"] = bool(comp.get("company_id"))
            new = [j for j in jobs if db.upsert_job(c, j)]
            changes[comp["name"]]["new_jobs"] = new
            all_jobs += new

    if args.seed:
        c.commit()
        print(f"Seeded history: {len(all_posts)} posts, {len(all_jobs)} jobs. "
              "Nothing written to Sheets. From now on run without --seed.")
        return

    digest = analyze.digest_rows(c, changes, run_started)
    has_news = bool(all_posts or all_jobs)
    summary = analyze.ai_summary(analyze.raw_text(changes)) if has_news else ""
    followers = {name: ch["followers"] for name, ch in changes.items()}
    rows = sheets.build_rows(today, digest, all_posts, all_jobs, followers, summary)

    if args.dry_run:
        sheets.preview(rows)
        c.rollback()
        print("\n(dry run: nothing saved)")
        return

    sheets.write(rows)
    c.commit()  # only after Sheets succeeded, so a failed write is retried next run
    print(f"Done: {len(all_posts)} new posts, {len(all_jobs)} new jobs.")


if __name__ == "__main__":
    sys.exit(main())

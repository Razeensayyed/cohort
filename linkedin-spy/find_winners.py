"""Show the posts that beat their account's usual engagement, and the topics behind them.

Uses the history already collected by main.py; it doesn't visit LinkedIn.

    python find_winners.py              analyze and write the Winners / Winning Topics tabs
    python find_winners.py --dry-run    print instead of writing to the Sheet
    python find_winners.py --x 3        stricter: 3x the usual engagement instead of 2x
    python find_winners.py --no-ai      keyword topics even if an Anthropic key is set
"""
import argparse

from dotenv import load_dotenv

from spy import db, sheets, winners

ap = argparse.ArgumentParser()
ap.add_argument("--dry-run", action="store_true")
ap.add_argument("--x", type=float, default=winners.WIN_MULTIPLIER, help="winning multiplier")
ap.add_argument("--no-ai", action="store_true")
args = ap.parse_args()

load_dotenv(".env")
result = winners.analyze(db.connect(), multiplier=args.x, use_ai=not args.no_ai)
if args.dry_run:
    sheets.preview_winners(*result)
else:
    sheets.write_winners(*result)

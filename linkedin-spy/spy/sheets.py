"""Append each run's results to a Google Sheet. Tabs are created on first use."""
import os
import re

TABS = {
    "Digest": ["Date", "Company", "New posts", "Hot posts", "New jobs", "Open jobs",
               "Followers", "Follower change (7d)", "Top new post", "Top post URL"],
    "AI Summary": ["Date", "Summary"],
    "Posts": ["First seen", "Company", "Engagement", "Reactions", "Comments", "Reposts",
              "x usual", "Hot", "Text", "URL"],
    "Jobs": ["First seen", "Company", "Title", "Location", "Posted", "URL"],
    "Followers": ["Date", "Company", "Followers"],
}


def build_rows(today, digest, posts, jobs, followers, summary):
    """Everything to append, as {tab: [row, ...]}. Kept separate so it can be tested."""
    from spy.analyze import engagement
    return {
        "Digest": [[d["date"], d["company"], d["new_posts"], d["hot_posts"], d["new_jobs"],
                    d["open_jobs"], d["followers"], d["follower_change_7d"],
                    d["top_post"], d["top_post_url"]] for d in digest],
        "AI Summary": [[today, summary]] if summary else [],
        "Posts": [[today, p["company"], engagement(p), p["reactions"], p["comments"],
                   p["reposts"], p.get("vs_avg") or "", "YES" if p.get("hot") else "",
                   p["text"], p["url"]] for p in posts],
        "Jobs": [[today, j["company"], j["title"], j["location"], j["posted"], j["url"]]
                 for j in jobs],
        "Followers": [[today, name, n] for name, n in followers.items() if n],
    }


def sheet_id_from(value):
    """Accept a bare ID, an ID with '/edit...' stuck on, or the whole Sheet URL."""
    value = (value or "").strip().strip("'\"")
    m = re.search(r"/d/([A-Za-z0-9_-]+)", value)
    if m:
        return m.group(1)
    return value.split("/")[0].split("?")[0].split("#")[0]


def _worksheet(sh, title, header):
    import gspread
    try:
        ws = sh.worksheet(title)
    except gspread.WorksheetNotFound:
        ws = sh.add_worksheet(title=title, rows=1000, cols=len(header))
    if not ws.row_values(1):
        ws.append_row(header, value_input_option="RAW")
        ws.freeze(rows=1)
    return ws


def write(rows_by_tab):
    import gspread
    key_file = os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "service_account.json")
    sheet_id = sheet_id_from(os.getenv("GOOGLE_SHEET_ID"))
    if not sheet_id:
        raise SystemExit("GOOGLE_SHEET_ID is not set in .env")
    sh = gspread.service_account(filename=key_file).open_by_key(sheet_id)
    for tab, header in TABS.items():
        ws = _worksheet(sh, tab, header)
        if rows_by_tab.get(tab):
            # RAW so post text starting with "=" is never run as a formula
            ws.append_rows(rows_by_tab[tab], value_input_option="RAW")
    print(f"[sheets] written to https://docs.google.com/spreadsheets/d/{sheet_id}")


def preview(rows_by_tab):
    for tab, rows in rows_by_tab.items():
        print(f"\n=== {tab} ({len(rows)} new rows) ===")
        print(" | ".join(TABS[tab]))
        for r in rows[:10]:
            print(" | ".join(str(x)[:80].replace("\n", " ") for x in r))
        if len(rows) > 10:
            print(f"... and {len(rows) - 10} more")

"""One-time (and whenever the session expires): log in by hand, the profile is saved."""
from playwright.sync_api import sync_playwright

from spy.collect_posts import PROFILE_DIR

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(PROFILE_DIR, headless=False)
    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    page.goto("https://www.linkedin.com/login")
    input("Log in in the browser window (including 2FA). "
          "When you can see your feed, press Enter here...")
    ctx.close()
    print(f"Session saved to {PROFILE_DIR}/")

"""Load and validate competitors.yaml."""
import re

import yaml

MAX_PEOPLE = 5            # deliberately small: public-facing founders/leaders only
DEFAULT_RETENTION_DAYS = 90


def _slug(value, kind):
    """Accept a bare slug or a full LinkedIn URL ('/company/x/' or '/in/x/')."""
    value = str(value or "").strip()
    m = re.search(rf"linkedin\.com/{kind}/([^/?#]+)", value)
    if m:
        return m.group(1)
    if "linkedin.com/" in value:
        where = "under 'people:'" if kind == "company" else "under 'competitors:'"
        raise SystemExit(f"'{value}' is in the wrong section of competitors.yaml; move it {where}")
    return value.strip("/")


def load(path="competitors.yaml"):
    """Returns (companies, people, retention_days). Each entry has name, slug, kind."""
    with open(path) as f:
        data = yaml.safe_load(f) or {}

    companies = [{"name": c["name"], "slug": _slug(c["slug"], "company"),
                  "company_id": str(c.get("company_id") or ""), "kind": "company"}
                 for c in data.get("competitors") or []]

    people = []
    for p in data.get("people") or []:
        label = f"{p['name']} ({p['company']})" if p.get("company") else p["name"]
        people.append({"name": label, "slug": _slug(p["slug"], "in"), "kind": "person"})
    if len(people) > MAX_PEOPLE:
        raise SystemExit(f"competitors.yaml lists {len(people)} people; the limit is {MAX_PEOPLE}. "
                         "Keep it to public-facing founders/leaders.")

    names = [x["name"] for x in companies + people]
    dupes = sorted({n for n in names if names.count(n) > 1})
    if dupes:
        raise SystemExit(f"Duplicate names in competitors.yaml: {', '.join(dupes)}")

    retention = int(data.get("people_retention_days") or DEFAULT_RETENTION_DAYS)
    return companies, people, retention

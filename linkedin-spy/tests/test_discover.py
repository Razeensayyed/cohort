import types
from pathlib import Path

import yaml

from spy import config, discover

FIX = Path(__file__).parent / "fixtures"


def test_parse_selection():
    assert discover.parse_selection("1,3,5-7", 10) == [0, 2, 4, 5, 6]
    assert discover.parse_selection("all", 3) == [0, 1, 2]
    assert discover.parse_selection("", 3) == [] and discover.parse_selection("none", 3) == []
    assert discover.parse_selection("0, 2, 99, x", 3) == [1]


def test_parse_company_search():
    found = discover.parse_company_search((FIX / "company_search.html").read_text())
    assert found == [{"name": "Acme AI", "slug": "acme-ai"},
                     {"name": "Globex Labs", "slug": "globex-labs"}]


def test_merge_into_config_adds_without_duplicates_and_respects_people_limit(tmp_path):
    path = tmp_path / "competitors.yaml"
    path.write_text("competitors:\n  - name: Acme\n    slug: https://www.linkedin.com/company/acme-ai/\n"
                    "people:\n" + "".join(f"  - name: P{i}\n    slug: p{i}\n" for i in range(4)))
    companies = [{"name": "Acme AI", "slug": "acme-ai", "company_id": "1"},
                 {"name": "Globex", "slug": "globex", "company_id": "2"}]
    people = [{"name": "P0 again", "slug": "p0", "company": "X"},
              {"name": "New A", "slug": "new-a", "company": "Globex"},
              {"name": "New B", "slug": "new-b", "company": "Globex"}]
    added_c, added_p, over = discover.merge_into_config(str(path), "AI tools", companies, people)
    assert [c["slug"] for c in added_c] == ["globex"]
    assert [p["slug"] for p in added_p] == ["new-a"] and [p["slug"] for p in over] == ["new-b"]

    data = yaml.safe_load(path.read_text())
    assert list(data)[:2] == ["niche", "competitors"] and data["niche"] == "AI tools"
    comps, ppl, retention = config.load(str(path))      # still a valid config
    assert [c["slug"] for c in comps] == ["acme-ai", "globex"]
    assert len(ppl) == config.MAX_PEOPLE and ppl[-1]["name"] == "New A (Globex)"


def test_merge_into_empty_config(tmp_path):
    path = tmp_path / "competitors.yaml"
    discover.merge_into_config(str(path), "niche", [{"name": "A", "slug": "a"}], [])
    assert yaml.safe_load(path.read_text()) == {
        "niche": "niche", "competitors": [{"name": "A", "slug": "a", "company_id": ""}]}


def _block(**kw):
    return types.SimpleNamespace(**kw)


def test_candidates_with_ai_handles_pause_turn(monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test")
    calls = []
    paused = _block(stop_reason="pause_turn", content=[_block(type="server_tool_use", name="web_search")])
    done = _block(stop_reason="tool_use", content=[
        _block(type="text", text="Here you go"),
        _block(type="tool_use", name="submit_candidates", input={
            "companies": [{"name": "Acme", "linkedin_url": "https://www.linkedin.com/company/acme/", "why": "x"}],
            "people": []})])

    def create(**kw):
        calls.append(kw)
        return paused if len(calls) == 1 else done

    client = _block(beta=_block(messages=_block(create=create)))
    result = discover.candidates_with_ai("AI tools", "MyCo", client=client)
    assert result["companies"][0]["name"] == "Acme"
    assert calls[0]["model"] == "claude-opus-5" and calls[0]["fallbacks"] == "default"
    assert {t.get("type", t.get("name")) for t in calls[0]["tools"]} == {"web_search_20260209", "submit_candidates"}
    assert "MyCo" in calls[0]["messages"][0]["content"]
    # resumed by re-sending the paused assistant turn, no extra user message
    assert [m["role"] for m in calls[1]["messages"]] == ["user", "assistant"]


def test_candidates_with_ai_without_key(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    assert discover.candidates_with_ai("x") is None


class FakePage:
    def __init__(self, pages):
        self.pages, self.url, self._html = pages, "", ""

    def goto(self, url, wait_until=None):
        self.url, self._html = self.pages.get(url, ("https://www.linkedin.com/company/unavailable/", ""))

    def content(self):
        return self._html

    def inner_text(self, sel):
        return self._html


def test_verify_drops_missing_and_fills_details(monkeypatch):
    monkeypatch.setattr(discover.time, "sleep", lambda s: None)
    base = "https://www.linkedin.com"
    activity = (FIX / "person_activity.html").read_text()
    page = FakePage({
        f"{base}/company/acme/": (f"{base}/company/acme/", 'x "urn:li:fsd_company:4242" 12,300 followers'),
        f"{base}/in/jane-founder/recent-activity/all/": (f"{base}/in/jane-founder/recent-activity/all/", activity),
    })
    companies = [{"name": "Acme", "linkedin_url": f"{base}/company/acme/", "why": ""},
                 {"name": "Ghost", "linkedin_url": f"{base}/company/ghost/", "why": ""},
                 {"name": "Bad", "linkedin_url": "https://example.com/acme", "why": ""}]
    people = [{"name": "Jane", "company": "Acme", "linkedin_url": f"{base}/in/jane-founder/", "why": ""}]
    ok_c, ok_p = discover.verify(page, companies, people)
    assert [(c["slug"], c["company_id"], c["followers"]) for c in ok_c] == [("acme", "4242", 12300)]
    assert ok_p[0]["slug"] == "jane-founder" and ok_p[0]["recent_posts"] == 1

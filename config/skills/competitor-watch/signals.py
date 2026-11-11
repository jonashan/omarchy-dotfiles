#!/usr/bin/env python3
"""Deterministic competitor signals: new URLs in sitemaps/feeds + app store releases.

Usage: signals.py [data_dir]   (prints changes since last run, then updates state.json)
       signals.py --selftest
Reads <data_dir>/sources.json (who to watch — kept out of this repo), writes <data_dir>/state.json.
First run for a source only records a baseline.

sources.json:
  {"sources": {"<name>": {"urls": ["<sitemap or rss url>"], "match": "<regex a URL must match>"}},
   "apps":    {"<App Store track id>": "<label>"},          # country=dk
   "ours":    "<regex of our own brand/product names>"}     # new page matching it = they write about us
"""
import json, re, sys, urllib.request
from pathlib import Path

DEFAULT_DIR = Path.home() / "Documents/SecondBrain/96. AI/Competitor watch"


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "replace")


def urls_in(xml):
    return re.findall(r"<(?:loc|link)>\s*(?:<!\[CDATA\[)?\s*(https?://[^<\]\s]+)", xml)


def crawl(url, depth=0):
    xml = get(url)
    found = urls_in(xml)
    if "<sitemapindex" in xml and depth < 2:
        return [u for sub in found for u in crawl(sub, depth + 1)]
    return found


def new_since(seen, current):
    """seen=None means first run: baseline only, report nothing."""
    return [] if seen is None else sorted(set(current) - set(seen))


def mentions(url, ours):
    try:
        html = re.sub(r"<script.*?</script>", "", get(url), flags=re.S)
    except Exception:
        return []
    return sorted({m.group(0).lower() for m in ours.finditer(html)})


def main(data_dir):
    cfg = json.loads((data_dir / "sources.json").read_text())
    ours = re.compile(cfg["ours"], re.I)
    state_path = data_dir / "state.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {}
    pages, apps = state.setdefault("pages", {}), state.setdefault("apps", {})

    for name, src in cfg["sources"].items():
        try:
            current = [u for m in src["urls"] for u in crawl(m) if re.search(src["match"], u)]
        except Exception as e:  # one dead site must not kill the run
            print(f"## {name}: FETCH FAILED ({e})")
            continue
        fresh = new_since(pages.get(name), current)
        if name not in pages:
            print(f"## {name}: baseline recorded ({len(current)} URLs)")
        elif fresh:
            print(f"## {name}: {len(fresh)} new URL(s)")
            for u in fresh:
                hits = mentions(u, ours) if len(fresh) <= 50 else []  # ponytail: skip scan on site-wide URL reshuffles
                print(f"- {u}" + (f"  !! MENTIONS US: {', '.join(hits)}" if hits else ""))
        # union, so a URL that disappears and returns is not reported twice
        pages[name] = sorted(set(pages.get(name, [])) | set(current))

    try:
        ids = ",".join(cfg.get("apps", {}))
        results = json.loads(get(f"https://itunes.apple.com/lookup?id={ids}&country=dk"))["results"] if ids else []
    except Exception as e:
        results = []
        print(f"## App Store: FETCH FAILED ({e})")
    for r in results:
        id_, ver = str(r["trackId"]), r["version"]
        if id_ in apps and apps[id_] != ver:
            print(f"## App release: {r['trackName']} {apps[id_]} -> {ver} ({r['currentVersionReleaseDate'][:10]})")
            print(r.get("releaseNotes", "(no release notes)"))
        apps[id_] = ver

    state_path.write_text(json.dumps(state, indent=1, ensure_ascii=False))


def selftest():
    xml = "<urlset><url><loc>https://a.dk/x</loc></url><item><link><![CDATA[https://a.dk/y]]></link></item></urlset>"
    assert urls_in(xml) == ["https://a.dk/x", "https://a.dk/y"], urls_in(xml)
    assert new_since(None, ["a"]) == []
    assert new_since(["a"], ["a", "b"]) == ["b"]
    print("ok")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        main(Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DIR)

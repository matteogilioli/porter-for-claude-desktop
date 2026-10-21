#!/usr/bin/env python3
"""Builds the website into docs/: one page per language from site/template.html and site/i18n/<lang>.json.

    python3 site/build.py

English is the fallback for any string a language does not have yet.
"""
import hashlib
import html
import json
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = "https://matteogilioli.github.io/porter-for-claude-desktop/"
# Language code (hreflang) → folder under docs/ ("" is the root page).
LANGS = {"en": "", "it": "it", "es": "es", "fr": "fr", "de": "de", "pt-BR": "pt-br",
         "zh-Hans": "zh-hans", "ja": "ja", "ko": "ko", "ru": "ru"}
FILES = {"en": "en", "it": "it", "es": "es", "fr": "fr", "de": "de", "pt-BR": "pt-BR",
         "zh-Hans": "zh-Hans", "ja": "ja", "ko": "ko", "ru": "ru"}
# Values that are markup or URLs, not text to escape.
RAW = {"css_v", "js_v", "hreflang_links", "lang_menu", "window_points_li", "jsonld", "canonical", "site", "base", "home"}


def url(code):
    return SITE + (LANGS[code] + "/" if LANGS[code] else "")


def main():
    template = (ROOT / "site/template.html").read_text()
    english = json.loads((ROOT / "site/i18n/en.json").read_text())
    texts = {}
    for code, name in FILES.items():
        path = ROOT / f"site/i18n/{name}.json"
        texts[code] = {**english, **(json.loads(path.read_text()) if path.exists() else {})}

    docs = ROOT / "docs"
    # Cache busting: the files' own hash, so a change reaches visitors at once.
    version = {k: hashlib.sha1((docs / f"assets/site.{k[:-2]}").read_bytes()).hexdigest()[:8] for k in ("css_v", "js_v")}
    alternates = "\n".join(f'<link rel="alternate" hreflang="{c}" href="{url(c)}">' for c in LANGS)
    alternates += f'\n<link rel="alternate" hreflang="x-default" href="{url("en")}">'

    for code, folder in LANGS.items():
        t = texts[code]
        base = "../" if folder else ""
        menu = "".join(
            f'<li><a href="{base}{(LANGS[c] + "/") if LANGS[c] else ""}" hreflang="{c}" lang="{c}"'
            + (' aria-current="page"' if c == code else "") + f">{html.escape(texts[c]['lang_name'])}</a></li>"
            for c in LANGS)
        jsonld = json.dumps({
            "@context": "https://schema.org",
            "@type": "SoftwareApplication",
            "name": "Porter for Claude Desktop",
            "operatingSystem": "macOS 14 or later",
            "applicationCategory": "DeveloperApplication",
            "description": t["meta_description"],
            "url": url(code),
            "downloadUrl": "https://github.com/matteogilioli/porter-for-claude-desktop/releases/latest/download/Porter.dmg",
            "codeRepository": "https://github.com/matteogilioli/porter-for-claude-desktop",
            "license": "https://opensource.org/licenses/MIT",
            "inLanguage": code,
            "image": SITE + "assets/og.png",
            "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
            "author": {"@type": "Person", "name": "Matteo Gilioli", "url": "https://github.com/matteogilioli"},
        }, ensure_ascii=False).replace("</", "<\\/")
        values = {k: html.escape(v) for k, v in t.items()}
        values.update({
            **version, "canonical": url(code), "site": SITE, "base": base, "home": "./",
            "hreflang_links": alternates, "lang_menu": menu, "jsonld": jsonld,
            "window_points_li": "".join(f"<li>{html.escape(p)}</li>" for p in t["window_points"].split("|")),
        })
        page = template
        for key, value in values.items():
            page = page.replace("{{" + key + "}}", value)
        missing = [part.split("}}")[0] for part in page.split("{{")[1:]]
        if missing:
            raise SystemExit(f"{code}: no value for {missing}")
        out = docs / folder / "index.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page)

    links = "".join(f'<xhtml:link rel="alternate" hreflang="{c}" href="{url(c)}"/>' for c in LANGS)
    (docs / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
        + "".join(f"<url><loc>{url(c)}</loc>{links}</url>\n" for c in LANGS) + "</urlset>\n")
    (docs / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {SITE}sitemap.xml\n")
    (docs / ".nojekyll").write_text("")
    # Copied once: the site's copy carries its provenance note (see .impeccable), which a copy would drop.
    if not (docs / "assets/icon.png").exists():
        shutil.copy(ROOT / "assets/icon.png", docs / "assets/icon.png")
    shutil.copy(ROOT / "assets/readme/window.svg", docs / "assets/window.svg")
    print(f"Built {len(LANGS)} pages into docs/")


if __name__ == "__main__":
    main()

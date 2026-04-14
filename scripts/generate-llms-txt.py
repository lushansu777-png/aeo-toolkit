#!/usr/bin/env python3
"""
generate-llms-txt.py — Auto-generate llms.txt from a website's structure

Usage:
    python3 generate-llms-txt.py https://your-domain.com
    python3 generate-llms-txt.py https://your-domain.com --output llms.txt
    python3 generate-llms-txt.py https://your-domain.com --depth 2 --full

Options:
    --output PATH     Save to file instead of stdout (default: stdout)
    --depth INT       How many levels of pages to crawl (default: 1)
    --full            Generate llms-full.txt format with more detail
    --timeout INT     HTTP timeout in seconds (default: 10)

Requirements:
    pip install requests beautifulsoup4 lxml
"""

import argparse
import re
import sys
from datetime import datetime
from urllib.parse import urljoin, urlparse

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Missing dependencies. Install with:")
    print("  pip install requests beautifulsoup4 lxml")
    sys.exit(1)


def fetch(url: str, timeout: int = 10) -> BeautifulSoup | None:
    """Fetch a URL and return a BeautifulSoup object."""
    headers = {
        "User-Agent": "AEOToolkit/1.0 (llms.txt generator; +https://github.com/your-org/aeo-toolkit)"
    }
    try:
        r = requests.get(url, headers=headers, timeout=timeout)
        r.raise_for_status()
        return BeautifulSoup(r.text, "lxml")
    except Exception as e:
        print(f"Warning: Could not fetch {url}: {e}", file=sys.stderr)
        return None


def extract_meta(soup: BeautifulSoup) -> dict:
    """Extract key meta information from a page."""
    meta = {}

    # Title
    title_tag = soup.find("title")
    if title_tag:
        meta["title"] = title_tag.get_text().strip()

    # Meta description
    desc = soup.find("meta", attrs={"name": "description"})
    if desc:
        meta["description"] = desc.get("content", "").strip()

    # OG title / description (better than plain meta often)
    og_title = soup.find("meta", property="og:title")
    if og_title:
        meta["og_title"] = og_title.get("content", "").strip()

    og_desc = soup.find("meta", property="og:description")
    if og_desc:
        meta["og_description"] = og_desc.get("content", "").strip()

    # Schema.org Organization name
    for script in soup.find_all("script", type="application/ld+json"):
        try:
            import json
            data = json.loads(script.string or "{}")
            if isinstance(data, dict) and data.get("@type") == "Organization":
                meta["org_name"] = data.get("name", "")
                meta["org_description"] = data.get("description", "")
                meta["founded"] = data.get("foundingDate", "")
                meta["employees"] = data.get("numberOfEmployees", {})
                if isinstance(meta["employees"], dict):
                    meta["employees"] = meta["employees"].get("value", "")
        except Exception:
            pass

    return meta


def extract_nav_links(soup: BeautifulSoup, base_url: str) -> list[dict]:
    """Extract main navigation links from the page."""
    links = []
    seen_hrefs = set()
    domain = urlparse(base_url).netloc

    # Look in nav, header, footer
    for container in soup.find_all(["nav", "header", "footer"]):
        for a in container.find_all("a", href=True):
            href = urljoin(base_url, a["href"])
            parsed = urlparse(href)

            # Same domain only, skip anchors and query strings
            if parsed.netloc != domain:
                continue
            if "#" in href or "?" in href:
                continue

            clean_href = href.rstrip("/")
            if clean_href in seen_hrefs or clean_href == base_url.rstrip("/"):
                continue

            text = a.get_text().strip()
            if not text or len(text) > 60:
                continue

            seen_hrefs.add(clean_href)
            links.append({"text": text, "url": href})

    return links[:20]  # Cap at 20 links


def extract_page_description(soup: BeautifulSoup, url: str) -> str:
    """Extract a 1-line description of a page."""
    # Try OG description first
    og_desc = soup.find("meta", property="og:description")
    if og_desc and og_desc.get("content"):
        desc = og_desc["content"].strip()
        if len(desc) > 10:
            # Truncate at sentence boundary around 100 chars
            if len(desc) > 120:
                desc = desc[:120].rsplit(" ", 1)[0] + "..."
            return desc

    # Try meta description
    meta_desc = soup.find("meta", attrs={"name": "description"})
    if meta_desc and meta_desc.get("content"):
        desc = meta_desc["content"].strip()
        if len(desc) > 10:
            if len(desc) > 120:
                desc = desc[:120].rsplit(" ", 1)[0] + "..."
            return desc

    # Try first paragraph of main content
    for tag in ["main", "article", "section", "body"]:
        container = soup.find(tag)
        if container:
            p = container.find("p")
            if p:
                text = p.get_text().strip()
                if len(text) > 20:
                    return text[:120].rsplit(" ", 1)[0] + "..."

    return "No description available"


def generate_llms_txt(base_url: str, depth: int = 1, full: bool = False, timeout: int = 10) -> str:
    """Generate llms.txt content for a website."""
    print(f"Fetching {base_url}...", file=sys.stderr)
    homepage = fetch(base_url, timeout)
    if not homepage:
        print(f"Error: Could not fetch {base_url}", file=sys.stderr)
        sys.exit(1)

    meta = extract_meta(homepage)
    nav_links = extract_nav_links(homepage, base_url)
    domain = urlparse(base_url).netloc

    # Company name
    company_name = (
        meta.get("org_name")
        or meta.get("og_title", "").split("|")[0].split("—")[0].split("-")[0].strip()
        or meta.get("title", "").split("|")[0].split("—")[0].split("-")[0].strip()
        or domain
    )

    # Company description
    company_desc = (
        meta.get("org_description")
        or meta.get("og_description")
        or meta.get("description")
        or ""
    )
    if len(company_desc) > 80:
        company_desc = company_desc[:80].rsplit(" ", 1)[0] + "..."

    lines = []
    lines.append(f"# {company_name}")
    lines.append("")
    lines.append(f"> {company_desc or '[Add one-line company description here]'}")
    lines.append("")

    # Crawl linked pages if depth > 1
    product_links = []
    doc_links = []
    blog_links = []
    other_links = []

    for link in nav_links:
        url_lower = link["url"].lower()
        text_lower = link["text"].lower()
        if any(k in url_lower or k in text_lower for k in ["product", "feature", "pricing", "plan", "solution"]):
            product_links.append(link)
        elif any(k in url_lower or k in text_lower for k in ["doc", "guide", "api", "reference", "help"]):
            doc_links.append(link)
        elif any(k in url_lower or k in text_lower for k in ["blog", "post", "article", "news", "learn"]):
            blog_links.append(link)
        else:
            other_links.append(link)

    # Products section
    if product_links or other_links:
        lines.append("## Products")
        lines.append("")
        for link in (product_links or other_links)[:6]:
            if depth >= 2:
                page = fetch(link["url"], timeout)
                desc = extract_page_description(page, link["url"]) if page else "See page for details"
            else:
                desc = "See page for details"
            lines.append(f"- [{link['text']}]({link['url']}): {desc}")
        lines.append("")

    # Resources section
    if doc_links or blog_links:
        lines.append("## Resources")
        lines.append("")
        for link in (doc_links + blog_links)[:5]:
            lines.append(f"- [{link['text']}]({link['url']})")
        lines.append("")

    # Company info
    lines.append("## Company Info")
    lines.append("")
    if meta.get("founded"):
        lines.append(f"- Founded: {meta['founded']}")
    else:
        lines.append("- Founded: [YEAR]")
    if meta.get("employees"):
        lines.append(f"- Team size: {meta['employees']}")
    else:
        lines.append("- Team size: [NUMBER]")
    lines.append(f"- Website: {base_url}")
    lines.append("")

    # Contact
    lines.append("## Contact")
    lines.append("")
    lines.append(f"- Website: {base_url}")

    # Look for email in homepage
    emails = re.findall(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", homepage.get_text())
    if emails:
        email = emails[0]
        lines.append(f"- Email: {email}")
    else:
        lines.append(f"- Email: hi@{domain}")

    lines.append("")

    if full:
        lines.append("## Full Details")
        lines.append("")
        lines.append(f"Generated from {base_url} on {datetime.now().strftime('%Y-%m-%d')}")
        lines.append("Review and edit the sections above before deploying.")

    # Footer note
    lines.append("---")
    lines.append(f"Generated by AEO Toolkit on {datetime.now().strftime('%Y-%m-%d')}")
    lines.append("Review, edit, and deploy to your web root as /llms.txt")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate llms.txt from a website structure",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("url", help="Website URL to analyze")
    parser.add_argument("--output", "-o", help="Output file path (default: stdout)")
    parser.add_argument("--depth", "-d", type=int, default=1, help="Crawl depth (default: 1)")
    parser.add_argument("--full", "-f", action="store_true", help="Generate full format")
    parser.add_argument("--timeout", "-t", type=int, default=10, help="HTTP timeout seconds")

    args = parser.parse_args()

    # Normalize URL
    url = args.url
    if not url.startswith("http"):
        url = "https://" + url

    content = generate_llms_txt(url, depth=args.depth, full=args.full, timeout=args.timeout)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(content)


if __name__ == "__main__":
    main()

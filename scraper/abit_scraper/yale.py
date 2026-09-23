from __future__ import annotations

import re
import time
from pathlib import Path
from typing import Iterable

import httpx
from bs4 import BeautifulSoup
from rich.console import Console

from .models import Attribution, Catalog, CourseRecord, LectureOutline, LicenseInfo, utc_now

console = Console()

YALE_BASE = "https://oyc.yale.edu"
YALE_CATALOG = f"{YALE_BASE}/courses?order=title&sort=asc"
YALE_LICENSE = LicenseInfo(
    notes="Most OYC material is CC BY-NC-SA 3.0; third-party lecture inserts may be excluded.",
)

USER_AGENT = "aBitScraper/0.1 (+https://github.com/JParadela112109/aBit-; open-course catalog harvest)"


class YaleOYCClient:
    def __init__(self, delay_s: float = 0.6, timeout_s: float = 40.0) -> None:
        self.delay_s = delay_s
        self.client = httpx.Client(
            headers={"User-Agent": USER_AGENT, "Accept": "text/html"},
            timeout=timeout_s,
            follow_redirects=True,
        )

    def close(self) -> None:
        self.client.close()

    def __enter__(self) -> "YaleOYCClient":
        return self

    def __exit__(self, *args: object) -> None:
        self.close()

    def _get(self, url: str) -> str:
        time.sleep(self.delay_s)
        console.print(f"[dim]GET[/dim] {url}")
        resp = self.client.get(url)
        resp.raise_for_status()
        return resp.text

    def fetch_catalog(self) -> Catalog:
        html = self._get(YALE_CATALOG)
        courses = list(self._parse_catalog(html))
        return Catalog(source="yale", course_count=len(courses), courses=courses)

    def _parse_catalog(self, html: str) -> Iterable[CourseRecord]:
        soup = BeautifulSoup(html, "lxml")
        table = soup.select_one("table.views-table")
        if not table:
            raise RuntimeError("Yale catalog table not found — page structure may have changed.")

        for row in table.select("tbody tr"):
            cells = row.find_all("td")
            if len(cells) < 5:
                continue
            dept = cells[0].get_text(" ", strip=True)
            number = cells[1].get_text(" ", strip=True)
            title_cell = cells[2]
            link = title_cell.find("a", href=True)
            title = title_cell.get_text(" ", strip=True)
            professor = cells[3].get_text(" ", strip=True)
            term = cells[4].get_text(" ", strip=True)
            if not link:
                continue
            path = link["href"].strip()
            slug = path.strip("/").replace("/", "-")
            course_id = f"yale:{number.lower().replace(' ', '-')}"
            yield CourseRecord(
                id=course_id,
                source="yale",
                department=dept,
                number=number,
                title=title,
                professor=professor,
                term=term,
                path=path,
                url=f"{YALE_BASE}{path}",
                license=YALE_LICENSE,
                attribution=Attribution(
                    faculty=professor,
                    course_title=title,
                    institution="Yale University",
                    project="Open Yale Courses",
                    source_url=f"{YALE_BASE}{path}",
                ),
            )

    def enrich_course(self, course: CourseRecord, max_lectures: int | None = None) -> CourseRecord:
        html = self._get(course.url)
        soup = BeautifulSoup(html, "lxml")
        about = self._extract_about(soup)
        lectures = self._extract_lectures(soup, course.path)
        if max_lectures is not None:
            lectures = lectures[:max_lectures]

        filled: list[LectureOutline] = []
        for lec in lectures:
            try:
                lec_html = self._get(lec.url)
                lec.overview = self._extract_overview(BeautifulSoup(lec_html, "lxml"))
                if not lec.title or lec.title.lower().startswith("lecture"):
                    lec.title = self._extract_lecture_title(BeautifulSoup(lec_html, "lxml"), lec)
            except httpx.HTTPError as exc:
                console.print(f"[yellow]Lecture fetch failed[/yellow] {lec.url}: {exc}")
            filled.append(lec)

        course.about = about
        course.lectures = filled
        if course.attribution:
            course.attribution.accessed_at = utc_now()
        return course

    def _extract_about(self, soup: BeautifulSoup) -> str:
        header = soup.find(string=re.compile(r"About the Course", re.I))
        if not header:
            return ""
        parent = header.find_parent(["h2", "h3", "h4", "span", "div"])
        root = parent or header.parent
        parts: list[str] = []
        for sib in root.find_next_siblings():
            if sib.name in {"h2", "h3", "h4"}:
                break
            text = sib.get_text(" ", strip=True)
            if text and text.lower() != "about the course":
                parts.append(text)
        if parts:
            return "\n\n".join(parts)
        # Sometimes the blurb is the next element after a label wrapper
        nxt = root.find_next(["p", "div"])
        if nxt:
            text = nxt.get_text(" ", strip=True)
            if text and "about the course" not in text.lower():
                return text
        return ""

    def _extract_lectures(self, soup: BeautifulSoup, course_path: str) -> list[LectureOutline]:
        # Catalog paths (e.g. /death/phil-176) often differ from lecture paths
        # (e.g. /philosophy/phil-176/lecture-1). Prefer exact prefix, then
        # fall back to any /lecture-N link that shares the course number segment.
        course_path = course_path.rstrip("/")
        number_slug = course_path.split("/")[-1]  # phil-176 or econ-252
        exact = re.compile(rf"^{re.escape(course_path)}/lecture-(\d+)/?$")
        loose = re.compile(rf"^/.*/{re.escape(number_slug)}(?:-[0-9]+)?/lecture-(\d+)/?$")
        found: dict[int, LectureOutline] = {}
        for a in soup.find_all("a", href=True):
            href = a["href"].split("?")[0]
            m = exact.match(href) or loose.match(href)
            if not m:
                # Last resort: any lecture link on the page
                m2 = re.match(r"^/.+/lecture-(\d+)/?$", href)
                if not m2:
                    continue
                # Prefer links that share the course number token
                if number_slug.split("-")[0] not in href and number_slug not in href:
                    continue
                m = m2
            idx = int(m.group(1))
            title = a.get_text(" ", strip=True) or f"Lecture {idx}"
            # Prefer richer titles if we see the link twice
            existing = found.get(idx)
            if existing and len(existing.title) >= len(title):
                continue
            found[idx] = LectureOutline(
                id=f"lecture-{idx}",
                index=idx,
                title=title,
                path=href,
                url=f"{YALE_BASE}{href}",
            )
        return [found[k] for k in sorted(found)]

    def _extract_overview(self, soup: BeautifulSoup) -> str:
        header = soup.find(string=re.compile(r"^\s*Overview\s*$", re.I))
        if not header:
            return ""
        parent = header.find_parent(["h2", "h3", "h4", "strong", "b"])
        root = parent or header.parent
        parts: list[str] = []
        for sib in root.find_next_siblings():
            if sib.name in {"h2", "h3", "h4"}:
                break
            text = sib.get_text(" ", strip=True)
            if text:
                parts.append(text)
        return "\n\n".join(parts)

    def _extract_lecture_title(self, soup: BeautifulSoup, lec: LectureOutline) -> str:
        h1s = [h.get_text(" ", strip=True) for h in soup.select("h1")]
        for title in h1s:
            if title and not re.match(r"^PHIL|^ECON|^HIST|^PSYC", title):
                return title
        page_title = soup.title.get_text(" ", strip=True) if soup.title else ""
        m = re.search(r"Lecture\s+\d+\s*-\s*(.+?)\s*\|\s*Open Yale", page_title, re.I)
        if m:
            return m.group(1).strip()
        return lec.title


def save_json(model, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(model.model_dump_json(indent=2), encoding="utf-8")
    console.print(f"[green]Wrote[/green] {path}")

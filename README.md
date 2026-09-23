# aBit

**College, in bites.**

aBit turns free open-course material from universities into Duolingo-style micro-lessons — learn, quiz to pass, earn a playful “degree,” and compete with friends. Think Imprint energy, campus depth, Apple Design Award polish.

> Repo: [`JParadela112109/aBit-`](https://github.com/JParadela112109/aBit-)

## What’s in this monorepo

| Path | Purpose |
| --- | --- |
| `scraper/` | Phase 1 — harvest open-course **catalogs, lecture outlines, and overviews** (Yale OYC first) into structured JSON |
| `ios/ABit/` | SwiftUI app shell — design system, browse → bite → quiz → degree → social stubs |
| `docs/` | Product vision, licensing, roadmap |

## Phase 1 (now): Scraping → iOS in one step

```bash
cd scraper
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
PYTHONPATH=. python -m abit_scraper catalog --source yale
PYTHONPATH=. python -m abit_scraper course --source yale --slug death/phil-176
PYTHONPATH=. python -m abit_scraper bites --course-id yale:phil-176
PYTHONPATH=. python -m abit_scraper bundle --course-id yale:phil-176
```

That writes `ios/ABit/Resources/Courses/yale_phil-176.course.json`. Rebuild the app — the course appears under **Paths**. See [docs/ADDING_COURSES.md](docs/ADDING_COURSES.md).

### Licensing (important)

Open Yale Courses material is mostly **CC BY-NC-SA 3.0**. We store license + attribution on every artifact. That license is **non-commercial** — a commercial aBit product needs separate rights, original content, or CC sources that allow your use case. The scraper records provenance so we never lose the trail.

## Phase 2+: iOS

```bash
cd ios && brew install xcodegen && xcodegen generate && open ABit.xcodeproj
```

## Product pillars

1. **Bites** — one idea, one screen, high craft  
2. **Prove it** — lecture checks that feed a real letter grade  
3. **College** — programs, credits, GPA, transcript, commence to graduate  
4. **Friends** — streaks, leaderboards, what they’re studying  

Degree rules: [docs/DEGREES.md](docs/DEGREES.md).

## Stack

- Scraper: Python 3.12, httpx, BeautifulSoup, pydantic  
- App: SwiftUI, Observation, drop-in course JSON bundles

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

## Phase 1 (now): Scraping

```bash
cd scraper
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python -m abit_scraper catalog --source yale
python -m abit_scraper course --source yale --slug death/phil-176
python -m abit_scraper bites --course-id yale:phil-176
```

Outputs land in `scraper/data/`. Sample fixtures ship in `scraper/data/samples/`.

### Licensing (important)

Open Yale Courses material is mostly **CC BY-NC-SA 3.0**. We store license + attribution on every artifact. That license is **non-commercial** — a commercial aBit product needs separate rights, original content, or CC sources that allow your use case. The scraper records provenance so we never lose the trail.

## Phase 2+: iOS

Open `ios/ABit` in Xcode 16+, select an iPhone simulator, Run.

## Product pillars

1. **Bites** — one idea, one screen, high craft  
2. **Prove it** — short checks to unlock the next module  
3. **Degrees** — playful credentials after you pass a path  
4. **Friends** — streaks, leaderboards, what they’re studying  

## Stack

- Scraper: Python 3.12, httpx, BeautifulSoup, pydantic  
- App: SwiftUI, SwiftData (planned), Observation

# aBit scraper

Harvest open university course catalogs into structured JSON, then emit bite packs for the iOS app.

## Quick start

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
PYTHONPATH=. python -m abit_scraper catalog --source yale
PYTHONPATH=. python -m abit_scraper course --source yale --slug death/phil-176 --max-lectures 5
PYTHONPATH=. python -m abit_scraper bites --course-id yale:phil-176
PYTHONPATH=. python -m abit_scraper export-ios --bites-file data/bites/yale_phil-176.json
```

Be polite: the client rate-limits requests (~0.6s delay).

## Sources

| Source | Status |
| --- | --- |
| Yale Open Courses | ✅ catalog + lecture overviews |
| MIT OCW | planned |
| Others | planned |

See `../docs/LICENSING.md` before shipping commercially.

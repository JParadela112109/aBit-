# Adding courses after scraping

aBit loads every `*.course.json` in the iOS app bundle folder:

```text
ios/ABit/Resources/Courses/
  manifest.json                 # auto-updated
  yale_phil-176.course.json
  yale_psyc-110.course.json
  …
```

## One-command path

From `scraper/`:

```bash
# 1. Scrape catalog (once)
PYTHONPATH=. python -m abit_scraper catalog --source yale

# 2. Scrape a course (use catalog path slug)
PYTHONPATH=. python -m abit_scraper course --source yale --slug death/phil-176
PYTHONPATH=. python -m abit_scraper bites --course-id yale:phil-176

# 3. Drop into the iOS app
PYTHONPATH=. python -m abit_scraper bundle --course-id yale:phil-176
```

Or bundle everything you’ve scraped:

```bash
PYTHONPATH=. python -m abit_scraper bundle-all
```

## Then in Xcode

1. Confirm the new `*.course.json` is in the **ABit** target → **Copy Bundle Resources**
2. Build & run — it appears under **Paths** on the Learn tab

No Swift code changes required for a new course.

## Bundle schema (`schema_version: 1`)

```json
{
  "schema_version": 1,
  "course": { "id", "title", "professor", "department", "about", "accent_label", "license", "attribution", … },
  "bites": [ { "id", "headline", "body", "kind", "attribution_line", … } ],
  "quizzes": [ { "id", "prompt", "choices", "answer_index", … } ]
}
```

`CourseLibrary.swift` discovers files by extension — keep the `.course.json` suffix.

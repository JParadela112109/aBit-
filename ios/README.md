# iOS — aBit

SwiftUI app aimed at Apple Design Award craft: brand-first Learn hero, immersive bites, checkpoints, playful degrees, friends.

## Open in Xcode

**Option A — XcodeGen (recommended)**

```bash
brew install xcodegen
cd ios
xcodegen generate
open ABit.xcodeproj
```

**Option B — manual**

1. File → New → Project → App (SwiftUI, Swift, iOS 17+)
2. Replace sources with `ABit/`
3. Add `Resources/Courses/*.course.json` (+ `manifest.json`) to **Copy Bundle Resources**
4. Run on iPhone simulator

## Adding courses

See [`../docs/ADDING_COURSES.md`](../docs/ADDING_COURSES.md). Short version:

```bash
cd ../scraper
PYTHONPATH=. python -m abit_scraper bundle --course-id yale:phil-176
# rebuild iOS
```

## Structure

| Path | Role |
| --- | --- |
| `ABit/Content/CourseLibrary.swift` | Auto-loads `*.course.json` |
| `ABit/Resources/Courses/` | Drop-in course bundles |
| `ABit/Design/` | Theme, atmosphere, buttons |
| `ABit/Features/` | Learn, detail, bites, quiz, degree, friends |

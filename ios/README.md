# iOS app (SwiftUI)

## Open in Xcode

1. Xcode 16+ → **File → New → Project → App**
2. Product Name: `ABit`, Interface: SwiftUI, Language: Swift
3. Replace the generated source group with the files in this `ABit/` folder
4. Add `Resources/SampleBites.json` to the app target (Copy Bundle Resources)
5. Deployment target **iOS 17.0+**
6. Run on iPhone 16 simulator

## What’s implemented

- Brand-first Learn home
- Bite session with motion + attribution
- Checkpoint quiz sheet
- Playful Degree screen (clearly not accredited)
- Friends leaderboard stub

Wire live scraped JSON via `python -m abit_scraper export-ios`.

import Foundation

enum CourseLibrary {
    /// Loads every `*.course.json` shipped in the app bundle.
    /// Add a course: `python -m abit_scraper bundle --course-id …` then rebuild.
    static func loadBundles() -> [CourseBundleFile] {
        let decoder = JSONDecoder()
        let candidates = resourceURLs().filter { $0.lastPathComponent.hasSuffix(".course.json") }

        var bundles: [CourseBundleFile] = []
        var seen = Set<String>()
        for url in candidates.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard let data = try? Data(contentsOf: url),
                  let bundle = try? decoder.decode(CourseBundleFile.self, from: data),
                  !bundle.bites.isEmpty,
                  seen.insert(bundle.course.id).inserted
            else { continue }
            bundles.append(bundle)
        }

        if bundles.isEmpty, let legacy = loadLegacySample() {
            bundles = [legacy]
        }
        return bundles
    }

    private static func resourceURLs() -> [URL] {
        let sub = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Courses") ?? []
        let root = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        return sub + root
    }

    private static func loadLegacySample() -> CourseBundleFile? {
        guard let url = Bundle.main.url(forResource: "SampleBites", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(LegacyBitePack.self, from: data)
        else { return nil }

        let meta = CourseMeta(
            id: pack.courseId,
            source: "yale",
            title: "Death",
            professor: "Shelly Kagan",
            department: "Philosophy",
            number: "PHIL 176",
            term: "Spring 2007",
            about: "",
            url: "https://oyc.yale.edu/death/phil-176",
            accentLabel: "Yale · Open Course",
            license: LicenseMeta(spdx: "CC-BY-NC-SA-3.0", commercialOk: false),
            attribution: AttributionMeta(faculty: "Shelly Kagan", creditLine: nil)
        )
        return CourseBundleFile(schemaVersion: 1, course: meta, bites: pack.bites, quizzes: pack.quizzes)
    }
}

private struct LegacyBitePack: Codable {
    let courseId: String
    let bites: [BiteCard]
    let quizzes: [QuizItem]

    enum CodingKeys: String, CodingKey {
        case bites, quizzes
        case courseId = "course_id"
    }
}

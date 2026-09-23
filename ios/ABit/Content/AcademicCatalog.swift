import Foundation

enum AcademicCatalog {
    static func load() -> AcademicCatalogFile {
        if let url = Bundle.main.url(forResource: "programs", withExtension: "json", subdirectory: "Academic")
            ?? Bundle.main.url(forResource: "programs", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(AcademicCatalogFile.self, from: data) {
            return file
        }
        return .fallback
    }
}

extension AcademicCatalogFile {
    /// Built-in catalog so the app works even before the JSON is in the target.
    static var fallback: AcademicCatalogFile {
        AcademicCatalogFile(
            schemaVersion: 1,
            programs: [
                DegreeProgram(
                    id: "ba-liberal-arts",
                    title: "Bachelor of Arts",
                    concentration: "Liberal Arts",
                    school: "aBit College",
                    credential: "B.A.",
                    summary: "A full undergraduate path: humanities, mind & behavior, and markets.",
                    minCredits: 12,
                    minGPA: 2.0,
                    requirements: [
                        DegreeRequirement(
                            id: "core-humanities",
                            kind: .required,
                            title: "Humanities core",
                            courseIds: ["yale:phil-176"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                        DegreeRequirement(
                            id: "core-social",
                            kind: .required,
                            title: "Social science core",
                            courseIds: ["yale:psyc-110"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                        DegreeRequirement(
                            id: "core-markets",
                            kind: .required,
                            title: "Markets & society",
                            courseIds: ["yale:econ-252"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                    ],
                    disclaimer: "Not an accredited university degree. aBit credentials are playful completion seals."
                ),
                DegreeProgram(
                    id: "ba-philosophy",
                    title: "Bachelor of Arts",
                    concentration: "Philosophy",
                    school: "aBit College",
                    credential: "B.A.",
                    summary: "Pass Death, then add electives from psychology or markets.",
                    minCredits: 8,
                    minGPA: 2.0,
                    requirements: [
                        DegreeRequirement(
                            id: "phil-major",
                            kind: .required,
                            title: "Philosophy major",
                            courseIds: ["yale:phil-176"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                        DegreeRequirement(
                            id: "phil-electives",
                            kind: .elective,
                            title: "Electives",
                            courseIds: ["yale:psyc-110", "yale:econ-252"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                    ],
                    disclaimer: "Not an accredited university degree. aBit credentials are playful completion seals."
                ),
                DegreeProgram(
                    id: "cert-mind-markets",
                    title: "Certificate",
                    concentration: "Mind & Markets",
                    school: "aBit College",
                    credential: "Certificate",
                    summary: "A shorter path: psychology plus one markets or philosophy elective.",
                    minCredits: 8,
                    minGPA: 2.0,
                    requirements: [
                        DegreeRequirement(
                            id: "cert-psych",
                            kind: .required,
                            title: "Psychology foundation",
                            courseIds: ["yale:psyc-110"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                        DegreeRequirement(
                            id: "cert-elective",
                            kind: .elective,
                            title: "Elective",
                            courseIds: ["yale:phil-176", "yale:econ-252"],
                            minCredits: 4,
                            creditsEach: 4
                        ),
                    ],
                    disclaimer: "Not an accredited university degree. aBit credentials are playful completion seals."
                ),
            ],
            courseCredits: [
                "yale:phil-176": 4,
                "yale:psyc-110": 4,
                "yale:econ-252": 4,
            ],
            prerequisites: [:]
        )
    }
}

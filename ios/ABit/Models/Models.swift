import Foundation
import SwiftUI

// MARK: - Drop-in course bundle (from scraper `bundle` command)

struct CourseBundleFile: Codable {
    let schemaVersion: Int
    let course: CourseMeta
    let bites: [BiteCard]
    let quizzes: [QuizItem]

    enum CodingKeys: String, CodingKey {
        case bites, quizzes, course
        case schemaVersion = "schema_version"
    }
}

struct CourseMeta: Identifiable, Codable, Hashable {
    let id: String
    let source: String
    let title: String
    let professor: String
    let department: String
    let number: String
    let term: String
    let about: String
    let url: String
    let accentLabel: String
    let license: LicenseMeta?
    let attribution: AttributionMeta?

    enum CodingKeys: String, CodingKey {
        case id, source, title, professor, department, number, term, about, url, license, attribution
        case accentLabel = "accent_label"
    }

    var biteReady: Bool { true }

    var shortProfessor: String {
        professor.split(separator: " ").last.map(String.init) ?? professor
    }
}

struct LicenseMeta: Codable, Hashable {
    let spdx: String
    let commercialOk: Bool

    enum CodingKeys: String, CodingKey {
        case spdx
        case commercialOk = "commercial_ok"
    }
}

struct AttributionMeta: Codable, Hashable {
    let faculty: String
    let creditLine: String?

    enum CodingKeys: String, CodingKey {
        case faculty
        case creditLine = "credit_line"
    }
}

struct ManifestFile: Codable {
    let schemaVersion: Int
    let courses: [String]

    enum CodingKeys: String, CodingKey {
        case courses
        case schemaVersion = "schema_version"
    }
}

struct BiteCard: Identifiable, Codable, Hashable {
    let id: String
    let courseId: String
    let lectureId: String
    let order: Int
    let kind: String
    let headline: String
    let body: String
    let attributionLine: String
    let sourceUrl: String
    let licenseSpdx: String

    enum CodingKeys: String, CodingKey {
        case id, order, kind, headline, body
        case courseId = "course_id"
        case lectureId = "lecture_id"
        case attributionLine = "attribution_line"
        case sourceUrl = "source_url"
        case licenseSpdx = "license_spdx"
    }

    var kindLabel: String {
        switch kind {
        case "story": return "Opening"
        case "takeaway": return "Carry forward"
        case "key_term": return "Key term"
        default: return "Concept"
        }
    }
}

struct QuizItem: Identifiable, Codable, Hashable {
    let id: String
    let courseId: String
    let lectureId: String
    let prompt: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case id, prompt, choices, explanation
        case courseId = "course_id"
        case lectureId = "lecture_id"
        case answerIndex = "answer_index"
    }
}

struct FriendActivity: Identifiable, Hashable {
    let id: String
    let name: String
    let studying: String
    let bitsToday: Int
}

// MARK: - Department accent (deterministic, non-purple)

enum CourseAccent {
    case forest, ocean, ember, slate, honey

    var glow: Color {
        switch self {
        case .forest: return Color(red: 0.35, green: 0.55, blue: 0.40)
        case .ocean: return Color(red: 0.28, green: 0.48, blue: 0.58)
        case .ember: return Color(red: 0.72, green: 0.42, blue: 0.28)
        case .slate: return Color(red: 0.42, green: 0.48, blue: 0.55)
        case .honey: return Color(red: 0.78, green: 0.62, blue: 0.22)
        }
    }

    var chip: Color {
        glow.opacity(0.9)
    }

    static func forDepartment(_ department: String) -> CourseAccent {
        let key = department.lowercased()
        if key.contains("psych") { return .ocean }
        if key.contains("econ") || key.contains("financ") { return .honey }
        if key.contains("phil") { return .forest }
        if key.contains("hist") { return .ember }
        let hash = abs(department.hashValue)
        return [.forest, .ocean, .ember, .slate, .honey][hash % 5]
    }
}

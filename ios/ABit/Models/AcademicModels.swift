import Foundation

// MARK: - Academic catalog (drop-in JSON)

struct AcademicCatalogFile: Codable {
    let schemaVersion: Int
    let programs: [DegreeProgram]
    let courseCredits: [String: Int]
    let prerequisites: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case programs
        case schemaVersion = "schema_version"
        case courseCredits = "course_credits"
        case prerequisites
    }
}

struct DegreeProgram: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let concentration: String
    let school: String
    let credential: String
    let summary: String
    let minCredits: Int
    let minGPA: Double
    let requirements: [DegreeRequirement]
    let disclaimer: String

    enum CodingKeys: String, CodingKey {
        case id, title, concentration, school, credential, summary, requirements, disclaimer
        case minCredits = "min_credits"
        case minGPA = "min_gpa"
    }

    var fullName: String {
        if concentration.isEmpty { return "\(credential) · \(title)" }
        return "\(credential) in \(concentration)"
    }
}

struct DegreeRequirement: Identifiable, Codable, Hashable {
    let id: String
    let kind: RequirementKind
    let title: String
    let courseIds: [String]
    /// For `required`: each listed course must be passed.
    /// For `elective`: earn at least `minCredits` from the pool.
    let minCredits: Int
    let creditsEach: Int

    enum CodingKeys: String, CodingKey {
        case id, kind, title
        case courseIds = "course_ids"
        case minCredits = "min_credits"
        case creditsEach = "credits_each"
    }
}

enum RequirementKind: String, Codable, Hashable {
    case required
    case elective
}

enum LetterGrade: String, Codable, Comparable {
    case a = "A"
    case aMinus = "A-"
    case bPlus = "B+"
    case b = "B"
    case bMinus = "B-"
    case cPlus = "C+"
    case c = "C"
    case cMinus = "C-"
    case d = "D"
    case f = "F"

    var points: Double {
        switch self {
        case .a: return 4.0
        case .aMinus: return 3.7
        case .bPlus: return 3.3
        case .b: return 3.0
        case .bMinus: return 2.7
        case .cPlus: return 2.3
        case .c: return 2.0
        case .cMinus: return 1.7
        case .d: return 1.0
        case .f: return 0.0
        }
    }

    var isPassing: Bool { self != .f }

    static func < (lhs: LetterGrade, rhs: LetterGrade) -> Bool {
        lhs.points < rhs.points
    }

    static func fromScore(_ score: Double) -> LetterGrade {
        switch score {
        case 0.93...: return .a
        case 0.90..<0.93: return .aMinus
        case 0.87..<0.90: return .bPlus
        case 0.83..<0.87: return .b
        case 0.80..<0.83: return .bMinus
        case 0.77..<0.80: return .cPlus
        case 0.73..<0.77: return .c
        case 0.70..<0.73: return .cMinus
        case 0.60..<0.70: return .d
        default: return .f
        }
    }
}

struct TranscriptEntry: Identifiable, Hashable {
    let id: String
    let courseID: String
    let title: String
    let department: String
    let credits: Int
    let grade: LetterGrade
    let passed: Bool
}

struct RequirementProgress: Identifiable, Hashable {
    let id: String
    let title: String
    let kind: RequirementKind
    let satisfied: Bool
    let detail: String
    let courseStatuses: [RequirementCourseStatus]
}

struct RequirementCourseStatus: Identifiable, Hashable {
    var id: String { courseID }
    let courseID: String
    let title: String
    let credits: Int
    let state: CourseAcademicState
    let grade: LetterGrade?
}

enum CourseAcademicState: String, Hashable {
    case locked
    case available
    case inProgress
    case passed
    case failed
}

struct ProgramProgress: Identifiable, Hashable {
    let id: String
    let program: DegreeProgram
    let creditsEarned: Int
    let creditsRequired: Int
    let gpa: Double?
    let requirements: [RequirementProgress]
    let canGraduate: Bool
    let blockingReasons: [String]
    let conferred: Bool
}

struct ConferredDegree: Identifiable, Codable, Hashable {
    let id: String
    let programID: String
    let credential: String
    let concentration: String
    let conferredAt: Date
    let gpa: Double
    let credits: Int
}

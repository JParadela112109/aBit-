import Foundation

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

struct BitePack: Codable {
    let courseId: String
    let bites: [BiteCard]
    let quizzes: [QuizItem]

    enum CodingKeys: String, CodingKey {
        case bites, quizzes
        case courseId = "course_id"
    }
}

struct CourseSummary: Identifiable, Hashable {
    let id: String
    let title: String
    let professor: String
    let department: String
    let biteCount: Int
    let accentLabel: String
}

struct FriendActivity: Identifiable, Hashable {
    let id: String
    let name: String
    let studying: String
    let bitsToday: Int
}

import Foundation
import Observation

@Observable
final class AppStore {
    var courses: [CourseSummary] = []
    var bites: [BiteCard] = []
    var quizzes: [QuizItem] = []
    var completedBiteIDs: Set<String> = []
    var friends: [FriendActivity] = [
        .init(id: "1", name: "Maya", studying: "Death · Kagan", bitsToday: 12),
        .init(id: "2", name: "Noah", studying: "Psych · Bloom", bitsToday: 8),
        .init(id: "3", name: "Ava", studying: "Markets · Shiller", bitsToday: 15),
    ]

    var progress: Double {
        guard !bites.isEmpty else { return 0 }
        return Double(completedBiteIDs.count) / Double(bites.count)
    }

    init() {
        loadSample()
    }

    func loadSample() {
        guard let url = Bundle.main.url(forResource: "SampleBites", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(BitePack.self, from: data)
        else {
            loadFallback()
            return
        }
        bites = pack.bites.sorted { $0.order < $1.order }
        quizzes = pack.quizzes
        courses = [
            CourseSummary(
                id: pack.courseId,
                title: "Death",
                professor: "Shelly Kagan",
                department: "Philosophy",
                biteCount: pack.bites.count,
                accentLabel: "Yale · Open Course"
            )
        ]
    }

    private func loadFallback() {
        courses = [
            CourseSummary(
                id: "yale:phil-176",
                title: "Death",
                professor: "Shelly Kagan",
                department: "Philosophy",
                biteCount: 3,
                accentLabel: "Yale · Open Course"
            )
        ]
        bites = [
            BiteCard(
                id: "demo-1",
                courseId: "yale:phil-176",
                lectureId: "lecture-1",
                order: 1,
                kind: "concept",
                headline: "What is death, philosophically?",
                body: "Before ethics, ask what kind of thing death is — and what, exactly, ends.",
                attributionLine: "Shelly Kagan, Death (Yale University: Open Yale Courses)",
                sourceUrl: "https://oyc.yale.edu/philosophy/phil-176",
                licenseSpdx: "CC-BY-NC-SA-3.0"
            )
        ]
    }

    func markComplete(_ bite: BiteCard) {
        completedBiteIDs.insert(bite.id)
    }
}

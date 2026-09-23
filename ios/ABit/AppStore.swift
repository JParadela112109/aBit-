import Foundation
import Observation

@Observable
final class AppStore {
    private(set) var bundles: [CourseBundleFile] = []
    var selectedCourseID: String?
    var completedBiteIDs: Set<String> = []
    var passedQuizIDs: Set<String> = []
    var friends: [FriendActivity] = [
        .init(id: "1", name: "Maya", studying: "Death · Kagan", bitsToday: 12),
        .init(id: "2", name: "Noah", studying: "Psych · Bloom", bitsToday: 8),
        .init(id: "3", name: "Ava", studying: "Markets · Shiller", bitsToday: 15),
    ]

    var courses: [CourseMeta] { bundles.map(\.course) }

    var selectedBundle: CourseBundleFile? {
        if let id = selectedCourseID {
            return bundles.first { $0.course.id == id }
        }
        return bundles.first
    }

    var selectedCourse: CourseMeta? { selectedBundle?.course }

    func bites(for courseID: String) -> [BiteCard] {
        bundles.first { $0.course.id == courseID }?
            .bites.sorted { $0.order < $1.order } ?? []
    }

    func quizzes(for courseID: String) -> [QuizItem] {
        bundles.first { $0.course.id == courseID }?.quizzes ?? []
    }

    func progress(for courseID: String) -> Double {
        let bites = bites(for: courseID)
        guard !bites.isEmpty else { return 0 }
        let done = bites.filter { completedBiteIDs.contains($0.id) }.count
        return Double(done) / Double(bites.count)
    }

    var overallBitsCleared: Int {
        completedBiteIDs.count
    }

    var earnedDegrees: [CourseMeta] {
        courses.filter { progress(for: $0.id) >= 0.99 }
    }

    init() {
        reloadCourses()
    }

    func reloadCourses() {
        bundles = CourseLibrary.loadBundles()
        if selectedCourseID == nil {
            selectedCourseID = bundles.first?.course.id
        }
    }

    func select(_ course: CourseMeta) {
        selectedCourseID = course.id
    }

    func markComplete(_ bite: BiteCard) {
        completedBiteIDs.insert(bite.id)
    }

    func markQuizPassed(_ quiz: QuizItem) {
        passedQuizIDs.insert(quiz.id)
    }
}

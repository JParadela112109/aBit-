import Foundation
import Observation

@Observable
final class AppStore {
    private(set) var bundles: [CourseBundleFile] = []
    private(set) var academicCatalog: AcademicCatalogFile = .fallback

    var selectedCourseID: String?
    var enrolledProgramIDs: Set<String> = []
    var completedBiteIDs: Set<String> = []
    var passedQuizIDs: Set<String> = []
    /// quizID → attempt count (wrong answers count too)
    var quizAttempts: [String: Int] = [:]
    var conferredDegrees: [ConferredDegree] = []

    var friends: [FriendActivity] = [
        .init(id: "1", name: "Maya", studying: "B.A. Philosophy", bitsToday: 12),
        .init(id: "2", name: "Noah", studying: "Certificate · Mind & Markets", bitsToday: 8),
        .init(id: "3", name: "Ava", studying: "B.A. Liberal Arts", bitsToday: 15),
    ]

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let bites = "abit.completedBiteIDs"
        static let quizzes = "abit.passedQuizIDs"
        static let attempts = "abit.quizAttempts"
        static let enrolled = "abit.enrolledProgramIDs"
        static let conferred = "abit.conferredDegrees"
    }

    var courses: [CourseMeta] { bundles.map(\.course) }
    var programs: [DegreeProgram] { academicCatalog.programs }

    var selectedBundle: CourseBundleFile? {
        if let id = selectedCourseID {
            return bundles.first { $0.course.id == id }
        }
        return bundles.first
    }

    var selectedCourse: CourseMeta? { selectedBundle?.course }

    var engine: AcademicEngine {
        AcademicEngine(
            catalog: academicCatalog,
            courses: courses,
            bitesByCourse: Dictionary(uniqueKeysWithValues: bundles.map { ($0.course.id, $0.bites) }),
            quizzesByCourse: Dictionary(uniqueKeysWithValues: bundles.map { ($0.course.id, $0.quizzes) }),
            completedBiteIDs: completedBiteIDs,
            passedQuizIDs: passedQuizIDs,
            quizAttempts: quizAttempts,
            conferred: conferredDegrees
        )
    }

    func bites(for courseID: String) -> [BiteCard] {
        bundles.first { $0.course.id == courseID }?
            .bites.sorted { $0.order < $1.order } ?? []
    }

    func quizzes(for courseID: String) -> [QuizItem] {
        bundles.first { $0.course.id == courseID }?.quizzes ?? []
    }

    func progress(for courseID: String) -> Double {
        engine.biteCompletion(for: courseID)
    }

    func credits(for courseID: String) -> Int {
        engine.credits(for: courseID)
    }

    func isCourseLocked(_ courseID: String) -> Bool {
        engine.academicState(for: courseID) == .locked
    }

    func isCoursePassed(_ courseID: String) -> Bool {
        engine.isPassed(courseID)
    }

    func letterGrade(for courseID: String) -> LetterGrade? {
        engine.letterGrade(for: courseID)
    }

    func programProgress(_ program: DegreeProgram) -> ProgramProgress {
        engine.progress(for: program)
    }

    var enrolledPrograms: [DegreeProgram] {
        programs.filter { enrolledProgramIDs.contains($0.id) }
    }

    init() {
        loadPersisted()
        reloadCourses()
    }

    func reloadCourses() {
        bundles = CourseLibrary.loadBundles()
        academicCatalog = AcademicCatalog.load()
        if selectedCourseID == nil {
            selectedCourseID = bundles.first?.course.id
        }
    }

    func select(_ course: CourseMeta) {
        selectedCourseID = course.id
    }

    func enroll(in program: DegreeProgram) {
        enrolledProgramIDs.insert(program.id)
        persist()
    }

    func unenroll(from program: DegreeProgram) {
        enrolledProgramIDs.remove(program.id)
        persist()
    }

    func markComplete(_ bite: BiteCard) {
        completedBiteIDs.insert(bite.id)
        persist()
    }

    func recordQuizAttempt(_ quiz: QuizItem, correct: Bool) {
        quizAttempts[quiz.id, default: 0] += 1
        if correct {
            passedQuizIDs.insert(quiz.id)
        }
        persist()
    }

    func markQuizPassed(_ quiz: QuizItem) {
        recordQuizAttempt(quiz, correct: true)
    }

    @discardableResult
    func commence(_ program: DegreeProgram) -> ConferredDegree? {
        let progress = programProgress(program)
        guard progress.canGraduate else { return nil }
        let degree = ConferredDegree(
            id: "\(program.id)-\(Int(Date().timeIntervalSince1970))",
            programID: program.id,
            credential: program.fullName,
            concentration: program.concentration,
            conferredAt: Date(),
            gpa: progress.gpa ?? 0,
            credits: progress.creditsEarned
        )
        conferredDegrees.append(degree)
        persist()
        return degree
    }

    // MARK: - Persistence

    private func loadPersisted() {
        if let bites = defaults.array(forKey: Keys.bites) as? [String] {
            completedBiteIDs = Set(bites)
        }
        if let quizzes = defaults.array(forKey: Keys.quizzes) as? [String] {
            passedQuizIDs = Set(quizzes)
        }
        if let attempts = defaults.dictionary(forKey: Keys.attempts) as? [String: Int] {
            quizAttempts = attempts
        }
        if let enrolled = defaults.array(forKey: Keys.enrolled) as? [String] {
            enrolledProgramIDs = Set(enrolled)
        }
        if let data = defaults.data(forKey: Keys.conferred),
           let decoded = try? JSONDecoder().decode([ConferredDegree].self, from: data) {
            conferredDegrees = decoded
        }
    }

    private func persist() {
        defaults.set(Array(completedBiteIDs), forKey: Keys.bites)
        defaults.set(Array(passedQuizIDs), forKey: Keys.quizzes)
        defaults.set(quizAttempts, forKey: Keys.attempts)
        defaults.set(Array(enrolledProgramIDs), forKey: Keys.enrolled)
        if let data = try? JSONEncoder().encode(conferredDegrees) {
            defaults.set(data, forKey: Keys.conferred)
        }
    }
}

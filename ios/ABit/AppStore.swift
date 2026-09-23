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
    var quizAttempts: [String: Int] = [:]
    var conferredDegrees: [ConferredDegree] = []
    /// courseID → last bite index for resume
    var resumeIndexByCourse: [String: Int] = [:]
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStudyDay: String? // yyyy-MM-dd
    var bitsCompletedToday: Int = 0

    var friends: [FriendActivity] = [
        .init(id: "1", name: "Maya", studying: "B.A. Philosophy", bitsToday: 12),
        .init(id: "2", name: "Noah", studying: "Certificate · Mind & Markets", bitsToday: 8),
        .init(id: "3", name: "Ava", studying: "B.A. Liberal Arts", bitsToday: 15),
    ]

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    private enum Keys {
        static let bites = "abit.completedBiteIDs"
        static let quizzes = "abit.passedQuizIDs"
        static let attempts = "abit.quizAttempts"
        static let enrolled = "abit.enrolledProgramIDs"
        static let conferred = "abit.conferredDegrees"
        static let resume = "abit.resumeIndexByCourse"
        static let streak = "abit.currentStreak"
        static let longest = "abit.longestStreak"
        static let lastDay = "abit.lastStudyDay"
        static let bitsToday = "abit.bitsCompletedToday"
        static let bitsTodayDay = "abit.bitsTodayDay"
    }

    var courses: [CourseMeta] { bundles.map(\.course) }
    var programs: [DegreeProgram] { academicCatalog.programs }

    var dailyGoal: Int { 5 }

    var dailyGoalProgress: Double {
        min(1, Double(bitsCompletedToday) / Double(dailyGoal))
    }

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

    func finalExam(for courseID: String) -> QuizItem? {
        quizzes(for: courseID).first { $0.lectureId == "final" }
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
        rollDailyCountersIfNeeded()
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
        let wasNew = !completedBiteIDs.contains(bite.id)
        completedBiteIDs.insert(bite.id)
        if wasNew {
            recordStudyActivity(bitsDelta: 1)
        }
        persist()
    }

    func saveResumeIndex(_ index: Int, for courseID: String) {
        resumeIndexByCourse[courseID] = index
        persist()
    }

    func resumeIndex(for courseID: String) -> Int {
        let bites = bites(for: courseID)
        let saved = resumeIndexByCourse[courseID] ?? 0
        return min(max(0, saved), max(0, bites.count - 1))
    }

    func recordQuizAttempt(_ quiz: QuizItem, correct: Bool) {
        quizAttempts[quiz.id, default: 0] += 1
        if correct {
            passedQuizIDs.insert(quiz.id)
        }
        recordStudyActivity(bitsDelta: 0)
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

    // MARK: - Streaks

    private func todayKey() -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    private func rollDailyCountersIfNeeded() {
        let today = todayKey()
        let bitsDay = defaults.string(forKey: Keys.bitsTodayDay)
        if bitsDay != today {
            bitsCompletedToday = 0
            defaults.set(today, forKey: Keys.bitsTodayDay)
            defaults.set(0, forKey: Keys.bitsToday)
        }
    }

    private func recordStudyActivity(bitsDelta: Int) {
        rollDailyCountersIfNeeded()
        let today = todayKey()
        if bitsDelta > 0 {
            bitsCompletedToday += bitsDelta
        }

        if lastStudyDay == today {
            // already counted streak today
        } else if let last = lastStudyDay, let lastDate = date(from: last),
                  let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())),
                  calendar.isDate(lastDate, inSameDayAs: yesterday) {
            currentStreak += 1
            lastStudyDay = today
        } else {
            currentStreak = 1
            lastStudyDay = today
        }
        longestStreak = max(longestStreak, currentStreak)
    }

    private func date(from key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
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
        if let resume = defaults.dictionary(forKey: Keys.resume) as? [String: Int] {
            resumeIndexByCourse = resume
        }
        currentStreak = defaults.integer(forKey: Keys.streak)
        longestStreak = defaults.integer(forKey: Keys.longest)
        lastStudyDay = defaults.string(forKey: Keys.lastDay)
        bitsCompletedToday = defaults.integer(forKey: Keys.bitsToday)
    }

    private func persist() {
        defaults.set(Array(completedBiteIDs), forKey: Keys.bites)
        defaults.set(Array(passedQuizIDs), forKey: Keys.quizzes)
        defaults.set(quizAttempts, forKey: Keys.attempts)
        defaults.set(Array(enrolledProgramIDs), forKey: Keys.enrolled)
        defaults.set(resumeIndexByCourse, forKey: Keys.resume)
        defaults.set(currentStreak, forKey: Keys.streak)
        defaults.set(longestStreak, forKey: Keys.longest)
        defaults.set(lastStudyDay, forKey: Keys.lastDay)
        defaults.set(bitsCompletedToday, forKey: Keys.bitsToday)
        defaults.set(todayKey(), forKey: Keys.bitsTodayDay)
        if let data = try? JSONEncoder().encode(conferredDegrees) {
            defaults.set(data, forKey: Keys.conferred)
        }
    }
}

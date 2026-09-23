import Foundation

/// University-style rules for passing courses and graduating programs.
enum AcademicRules {
    /// Minimum bite completion to sit for / earn a passing course grade.
    static let minBiteCompletionToPass = 0.80
    /// Minimum quiz accuracy (passed / total) when quizzes exist.
    static let minQuizPassRate = 0.70
    /// Weighted score: quizzes matter more than skimming bites.
    static let biteWeight = 0.40
    static let quizWeight = 0.60
}

struct AcademicEngine {
    let catalog: AcademicCatalogFile
    let courses: [CourseMeta]
    let bitesByCourse: [String: [BiteCard]]
    let quizzesByCourse: [String: [QuizItem]]
    let completedBiteIDs: Set<String>
    let passedQuizIDs: Set<String>
    let quizAttempts: [String: Int]
    let conferred: [ConferredDegree]

    func credits(for courseID: String) -> Int {
        catalog.courseCredits[courseID] ?? 4
    }

    func prerequisites(for courseID: String) -> [String] {
        catalog.prerequisites[courseID] ?? []
    }

    func prereqsSatisfied(for courseID: String) -> Bool {
        prerequisites(for: courseID).allSatisfy { isPassed($0) }
    }

    func biteCompletion(for courseID: String) -> Double {
        let bites = bitesByCourse[courseID] ?? []
        guard !bites.isEmpty else { return 0 }
        let done = bites.filter { completedBiteIDs.contains($0.id) }.count
        return Double(done) / Double(bites.count)
    }

    func quizPassRate(for courseID: String) -> Double {
        let quizzes = quizzesByCourse[courseID] ?? []
        guard !quizzes.isEmpty else { return 1 } // no quizzes → treat as satisfied
        let passed = quizzes.filter { passedQuizIDs.contains($0.id) }.count
        return Double(passed) / Double(quizzes.count)
    }

    /// 0...1 composite used for letter grades.
    func courseScore(for courseID: String) -> Double {
        let bites = biteCompletion(for: courseID)
        let quizzes = quizPassRate(for: courseID)
        let hasQuizzes = !(quizzesByCourse[courseID] ?? []).isEmpty
        if hasQuizzes {
            return bites * AcademicRules.biteWeight + quizzes * AcademicRules.quizWeight
        }
        return bites
    }

    func letterGrade(for courseID: String) -> LetterGrade? {
        let bites = biteCompletion(for: courseID)
        guard bites > 0 || !(quizzesByCourse[courseID] ?? []).isEmpty else { return nil }
        // Only issue a grade once the learner has finished enough of the course
        // or exhausted the material.
        let finishedEnough = bites >= AcademicRules.minBiteCompletionToPass
            || bites >= 0.99
        guard finishedEnough else { return nil }
        return LetterGrade.fromScore(courseScore(for: courseID))
    }

    func isPassed(_ courseID: String) -> Bool {
        guard let grade = letterGrade(for: courseID) else { return false }
        guard grade.isPassing else { return false }
        let bitesOK = biteCompletion(for: courseID) >= AcademicRules.minBiteCompletionToPass
        let quizzesOK = quizPassRate(for: courseID) >= AcademicRules.minQuizPassRate
        return bitesOK && quizzesOK
    }

    func academicState(for courseID: String) -> CourseAcademicState {
        if !prereqsSatisfied(for: courseID) { return .locked }
        if isPassed(courseID) { return .passed }
        if let grade = letterGrade(for: courseID), !grade.isPassing { return .failed }

        let touchedBites = (bitesByCourse[courseID] ?? []).contains { completedBiteIDs.contains($0.id) }
        let touchedQuizzes = (quizzesByCourse[courseID] ?? []).contains { passedQuizIDs.contains($0.id) }
        if touchedBites || touchedQuizzes { return .inProgress }
        return .available
    }

    func transcript() -> [TranscriptEntry] {
        courses.compactMap { course in
            guard let grade = letterGrade(for: course.id) else { return nil }
            return TranscriptEntry(
                id: course.id,
                courseID: course.id,
                title: course.title,
                department: course.department,
                credits: credits(for: course.id),
                grade: grade,
                passed: isPassed(course.id)
            )
        }
        .sorted { $0.title < $1.title }
    }

    var cumulativeGPA: Double? {
        let passed = transcript().filter(\.passed)
        guard !passed.isEmpty else { return nil }
        let points = passed.reduce(0.0) { $0 + $1.grade.points * Double($1.credits) }
        let credits = passed.reduce(0) { $0 + $1.credits }
        guard credits > 0 else { return nil }
        return points / Double(credits)
    }

    var creditsEarned: Int {
        transcript().filter(\.passed).reduce(0) { $0 + $1.credits }
    }

    func title(for courseID: String) -> String {
        courses.first { $0.id == courseID }?.title ?? courseID
    }

    func progress(for program: DegreeProgram) -> ProgramProgress {
        let reqProgress = program.requirements.map { requirementProgress($0) }
        let earnedTowardProgram = creditsCounting(toward: program)
        var blockers: [String] = []

        for req in reqProgress where !req.satisfied {
            blockers.append("Complete: \(req.title)")
        }
        if earnedTowardProgram < program.minCredits {
            blockers.append("Earn \(program.minCredits) credits (have \(earnedTowardProgram))")
        }
        if let gpa = gpa(toward: program) {
            if gpa + 0.001 < program.minGPA {
                blockers.append(String(format: "Raise GPA to %.1f (now %.2f)", program.minGPA, gpa))
            }
        } else if program.minCredits > 0 {
            blockers.append("Pass courses to establish a GPA")
        }

        let conferred = self.conferred.contains { $0.programID == program.id }
        let canGraduate = blockers.isEmpty && !conferred

        return ProgramProgress(
            id: program.id,
            program: program,
            creditsEarned: earnedTowardProgram,
            creditsRequired: program.minCredits,
            gpa: gpa(toward: program),
            requirements: reqProgress,
            canGraduate: canGraduate,
            blockingReasons: blockers,
            conferred: conferred
        )
    }

    private func requirementProgress(_ req: DegreeRequirement) -> RequirementProgress {
        let statuses: [RequirementCourseStatus] = req.courseIds.map { id in
            RequirementCourseStatus(
                courseID: id,
                title: title(for: id),
                credits: req.creditsEach > 0 ? req.creditsEach : credits(for: id),
                state: academicState(for: id),
                grade: letterGrade(for: id)
            )
        }

        let satisfied: Bool
        let detail: String
        switch req.kind {
        case .required:
            let missing = statuses.filter { $0.state != .passed }
            satisfied = missing.isEmpty
            if satisfied {
                detail = "All required courses passed"
            } else {
                detail = "\(statuses.count - missing.count)/\(statuses.count) courses passed"
            }
        case .elective:
            let earned = statuses.filter { $0.state == .passed }.reduce(0) { $0 + $1.credits }
            satisfied = earned >= req.minCredits
            detail = "\(earned)/\(req.minCredits) elective credits"
        }

        return RequirementProgress(
            id: req.id,
            title: req.title,
            kind: req.kind,
            satisfied: satisfied,
            detail: detail,
            courseStatuses: statuses
        )
    }

    private func creditsCounting(toward program: DegreeProgram) -> Int {
        let relevant = Set(program.requirements.flatMap(\.courseIds))
        return transcript()
            .filter { $0.passed && relevant.contains($0.courseID) }
            .reduce(0) { $0 + $1.credits }
    }

    private func gpa(toward program: DegreeProgram) -> Double? {
        let relevant = Set(program.requirements.flatMap(\.courseIds))
        let rows = transcript().filter { $0.passed && relevant.contains($0.courseID) }
        guard !rows.isEmpty else { return nil }
        let points = rows.reduce(0.0) { $0 + $1.grade.points * Double($1.credits) }
        let credits = rows.reduce(0) { $0 + $1.credits }
        guard credits > 0 else { return nil }
        return points / Double(credits)
    }
}

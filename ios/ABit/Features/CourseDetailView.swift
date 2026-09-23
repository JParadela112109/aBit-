import SwiftUI

struct CourseDetailView: View {
    @Environment(AppStore.self) private var store
    let courseID: String

    private var course: CourseMeta? {
        store.courses.first { $0.id == courseID }
    }

    private var bites: [BiteCard] { store.bites(for: courseID) }
    private var progress: Double { store.progress(for: courseID) }
    private var accent: CourseAccent {
        .forDepartment(course?.department ?? "")
    }

    private var state: CourseAcademicState {
        store.engine.academicState(for: courseID)
    }

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: accent)
            if let course {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        header(course)
                        academicPanel(course)
                        about(course)

                        if state == .locked {
                            Text("Finish prerequisite courses before starting.")
                                .font(ABitTheme.body)
                                .foregroundStyle(ABitTheme.mist)
                        } else {
                            NavigationLink {
                                BiteSessionView(courseID: course.id)
                            } label: {
                                Text(ctaLabel)
                            }
                            .buttonStyle(PrimaryBitButton())
                            .padding(.top, 4)
                        }

                        Text("License \(course.license?.spdx ?? "CC-BY-NC-SA-3.0") · Course credit is internal to aBit — not an accredited credential")
                            .font(ABitTheme.micro)
                            .foregroundStyle(ABitTheme.mist.opacity(0.65))
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            } else {
                Text("Course missing — re-run the scraper bundle.")
                    .foregroundStyle(ABitTheme.mist)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let course {
                store.select(course)
            }
        }
    }

    private var ctaLabel: String {
        switch state {
        case .passed: return "Review bites"
        case .failed: return "Retry course"
        case .inProgress: return "Resume bites"
        default: return "Start first bite"
        }
    }

    private func header(_ course: CourseMeta) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(course.accentLabel.uppercased())
                .font(ABitTheme.caption)
                .tracking(1.5)
                .foregroundStyle(accent.chip)

            Text(course.title)
                .font(ABitTheme.display)
                .foregroundStyle(ABitTheme.chalk)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(course.professor)\n\(course.department) · \(course.number)")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)

            ProgressView(value: progress)
                .tint(ABitTheme.lime)
                .padding(.top, 4)

            Text("\(Int(progress * 100))% bites · \(bites.count) cards")
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
        }
        .padding(.top, 8)
    }

    private func academicPanel(_ course: CourseMeta) -> some View {
        let credits = store.credits(for: course.id)
        let grade = store.letterGrade(for: course.id)
        let quizRate = store.engine.quizPassRate(for: course.id)
        let prereqs = store.engine.prerequisites(for: course.id)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Academic standing")
                .font(ABitTheme.titleSm)
                .foregroundStyle(ABitTheme.chalk)

            HStack {
                standingChip("\(credits) credits")
                standingChip(stateLabel)
                if let grade {
                    standingChip("Grade \(grade.rawValue)")
                }
            }

            Text(passRuleCopy(quizRate: quizRate))
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
                .fixedSize(horizontal: false, vertical: true)

            if !prereqs.isEmpty {
                Text("Prerequisites: " + prereqs.map { store.engine.title(for: $0) }.joined(separator: ", "))
                    .font(ABitTheme.micro)
                    .foregroundStyle(ABitTheme.mist)
            }
        }
        .padding(16)
        .background(ABitTheme.inkElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var stateLabel: String {
        switch state {
        case .locked: return "Locked"
        case .available: return "Open"
        case .inProgress: return "In progress"
        case .passed: return "Passed"
        case .failed: return "Failed"
        }
    }

    private func standingChip(_ text: String) -> some View {
        Text(text)
            .font(ABitTheme.micro)
            .foregroundStyle(ABitTheme.chalk)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ABitTheme.inkSoft, in: Capsule())
    }

    private func passRuleCopy(quizRate: Double) -> String {
        let quizPct = Int(AcademicRules.minQuizPassRate * 100)
        let bitePct = Int(AcademicRules.minBiteCompletionToPass * 100)
        return "To pass: clear \(bitePct)%+ of bites and \(quizPct)%+ of lecture checks. Letter grade blends bite completion (\(Int(AcademicRules.biteWeight * 100))%) with quiz accuracy (\(Int(AcademicRules.quizWeight * 100))%). Your quiz rate: \(Int(quizRate * 100))%."
    }

    @ViewBuilder
    private func about(_ course: CourseMeta) -> some View {
        if !course.about.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(ABitTheme.titleSm)
                    .foregroundStyle(ABitTheme.chalk)
                Text(course.about)
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)
                    .lineSpacing(3)
            }
        }
    }
}

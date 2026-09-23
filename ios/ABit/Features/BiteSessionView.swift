import SwiftUI

struct BiteSessionView: View {
    @Environment(AppStore.self) private var store
    let courseID: String

    @State private var index = 0
    @State private var showQuiz = false
    @State private var activeQuiz: QuizItem?
    @State private var appeared = false
    @State private var celebrating = false
    @State private var didInit = false

    private var course: CourseMeta? { store.courses.first { $0.id == courseID } }
    private var bites: [BiteCard] { store.bites(for: courseID) }
    private var quizzes: [QuizItem] { store.quizzes(for: courseID) }
    private var accent: CourseAccent { .forDepartment(course?.department ?? "") }

    private var current: BiteCard? {
        guard !bites.isEmpty, bites.indices.contains(index) else { return nil }
        return bites[index]
    }

    private var lectureNumber: Int {
        guard let bite = current else { return 0 }
        if bite.lectureId == "about" { return 0 }
        if bite.lectureId == "final" { return -1 }
        let n = bite.lectureId.replacingOccurrences(of: "lecture-", with: "")
        return Int(n) ?? 0
    }

    private var lectureBitePosition: (Int, Int) {
        guard let bite = current else { return (0, 0) }
        let group = bites.filter { $0.lectureId == bite.lectureId }
        let pos = (group.firstIndex { $0.id == bite.id } ?? 0) + 1
        return (pos, group.count)
    }

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: accent)

            if bites.isEmpty {
                Text("No bites in this bundle.")
                    .foregroundStyle(ABitTheme.mist)
            } else if let bite = current {
                VStack(spacing: 16) {
                    sessionHeader
                    biteSurface(bite)
                        .id(bite.id)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                    Button("Got it") { handleGotIt(bite) }
                        .buttonStyle(PrimaryBitButton())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }

            if celebrating {
                celebrationOverlay
            }
        }
        .navigationTitle(course?.title ?? "Bites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didInit else { return }
            didInit = true
            index = store.resumeIndex(for: courseID)
        }
        .onChange(of: index) { _, newValue in
            store.saveResumeIndex(newValue, for: courseID)
        }
        .sheet(isPresented: $showQuiz) {
            if let quiz = activeQuiz {
                QuizView(
                    quiz: quiz,
                    accent: accent,
                    onAttempt: { correct in
                        store.recordQuizAttempt(quiz, correct: correct)
                    },
                    onPass: {
                        showQuiz = false
                        activeQuiz = nil
                        continueAfterQuiz()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: Double(index + 1), total: Double(max(bites.count, 1)))
                .tint(ABitTheme.lime)

            HStack {
                Text(moduleLabel)
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist)
                Spacer()
                Text("\(index + 1)/\(bites.count)")
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.lime)
            }
        }
    }

    private var moduleLabel: String {
        let (pos, total) = lectureBitePosition
        if lectureNumber == 0 { return "Course opening · \(pos)/\(total)" }
        if lectureNumber < 0 { return "Final" }
        return "Lecture \(lectureNumber) · bit \(pos)/\(total)"
    }

    private func biteSurface(_ bite: BiteCard) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(bite.kindLabel.uppercased())
                .font(ABitTheme.caption)
                .tracking(1.8)
                .foregroundStyle(ABitTheme.lime)

            Text(bite.headline)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(ABitTheme.chalk)
                .fixedSize(horizontal: false, vertical: true)

            Text(bite.body)
                .font(ABitTheme.bodyLg)
                .foregroundStyle(ABitTheme.mist)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text(bite.attributionLine)
                .font(ABitTheme.micro)
                .foregroundStyle(ABitTheme.mist.opacity(0.65))
                .lineLimit(3)
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(ABitTheme.inkElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [ABitTheme.lime.opacity(0.25), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: accent.glow.opacity(0.18), radius: 40, y: 18)
        )
        .scaleEffect(appeared ? 1 : 0.965)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private func handleGotIt(_ bite: BiteCard) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        store.markComplete(bite)

        let lecture = bite.lectureId
        let remainingInLecture = bites.contains {
            $0.lectureId == lecture
                && $0.id != bite.id
                && !store.completedBiteIDs.contains($0.id)
        }

        if !remainingInLecture,
           let quiz = quizzes.first(where: { $0.lectureId == lecture && $0.lectureId != "final" }),
           !store.passedQuizIDs.contains(quiz.id) {
            activeQuiz = quiz
            showQuiz = true
            return
        }

        if index >= bites.count - 1 {
            offerFinalOrCelebrate()
        } else {
            advance()
        }
    }

    private func continueAfterQuiz() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if index >= bites.count - 1 {
            offerFinalOrCelebrate()
        } else {
            advance()
        }
    }

    private func offerFinalOrCelebrate() {
        if let final = store.finalExam(for: courseID), !store.passedQuizIDs.contains(final.id) {
            activeQuiz = final
            showQuiz = true
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            celebrating = true
        }
    }

    private var celebrationOverlay: some View {
        let passed = store.isCoursePassed(courseID)
        let grade = store.letterGrade(for: courseID)
        return ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: passed ? "checkmark.seal.fill" : "books.vertical.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ABitTheme.lime)
                    .symbolEffect(.bounce, value: celebrating)
                Text(passed ? "Course passed" : "Session complete")
                    .font(ABitTheme.title)
                    .foregroundStyle(ABitTheme.chalk)
                if let grade {
                    Text("Grade \(grade.rawValue) · \(store.credits(for: courseID)) credits")
                        .font(ABitTheme.body)
                        .foregroundStyle(ABitTheme.mist)
                } else {
                    Text("Pass the final and clear enough checks to lock a grade.")
                        .font(ABitTheme.body)
                        .foregroundStyle(ABitTheme.mist)
                        .multilineTextAlignment(.center)
                }
                Text(passed
                     ? "Credits are on your transcript. Open College to check program requirements."
                     : "Need 80%+ bites, 70%+ lecture checks, and the final.")
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist.opacity(0.85))
                    .multilineTextAlignment(.center)
                Button("Done") { celebrating = false }
                    .buttonStyle(PrimaryBitButton())
                    .frame(width: 160)
            }
            .padding(28)
            .background(ABitTheme.inkElevated, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(32)
        }
    }

    private func advance() {
        guard index < bites.count - 1 else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            index += 1
        }
    }
}

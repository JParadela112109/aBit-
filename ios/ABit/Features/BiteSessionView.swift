import SwiftUI

struct BiteSessionView: View {
    @Environment(AppStore.self) private var store
    let courseID: String

    @State private var index = 0
    @State private var showQuiz = false
    @State private var quizForLecture: String?
    @State private var appeared = false
    @State private var celebrating = false

    private var course: CourseMeta? { store.courses.first { $0.id == courseID } }
    private var bites: [BiteCard] { store.bites(for: courseID) }
    private var quizzes: [QuizItem] { store.quizzes(for: courseID) }
    private var accent: CourseAccent { .forDepartment(course?.department ?? "") }

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: accent)

            if bites.isEmpty {
                Text("No bites in this bundle.")
                    .foregroundStyle(ABitTheme.mist)
            } else {
                VStack(spacing: 18) {
                    progressBar
                    biteSurface(bites[index])
                        .id(bites[index].id)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                    controls
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            if celebrating {
                celebrationOverlay
            }
        }
        .navigationTitle(course?.title ?? "Bites")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQuiz) {
            if let lecture = quizForLecture,
               let quiz = quizzes.first(where: { $0.lectureId == lecture }) {
                QuizView(
                    quiz: quiz,
                    accent: accent,
                    onAttempt: { correct in
                        store.recordQuizAttempt(quiz, correct: correct)
                    },
                    onPass: {
                        showQuiz = false
                        if index >= bites.count - 1 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                celebrating = true
                            }
                        } else {
                            advance()
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 5) {
            ForEach(Array(bites.enumerated()), id: \.offset) { i, bite in
                Capsule()
                    .fill(
                        i < index || store.completedBiteIDs.contains(bite.id)
                            ? ABitTheme.lime
                            : (i == index ? ABitTheme.lime.opacity(0.55) : ABitTheme.mist.opacity(0.2))
                    )
                    .frame(height: 3)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: index)
            }
        }
        .padding(.top, 4)
    }

    private func biteSurface(_ bite: BiteCard) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(bite.kindLabel.uppercased())
                .font(ABitTheme.caption)
                .tracking(1.8)
                .foregroundStyle(ABitTheme.lime)

            Text(bite.headline)
                .font(.system(size: 36, weight: .semibold, design: .serif))
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

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Got it") {
                let bite = bites[index]
                store.markComplete(bite)
                let lecture = bite.lectureId
                let remainingInLecture = bites.contains {
                    $0.lectureId == lecture
                        && $0.id != bite.id
                        && !store.completedBiteIDs.contains($0.id)
                }
                let quiz = quizzes.first { $0.lectureId == lecture }
                if !remainingInLecture, let quiz, !store.passedQuizIDs.contains(quiz.id) {
                    quizForLecture = lecture
                    showQuiz = true
                } else if index >= bites.count - 1 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        celebrating = true
                    }
                } else {
                    advance()
                }
            }
            .buttonStyle(PrimaryBitButton())

            if index < bites.count - 1 {
                Button("Skip") { advance() }
                    .buttonStyle(GhostBitButton())
            }
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
                Text(passed ? "Course passed" : "Bites complete")
                    .font(ABitTheme.title)
                    .foregroundStyle(ABitTheme.chalk)
                if let grade {
                    Text("Grade \(grade.rawValue) · \(store.credits(for: courseID)) credits")
                        .font(ABitTheme.body)
                        .foregroundStyle(ABitTheme.mist)
                } else {
                    Text("Keep improving quiz checks to lock a passing grade.")
                        .font(ABitTheme.body)
                        .foregroundStyle(ABitTheme.mist)
                        .multilineTextAlignment(.center)
                }
                Text(passed
                     ? "Credits post to your transcript. Graduate from College when your program clears."
                     : "Pass rules: 80%+ bites and 70%+ lecture checks.")
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist.opacity(0.85))
                    .multilineTextAlignment(.center)
                Button("Nice") { celebrating = false }
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

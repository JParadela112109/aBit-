import SwiftUI

struct QuizView: View {
    let quiz: QuizItem
    var accent: CourseAccent = .forest
    var onAttempt: (Bool) -> Void
    var onPass: () -> Void

    @State private var selected: Int?
    @State private var submitted = false
    @State private var shakeWrong = false
    @State private var reported = false

    private var isCorrect: Bool { selected == quiz.answerIndex }
    private var isFinal: Bool { quiz.lectureId == "final" }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground(accent: accent)
                VStack(alignment: .leading, spacing: 18) {
                    Text(isFinal ? "COURSE FINAL" : "LECTURE CHECK")
                        .font(ABitTheme.caption)
                        .tracking(1.6)
                        .foregroundStyle(ABitTheme.lime)

                    Text(quiz.prompt)
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundStyle(ABitTheme.chalk)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array(quiz.choices.enumerated()), id: \.offset) { i, choice in
                        Button {
                            selected = i
                        } label: {
                            HStack(alignment: .top) {
                                Text(choice)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(ABitTheme.chalk)
                                    .font(ABitTheme.body)
                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(choiceFill(i))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(submitted && isCorrect)
                    }
                    .offset(x: shakeWrong ? -8 : 0)

                    if submitted {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isCorrect ? "Correct." : "Not yet.")
                                .font(ABitTheme.body)
                                .foregroundStyle(isCorrect ? ABitTheme.lime : ABitTheme.mist)
                            if isCorrect, !quiz.explanation.isEmpty {
                                Text(quiz.explanation)
                                    .font(ABitTheme.caption)
                                    .foregroundStyle(ABitTheme.mist)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 0)

                    Button(submitted && isCorrect ? "Continue" : "Check") {
                        handlePrimary()
                    }
                    .buttonStyle(PrimaryBitButton())
                    .disabled(selected == nil)
                }
                .padding(22)
            }
            .navigationTitle(isFinal ? "Final" : "Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func handlePrimary() {
        if submitted && isCorrect {
            onPass()
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            submitted = true
        }
        if !reported {
            onAttempt(isCorrect)
            reported = true
        }
        if isCorrect {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            reported = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring(response: 0.12, dampingFraction: 0.2)) {
                shakeWrong = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                shakeWrong = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    submitted = false
                    selected = nil
                }
            }
        }
    }

    private func choiceFill(_ i: Int) -> Color {
        if !submitted {
            return selected == i ? ABitTheme.lime.opacity(0.22) : ABitTheme.inkElevated
        }
        if i == quiz.answerIndex { return ABitTheme.lime.opacity(0.3) }
        if i == selected { return Color(red: 0.75, green: 0.28, blue: 0.28).opacity(0.35) }
        return ABitTheme.inkElevated
    }
}

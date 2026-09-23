import SwiftUI

struct QuizView: View {
    let quiz: QuizItem
    var accent: CourseAccent = .forest
    /// Called when the learner submits a check — `true` if correct.
    var onAttempt: (Bool) -> Void
    var onPass: () -> Void

    @State private var selected: Int?
    @State private var submitted = false
    @State private var shakeWrong = false
    @State private var reported = false

    private var isCorrect: Bool { selected == quiz.answerIndex }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground(accent: accent)
                VStack(alignment: .leading, spacing: 18) {
                    Text("PROVE THIS BIT")
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
                        .disabled(submitted)
                    }
                    .offset(x: shakeWrong ? -8 : 0)

                    if submitted {
                        Text(isCorrect ? "Cleared. Onward." : "Not yet — try again.")
                            .font(ABitTheme.body)
                            .foregroundStyle(isCorrect ? ABitTheme.lime : ABitTheme.mist)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 0)

                    Button(submitted && isCorrect ? "Continue" : "Check") {
                        if submitted && isCorrect {
                            onPass()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                submitted = true
                            }
                            if !reported {
                                onAttempt(isCorrect)
                                reported = true
                            }
                            if isCorrect == false {
                                reported = false
                                withAnimation(.spring(response: 0.12, dampingFraction: 0.2)) {
                                    shakeWrong = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    shakeWrong = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                                    withAnimation {
                                        submitted = false
                                        selected = nil
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(PrimaryBitButton())
                    .disabled(selected == nil)
                }
                .padding(22)
            }
            .navigationTitle("Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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

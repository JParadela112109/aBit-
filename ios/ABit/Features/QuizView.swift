import SwiftUI

struct QuizView: View {
    let quiz: QuizItem
    var onPass: () -> Void

    @State private var selected: Int?
    @State private var submitted = false

    private var isCorrect: Bool { selected == quiz.answerIndex }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Prove this bit")
                    .font(ABitTheme.caption)
                    .tracking(1.4)
                    .foregroundStyle(ABitTheme.lime)

                Text(quiz.prompt)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(ABitTheme.chalk)

                ForEach(Array(quiz.choices.enumerated()), id: \.offset) { i, choice in
                    Button {
                        selected = i
                    } label: {
                        HStack(alignment: .top) {
                            Text(choice)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(ABitTheme.chalk)
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(choiceFill(i))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(submitted)
                }

                if submitted {
                    Text(isCorrect ? "Cleared. Onward." : "Not quite — reread the bite and try again.")
                        .font(ABitTheme.body)
                        .foregroundStyle(isCorrect ? ABitTheme.lime : ABitTheme.mist)
                }

                Spacer()

                Button(submitted && isCorrect ? "Continue" : "Check") {
                    if submitted && isCorrect {
                        onPass()
                    } else {
                        submitted = true
                        if !isCorrect {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                submitted = false
                                selected = nil
                            }
                        }
                    }
                }
                .buttonStyle(PrimaryBitButton())
                .disabled(selected == nil)
            }
            .padding(22)
            .background(ABitTheme.ink.ignoresSafeArea())
            .navigationTitle("Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func choiceFill(_ i: Int) -> Color {
        if !submitted {
            return selected == i ? ABitTheme.lime.opacity(0.22) : ABitTheme.inkElevated
        }
        if i == quiz.answerIndex { return ABitTheme.lime.opacity(0.28) }
        if i == selected { return Color.red.opacity(0.25) }
        return ABitTheme.inkElevated
    }
}

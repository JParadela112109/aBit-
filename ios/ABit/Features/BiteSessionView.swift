import SwiftUI

struct BiteSessionView: View {
    @Environment(AppStore.self) private var store
    let course: CourseSummary

    @State private var index = 0
    @State private var showQuiz = false
    @State private var appeared = false

    private var bites: [BiteCard] { store.bites }

    var body: some View {
        ZStack {
            AtmosphereBackground()
            if bites.isEmpty {
                Text("No bites yet — run the scraper.")
                    .foregroundStyle(ABitTheme.mist)
            } else {
                VStack(spacing: 20) {
                    progress
                    biteCard(bites[index])
                        .id(bites[index].id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    controls
                }
                .padding(22)
            }
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQuiz) {
            if let quiz = store.quizzes.first(where: { $0.lectureId == bites[index].lectureId })
                ?? store.quizzes.first {
                QuizView(quiz: quiz) {
                    showQuiz = false
                    advance()
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(Array(bites.enumerated()), id: \.offset) { i, bite in
                Capsule()
                    .fill(i <= index || store.completedBiteIDs.contains(bite.id) ? ABitTheme.lime : ABitTheme.mist.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }

    private func biteCard(_ bite: BiteCard) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(bite.kind.uppercased())
                .font(ABitTheme.caption)
                .tracking(1.6)
                .foregroundStyle(ABitTheme.lime)

            Text(bite.headline)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(ABitTheme.chalk)
                .fixedSize(horizontal: false, vertical: true)

            Text(bite.body)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(ABitTheme.mist)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text(bite.attributionLine)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(ABitTheme.mist.opacity(0.7))
                .lineLimit(3)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(ABitTheme.inkElevated)
        )
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Got it") {
                store.markComplete(bites[index])
                let lectureDone = !bites.contains { $0.lectureId == bites[index].lectureId && !store.completedBiteIDs.contains($0.id) && $0.id != bites[index].id }
                if lectureDone && store.quizzes.contains(where: { $0.lectureId == bites[index].lectureId }) {
                    showQuiz = true
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

    private func advance() {
        guard index < bites.count - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            index += 1
        }
    }
}

struct PrimaryBitButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ABitTheme.lime, in: Capsule())
            .foregroundStyle(ABitTheme.ink)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostBitButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(ABitTheme.mist.opacity(0.12), in: Capsule())
            .foregroundStyle(ABitTheme.chalk)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

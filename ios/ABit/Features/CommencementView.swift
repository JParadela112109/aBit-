import SwiftUI

struct CommencementView: View {
    let degree: ConferredDegree
    var onDismiss: () -> Void

    @State private var appear = false
    @State private var sharePayload: String = ""

    var body: some View {
        ZStack {
            ABitTheme.ink.ignoresSafeArea()
            RadialGradient(
                colors: [ABitTheme.lime.opacity(0.35), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .scaleEffect(appear ? 1.05 : 0.85)
            .opacity(appear ? 1 : 0.4)

            VStack(spacing: 22) {
                Spacer()

                Text("aBit COLLEGE")
                    .font(ABitTheme.caption)
                    .tracking(2)
                    .foregroundStyle(ABitTheme.lime)
                    .opacity(appear ? 1 : 0)

                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(ABitTheme.lime)
                    .symbolEffect(.bounce, value: appear)
                    .scaleEffect(appear ? 1 : 0.6)

                Text("Commencement")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(ABitTheme.mist)

                Text(degree.credential)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(ABitTheme.chalk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(String(format: "GPA %.2f  ·  %d credits", degree.gpa, degree.credits))
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)

                Text(degree.conferredAt.formatted(date: .long, time: .omitted))
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist.opacity(0.75))

                Text("Not an accredited university degree.\nA playful seal for work you actually did.")
                    .font(ABitTheme.micro)
                    .foregroundStyle(ABitTheme.mist.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()

                ShareLink(item: sharePayload) {
                    Label("Share seal", systemImage: "square.and.arrow.up")
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ABitTheme.lime, in: Capsule())
                        .foregroundStyle(ABitTheme.ink)
                }
                .padding(.horizontal, 28)

                Button("Done") { onDismiss() }
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            sharePayload =
                "I commenced \(degree.credential) at aBit College — \(degree.credits) credits, GPA \(String(format: "%.2f", degree.gpa)). Not an accredited degree — just bites, checks, and consistency."
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                appear = true
            }
        }
    }
}

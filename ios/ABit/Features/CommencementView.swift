import SwiftUI

struct CommencementView: View {
    let degree: ConferredDegree
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false
    @State private var glowPulse = false
    @State private var sharePayload: String = ""

    var body: some View {
        ZStack {
            ABitTheme.ink.ignoresSafeArea()
            RadialGradient(
                colors: [ABitTheme.lime.opacity(glowPulse ? 0.42 : 0.28), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .scaleEffect(appear ? (glowPulse && !reduceMotion ? 1.08 : 1.02) : 0.82)
            .opacity(appear ? 1 : 0.35)
            .blur(radius: reduceMotion ? 0 : (glowPulse ? 2 : 8))

            VStack(spacing: 22) {
                Spacer()

                Text("aBit COLLEGE")
                    .font(ABitTheme.caption)
                    .tracking(2)
                    .foregroundStyle(ABitTheme.lime)
                    .opacity(appear ? 1 : 0)

                ZStack {
                    Circle()
                        .fill(ABitTheme.lime.opacity(0.18))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? (glowPulse && !reduceMotion ? 1.12 : 1) : 0.5)
                        .opacity(appear ? 1 : 0)

                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(ABitTheme.lime)
                        .symbolEffect(.bounce, value: appear && !reduceMotion)
                        .scaleEffect(appear ? 1 : 0.55)
                        .shadow(color: ABitTheme.lime.opacity(appear ? 0.55 : 0), radius: glowPulse ? 24 : 10)
                }

                Text("Commencement")
                    .font(Font.custom("Nunito-SemiBold", size: 18, relativeTo: .body))
                    .foregroundStyle(ABitTheme.mist)

                Text(degree.credential)
                    .font(Font.custom("Fraunces-Bold", size: 34, relativeTo: .title))
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
                        .font(Font.custom("Nunito-Bold", size: 17, relativeTo: .body))
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
            if reduceMotion {
                appear = true
                glowPulse = true
            } else {
                withAnimation(.spring(response: 0.72, dampingFraction: 0.74)) {
                    appear = true
                }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.35)) {
                    glowPulse = true
                }
            }
        }
    }
}

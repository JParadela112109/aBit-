import SwiftUI

enum ABitTheme {
    static let ink = Color(red: 0.04, green: 0.055, blue: 0.05)
    static let inkElevated = Color(red: 0.085, green: 0.11, blue: 0.10)
    static let inkSoft = Color(red: 0.12, green: 0.15, blue: 0.14)
    static let chalk = Color(red: 0.94, green: 0.96, blue: 0.945)
    static let mist = Color(red: 0.68, green: 0.76, blue: 0.72)
    static let lime = Color(red: 0.74, green: 0.90, blue: 0.32)
    static let limeDeep = Color(red: 0.55, green: 0.72, blue: 0.18)

    // Fraunces (display) + Nunito (rounded body) — PostScript names from bundled OFL TTFs
    static let displayHuge = Font.custom("Fraunces-Bold", size: 64, relativeTo: .largeTitle)
    static let display = Font.custom("Fraunces-Bold", size: 40, relativeTo: .largeTitle)
    static let title = Font.custom("Fraunces-SemiBold", size: 26, relativeTo: .title2)
    static let titleSm = Font.custom("Fraunces-SemiBold", size: 20, relativeTo: .title3)
    static let body = Font.custom("Nunito-Regular", size: 17, relativeTo: .body)
    static let bodyLg = Font.custom("Nunito-Regular", size: 19, relativeTo: .title3)
    static let caption = Font.custom("Nunito-SemiBold", size: 12, relativeTo: .caption)
    static let micro = Font.custom("Nunito-SemiBold", size: 11, relativeTo: .caption2)

    static let biteHeadline = Font.custom("Fraunces-SemiBold", size: 34, relativeTo: .title)
    static let brandMark = Font.custom("Fraunces-Bold", size: 62, relativeTo: .largeTitle)
}

struct AtmosphereBackground: View {
    var accent: CourseAccent = .forest
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    var body: some View {
        ZStack {
            ABitTheme.ink.ignoresSafeArea()

            RadialGradient(
                colors: [accent.glow.opacity(0.35), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .scaleEffect(reduceMotion ? 1 : (phase ? 1.08 : 0.94))
            .opacity(reduceMotion ? 0.9 : (phase ? 1 : 0.75))

            RadialGradient(
                colors: [ABitTheme.lime.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 360
            )
            .ignoresSafeArea()
            .scaleEffect(reduceMotion ? 1 : (phase ? 0.92 : 1.06))

            LinearGradient(
                colors: [.clear, ABitTheme.ink.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }
}

struct BrandMark: View {
    var size: CGFloat = 56

    var body: some View {
        HStack(spacing: 0) {
            Text("a")
            Text("B").foregroundStyle(ABitTheme.lime)
            Text("it")
        }
        .font(Font.custom("Fraunces-Bold", size: size, relativeTo: .largeTitle))
        .foregroundStyle(ABitTheme.chalk)
        .accessibilityLabel("aBit")
    }
}

struct PrimaryBitButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("Nunito-Bold", size: 17, relativeTo: .body))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(ABitTheme.lime, in: Capsule())
            .foregroundStyle(ABitTheme.ink)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GhostBitButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("Nunito-SemiBold", size: 17, relativeTo: .body))
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .background(ABitTheme.mist.opacity(0.12), in: Capsule())
            .foregroundStyle(ABitTheme.chalk)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

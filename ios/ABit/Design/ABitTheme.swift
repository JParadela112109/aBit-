import SwiftUI

enum ABitTheme {
    static let ink = Color(red: 0.04, green: 0.055, blue: 0.05)
    static let inkElevated = Color(red: 0.085, green: 0.11, blue: 0.10)
    static let inkSoft = Color(red: 0.12, green: 0.15, blue: 0.14)
    static let chalk = Color(red: 0.94, green: 0.96, blue: 0.945)
    static let mist = Color(red: 0.68, green: 0.76, blue: 0.72)
    static let lime = Color(red: 0.74, green: 0.90, blue: 0.32)
    static let limeDeep = Color(red: 0.55, green: 0.72, blue: 0.18)

    static let displayHuge = Font.system(size: 64, weight: .bold, design: .serif)
    static let display = Font.system(size: 40, weight: .bold, design: .serif)
    static let title = Font.system(size: 26, weight: .semibold, design: .serif)
    static let titleSm = Font.system(size: 20, weight: .semibold, design: .serif)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyLg = Font.system(size: 19, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let micro = Font.system(size: 11, weight: .medium, design: .rounded)
}

struct AtmosphereBackground: View {
    var accent: CourseAccent = .forest
    @State private var phase = false

    var body: some View {
        ZStack {
            ABitTheme.ink.ignoresSafeArea()

            // Soft paper grain substitute — layered radial washes
            RadialGradient(
                colors: [accent.glow.opacity(0.35), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .scaleEffect(phase ? 1.08 : 0.94)
            .opacity(phase ? 1 : 0.75)

            RadialGradient(
                colors: [ABitTheme.lime.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 360
            )
            .ignoresSafeArea()
            .scaleEffect(phase ? 0.92 : 1.06)

            LinearGradient(
                colors: [.clear, ABitTheme.ink.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onAppear {
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
        .font(.system(size: size, weight: .bold, design: .serif))
        .foregroundStyle(ABitTheme.chalk)
        .accessibilityLabel("aBit")
    }
}

struct PrimaryBitButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.bold))
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
            .font(.system(.body, design: .rounded).weight(.semibold))
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

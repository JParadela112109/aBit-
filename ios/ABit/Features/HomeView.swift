import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            AtmosphereBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    brand
                    if let course = store.courses.first {
                        courseCard(course)
                    }
                    today
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text("a")
                Text("B").foregroundStyle(ABitTheme.lime)
                Text("it")
            }
            .font(.system(size: 58, weight: .bold, design: .serif))
            .foregroundStyle(ABitTheme.chalk)
            .accessibilityLabel("aBit")

            Text("College, in bites.")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(ABitTheme.chalk)

            Text("Open courses remixed into tiny lessons. Learn, pass the check, claim the degree.")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    private func courseCard(_ course: CourseSummary) -> some View {
        NavigationLink {
            BiteSessionView(course: course)
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                Text(course.accentLabel.uppercased())
                    .font(ABitTheme.caption)
                    .tracking(1.4)
                    .foregroundStyle(ABitTheme.lime)

                Text(course.title)
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(ABitTheme.chalk)

                Text("\(course.professor) · \(course.department)")
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)

                HStack {
                    Label("\(course.biteCount) bites", systemImage: "square.stack.3d.up.fill")
                    Spacer()
                    Text("Start")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(ABitTheme.lime, in: Capsule())
                        .foregroundStyle(ABitTheme.ink)
                }
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ABitTheme.inkElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(ABitTheme.mist.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var today: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(ABitTheme.title)
                .foregroundStyle(ABitTheme.chalk)

            ProgressView(value: store.progress)
                .tint(ABitTheme.lime)

            Text("\(store.completedBiteIDs.count) of \(max(store.bites.count, 1)) bites cleared")
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
        }
    }
}

struct AtmosphereBackground: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            ABitTheme.ink.ignoresSafeArea()
            Circle()
                .fill(ABitTheme.glow)
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -120, y: -220)
                .scaleEffect(pulse ? 1.05 : 0.95)
            Circle()
                .fill(ABitTheme.lime.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: 140, y: 180)
                .scaleEffect(pulse ? 0.96 : 1.04)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

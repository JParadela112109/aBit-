import SwiftUI

struct DegreeView: View {
    @Environment(AppStore.self) private var store
    @State private var appear = false

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: .honey)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        BrandMark(size: 36)
                        Text("Degrees")
                            .font(ABitTheme.display)
                            .foregroundStyle(ABitTheme.chalk)
                        Text("Playful seals for paths you clear — never an accredited credential.")
                            .font(ABitTheme.body)
                            .foregroundStyle(ABitTheme.mist)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .padding(.top, 28)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)

                    if store.earnedDegrees.isEmpty {
                        emptySeal
                    } else {
                        ForEach(store.earnedDegrees) { course in
                            sealCard(course)
                        }
                    }

                    inProgress
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) { appear = true }
        }
    }

    private var emptySeal: some View {
        VStack(spacing: 14) {
            Image(systemName: "seal")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(ABitTheme.mist.opacity(0.5))
            Text("No degrees yet")
                .font(ABitTheme.titleSm)
                .foregroundStyle(ABitTheme.chalk)
            Text("Finish every bite in a path to claim one.")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(ABitTheme.mist.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
        )
    }

    private func sealCard(_ course: CourseMeta) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 40))
                .foregroundStyle(ABitTheme.lime)
                .symbolEffect(.pulse, options: .repeating.speed(0.4), isActive: appear)

            Text("Bachelor of Bits")
                .font(ABitTheme.title)
                .foregroundStyle(ABitTheme.chalk)

            Text(course.title)
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)

            Text(course.professor)
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist.opacity(0.8))

            Text("Not an accredited university degree.")
                .font(ABitTheme.micro)
                .foregroundStyle(ABitTheme.mist.opacity(0.55))
                .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(ABitTheme.inkElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(ABitTheme.lime.opacity(0.55), lineWidth: 1.5)
                )
        )
    }

    private var inProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In progress")
                .font(ABitTheme.titleSm)
                .foregroundStyle(ABitTheme.chalk)

            ForEach(store.courses.filter { store.progress(for: $0.id) < 1 }) { course in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(ABitTheme.chalk)
                        Text("\(Int(store.progress(for: course.id) * 100))%")
                            .font(ABitTheme.caption)
                            .foregroundStyle(ABitTheme.mist)
                    }
                    Spacer()
                    ProgressView(value: store.progress(for: course.id))
                        .tint(ABitTheme.lime)
                        .frame(width: 80)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.top, 12)
    }
}

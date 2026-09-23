import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var heroVisible = false

    private var continueCourse: CourseMeta? {
        store.courses.first { store.progress(for: $0.id) > 0 && store.progress(for: $0.id) < 1 }
            ?? store.courses.first
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AtmosphereBackground(accent: .forest)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        hero
                            .frame(minHeight: max(geo.size.height * 0.72, 520))
                            .padding(.horizontal, 24)

                        pathsSection
                            .padding(.top, 8)
                            .padding(.bottom, 56)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.84).delay(0.05)) {
                heroVisible = true
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 48)

            BrandMark(size: 62)
                .opacity(heroVisible ? 1 : 0)
                .offset(y: heroVisible ? 0 : 16)

            Text("College, in bites.")
                .font(ABitTheme.title)
                .foregroundStyle(ABitTheme.chalk)
                .opacity(heroVisible ? 1 : 0)
                .offset(y: heroVisible ? 0 : 12)

            Text("Open lectures, remixed into tiny lessons you can finish between classes.")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320, alignment: .leading)
                .opacity(heroVisible ? 1 : 0)
                .offset(y: heroVisible ? 0 : 10)

            if let course = continueCourse {
                NavigationLink {
                    CourseDetailView(courseID: course.id)
                } label: {
                    HStack(spacing: 10) {
                        Text(store.progress(for: course.id) > 0 ? "Continue \(course.title)" : "Begin with \(course.title)")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(ABitTheme.ink)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(ABitTheme.lime, in: Capsule())
                }
                .buttonStyle(PressableCardStyle())
                .padding(.top, 10)
                .opacity(heroVisible ? 1 : 0)
                .offset(y: heroVisible ? 0 : 8)
            }

            Spacer(minLength: 24)

            Image(systemName: "chevron.compact.down")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(ABitTheme.mist.opacity(0.55))
                .frame(maxWidth: .infinity)
                .opacity(heroVisible ? 1 : 0)
                .padding(.bottom, 12)
        }
    }

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Paths")
                    .font(ABitTheme.title)
                    .foregroundStyle(ABitTheme.chalk)
                Spacer()
                Text("\(store.courses.count) open")
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist)
            }
            .padding(.horizontal, 24)

            Text("Drop a scraped `.course.json` into Resources/Courses — it shows up here.")
                .font(ABitTheme.micro)
                .foregroundStyle(ABitTheme.mist.opacity(0.75))
                .padding(.horizontal, 24)

            LazyVStack(spacing: 14) {
                ForEach(Array(store.courses.enumerated()), id: \.element.id) { index, course in
                    NavigationLink {
                        CourseDetailView(courseID: course.id)
                    } label: {
                        CoursePathRow(
                            course: course,
                            progress: store.progress(for: course.id),
                            biteCount: store.bites(for: course.id).count
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                    .padding(.horizontal, 24)
                    .opacity(heroVisible ? 1 : 0)
                    .offset(y: heroVisible ? 0 : 20)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.84).delay(0.12 + Double(index) * 0.06),
                        value: heroVisible
                    )
                }
            }
        }
    }
}

struct CoursePathRow: View {
    let course: CourseMeta
    let progress: Double
    let biteCount: Int

    private var accent: CourseAccent { .forDepartment(course.department) }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.glow.opacity(0.85), accent.glow.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 84)
                .overlay {
                    Text(String(course.title.prefix(1)))
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(ABitTheme.chalk)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(course.accentLabel.uppercased())
                    .font(ABitTheme.micro)
                    .tracking(1.2)
                    .foregroundStyle(accent.chip)

                Text(course.title)
                    .font(ABitTheme.titleSm)
                    .foregroundStyle(ABitTheme.chalk)
                    .multilineTextAlignment(.leading)

                Text("\(course.professor) · \(course.department)")
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist)

                HStack(spacing: 10) {
                    Text("\(biteCount) bites")
                    if progress > 0 {
                        Text("·")
                        Text("\(Int(progress * 100))%")
                            .foregroundStyle(ABitTheme.lime)
                    }
                }
                .font(ABitTheme.micro)
                .foregroundStyle(ABitTheme.mist.opacity(0.85))
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ABitTheme.mist.opacity(0.5))
                .padding(.top, 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ABitTheme.inkElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(ABitTheme.mist.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

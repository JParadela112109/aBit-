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
                            .frame(minHeight: max(geo.size.height * 0.68, 500))
                            .padding(.horizontal, 24)

                        streakBand
                            .padding(.horizontal, 24)
                            .padding(.bottom, 28)

                        pathsSection
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

            Text("Real open lectures. Tiny lessons. Pass the course, earn the credits, graduate your program.")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 340, alignment: .leading)
                .opacity(heroVisible ? 1 : 0)

            if let course = continueCourse {
                NavigationLink {
                    CourseDetailView(courseID: course.id)
                } label: {
                    HStack(spacing: 10) {
                        Text(store.progress(for: course.id) > 0 ? "Continue \(course.title)" : "Begin \(course.title)")
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
                .padding(.top, 8)
                .opacity(heroVisible ? 1 : 0)
            }

            Spacer(minLength: 20)

            Image(systemName: "chevron.compact.down")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(ABitTheme.mist.opacity(0.55))
                .frame(maxWidth: .infinity)
                .opacity(heroVisible ? 1 : 0)
                .padding(.bottom, 8)
        }
    }

    private var streakBand: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STREAK")
                    .font(ABitTheme.micro)
                    .tracking(1.2)
                    .foregroundStyle(ABitTheme.mist)
                Text("\(store.currentStreak) day\(store.currentStreak == 1 ? "" : "s")")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ABitTheme.lime)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY · \(store.bitsCompletedToday)/\(store.dailyGoal) bits")
                    .font(ABitTheme.micro)
                    .tracking(1.0)
                    .foregroundStyle(ABitTheme.mist)
                ProgressView(value: store.dailyGoalProgress)
                    .tint(ABitTheme.lime)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(ABitTheme.inkElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .opacity(heroVisible ? 1 : 0)
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

            LazyVStack(spacing: 14) {
                ForEach(Array(store.courses.enumerated()), id: \.element.id) { index, course in
                    NavigationLink {
                        CourseDetailView(courseID: course.id)
                    } label: {
                        CoursePathRow(
                            course: course,
                            progress: store.progress(for: course.id),
                            biteCount: store.bites(for: course.id).count,
                            grade: store.letterGrade(for: course.id),
                            passed: store.isCoursePassed(course.id)
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
    var grade: LetterGrade? = nil
    var passed: Bool = false

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
                    if passed {
                        Text("· Passed")
                            .foregroundStyle(ABitTheme.lime)
                    } else if let grade {
                        Text("· \(grade.rawValue)")
                            .foregroundStyle(ABitTheme.lime)
                    } else if progress > 0 {
                        Text("· \(Int(progress * 100))%")
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

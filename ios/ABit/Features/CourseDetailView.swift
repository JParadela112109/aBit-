import SwiftUI

struct CourseDetailView: View {
    @Environment(AppStore.self) private var store
    let courseID: String

    private var course: CourseMeta? {
        store.courses.first { $0.id == courseID }
    }

    private var bites: [BiteCard] { store.bites(for: courseID) }
    private var progress: Double { store.progress(for: courseID) }
    private var accent: CourseAccent {
        .forDepartment(course?.department ?? "")
    }

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: accent)
            if let course {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        header(course)
                        about(course)
                        NavigationLink {
                            BiteSessionView(courseID: course.id)
                        } label: {
                            Text(progress > 0 ? "Resume bites" : "Start first bite")
                        }
                        .buttonStyle(PrimaryBitButton())
                        .padding(.top, 4)

                        Text("License \(course.license?.spdx ?? "CC-BY-NC-SA-3.0") · Not a university credential")
                            .font(ABitTheme.micro)
                            .foregroundStyle(ABitTheme.mist.opacity(0.65))
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            } else {
                Text("Course missing — re-run the scraper bundle.")
                    .foregroundStyle(ABitTheme.mist)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let course {
                store.select(course)
            }
        }
    }

    private func header(_ course: CourseMeta) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(course.accentLabel.uppercased())
                .font(ABitTheme.caption)
                .tracking(1.5)
                .foregroundStyle(accent.chip)

            Text(course.title)
                .font(ABitTheme.display)
                .foregroundStyle(ABitTheme.chalk)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(course.professor)\n\(course.department) · \(course.number)")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)

            ProgressView(value: progress)
                .tint(ABitTheme.lime)
                .padding(.top, 4)

            Text("\(Int(progress * 100))% · \(bites.count) bites")
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func about(_ course: CourseMeta) -> some View {
        if !course.about.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(ABitTheme.titleSm)
                    .foregroundStyle(ABitTheme.chalk)
                Text(course.about)
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)
                    .lineSpacing(3)
            }
        }
    }
}

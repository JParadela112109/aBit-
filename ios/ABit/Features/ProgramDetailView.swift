import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppStore.self) private var store
    let program: DegreeProgram
    @State private var commenceFlash = false

    private var progress: ProgramProgress {
        store.programProgress(program)
    }

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: .honey)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(program.school.uppercased())
                            .font(ABitTheme.caption)
                            .tracking(1.4)
                            .foregroundStyle(ABitTheme.lime)
                        Text(program.fullName)
                            .font(ABitTheme.display)
                            .foregroundStyle(ABitTheme.chalk)
                        Text(program.summary)
                            .font(ABitTheme.body)
                            .foregroundStyle(ABitTheme.mist)

                        HStack(spacing: 12) {
                            metaPill("\(program.minCredits) credits min")
                            metaPill(String(format: "%.1f GPA min", program.minGPA))
                        }
                    }

                    enrollRow

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements")
                            .font(ABitTheme.titleSm)
                            .foregroundStyle(ABitTheme.chalk)

                        ForEach(progress.requirements) { req in
                            requirementCard(req)
                        }
                    }

                    graduationBlock

                    Text(program.disclaimer)
                        .font(ABitTheme.micro)
                        .foregroundStyle(ABitTheme.mist.opacity(0.65))
                }
                .padding(22)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metaPill(_ text: String) -> some View {
        Text(text)
            .font(ABitTheme.micro)
            .foregroundStyle(ABitTheme.chalk)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ABitTheme.inkElevated, in: Capsule())
    }

    @ViewBuilder
    private var enrollRow: some View {
        if progress.conferred {
            Label("Degree conferred", systemImage: "checkmark.seal.fill")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.lime)
        } else if store.enrolledProgramIDs.contains(program.id) {
            HStack {
                Label("Enrolled", systemImage: "studentdesk")
                    .foregroundStyle(ABitTheme.chalk)
                Spacer()
                Button("Drop") { store.unenroll(from: program) }
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist)
            }
        } else {
            Button("Enroll in this program") {
                store.enroll(in: program)
            }
            .buttonStyle(PrimaryBitButton())
        }
    }

    private func requirementCard(_ req: RequirementProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: req.satisfied ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(req.satisfied ? ABitTheme.lime : ABitTheme.mist)
                VStack(alignment: .leading, spacing: 2) {
                    Text(req.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(ABitTheme.chalk)
                    Text("\(req.kind == .required ? "Required" : "Elective") · \(req.detail)")
                        .font(ABitTheme.micro)
                        .foregroundStyle(ABitTheme.mist)
                }
            }

            ForEach(req.courseStatuses) { course in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(course.title)
                            .font(ABitTheme.caption)
                            .foregroundStyle(ABitTheme.chalk)
                        Text(stateLabel(course))
                            .font(ABitTheme.micro)
                            .foregroundStyle(ABitTheme.mist)
                    }
                    Spacer()
                    if let grade = course.grade {
                        Text(grade.rawValue)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(course.state == .passed ? ABitTheme.lime : ABitTheme.mist)
                    }
                    Text("\(course.credits) cr")
                        .font(ABitTheme.micro)
                        .foregroundStyle(ABitTheme.mist)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.leading, 28)
            }
        }
        .padding(16)
        .background(ABitTheme.inkElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func stateLabel(_ course: RequirementCourseStatus) -> String {
        switch course.state {
        case .locked: return "Locked — finish prerequisites"
        case .available: return "Not started"
        case .inProgress: return "In progress"
        case .passed: return "Passed"
        case .failed: return "Failed — improve score to pass"
        }
    }

    @ViewBuilder
    private var graduationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Graduation")
                .font(ABitTheme.titleSm)
                .foregroundStyle(ABitTheme.chalk)

            if progress.conferred {
                Text("You’ve already commenced this program.")
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)
            } else if progress.canGraduate {
                Text("All requirements clear. Commence to seal the credential.")
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)
                Button(commenceFlash ? "Conferred" : "Commence") {
                    if store.commence(program) != nil {
                        commenceFlash = true
                    }
                }
                .buttonStyle(PrimaryBitButton())
                .disabled(commenceFlash)
            } else {
                Text("Still needed:")
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist)
                ForEach(progress.blockingReasons, id: \.self) { reason in
                    Label(reason, systemImage: "arrow.right.circle")
                        .font(ABitTheme.caption)
                        .foregroundStyle(ABitTheme.chalk.opacity(0.9))
                }
            }

            ProgressView(value: Double(progress.creditsEarned), total: Double(max(progress.creditsRequired, 1)))
                .tint(ABitTheme.lime)
            Text("\(progress.creditsEarned) / \(progress.creditsRequired) program credits")
                .font(ABitTheme.micro)
                .foregroundStyle(ABitTheme.mist)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(ABitTheme.lime.opacity(progress.canGraduate ? 0.55 : 0.15), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(ABitTheme.inkElevated)
                )
        )
    }
}

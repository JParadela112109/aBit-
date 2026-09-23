import SwiftUI

struct DegreeView: View {
    @Environment(AppStore.self) private var store
    @State private var appear = false
    @State private var selectedProgram: DegreeProgram?

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: .honey)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    conferredSection
                    programsSection
                    transcriptSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedProgram) { program in
            ProgramDetailView(program: program)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) { appear = true }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandMark(size: 34)
            Text("College")
                .font(ABitTheme.display)
                .foregroundStyle(ABitTheme.chalk)
            Text("Enroll in a program, earn credits, keep a GPA, graduate when requirements clear — like a real university, without the tuition.")
                .font(ABitTheme.body)
                .foregroundStyle(ABitTheme.mist)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                statChip(title: "Credits", value: "\(store.engine.creditsEarned)")
                statChip(
                    title: "GPA",
                    value: store.engine.cumulativeGPA.map { String(format: "%.2f", $0) } ?? "—"
                )
                statChip(title: "Degrees", value: "\(store.conferredDegrees.count)")
            }
            .padding(.top, 6)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(ABitTheme.micro)
                .tracking(1.1)
                .foregroundStyle(ABitTheme.mist)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(ABitTheme.lime)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ABitTheme.inkElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var conferredSection: some View {
        if !store.conferredDegrees.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Conferred")
                    .font(ABitTheme.titleSm)
                    .foregroundStyle(ABitTheme.chalk)

                ForEach(store.conferredDegrees) { degree in
                    conferredCard(degree)
                }
            }
        }
    }

    private func conferredCard(_ degree: ConferredDegree) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 36))
                .foregroundStyle(ABitTheme.lime)
            Text(degree.credential)
                .font(ABitTheme.title)
                .foregroundStyle(ABitTheme.chalk)
                .multilineTextAlignment(.center)
            Text(String(format: "GPA %.2f · %d credits", degree.gpa, degree.credits))
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
            Text("Not an accredited university degree.")
                .font(ABitTheme.micro)
                .foregroundStyle(ABitTheme.mist.opacity(0.6))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ABitTheme.inkElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(ABitTheme.lime.opacity(0.5), lineWidth: 1.5)
                )
        )
    }

    private var programsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Programs")
                .font(ABitTheme.titleSm)
                .foregroundStyle(ABitTheme.chalk)

            ForEach(store.programs) { program in
                Button {
                    selectedProgram = program
                } label: {
                    programRow(program)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func programRow(_ program: DegreeProgram) -> some View {
        let progress = store.programProgress(program)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.school.uppercased())
                        .font(ABitTheme.micro)
                        .tracking(1.2)
                        .foregroundStyle(ABitTheme.lime)
                    Text(program.fullName)
                        .font(ABitTheme.titleSm)
                        .foregroundStyle(ABitTheme.chalk)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if progress.conferred {
                    Text("Earned")
                        .font(ABitTheme.caption)
                        .foregroundStyle(ABitTheme.lime)
                } else if store.enrolledProgramIDs.contains(program.id) {
                    Text("Enrolled")
                        .font(ABitTheme.caption)
                        .foregroundStyle(ABitTheme.mist)
                }
            }

            Text(program.summary)
                .font(ABitTheme.caption)
                .foregroundStyle(ABitTheme.mist)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: Double(progress.creditsEarned), total: Double(max(progress.creditsRequired, 1)))
                .tint(ABitTheme.lime)

            HStack {
                Text("\(progress.creditsEarned)/\(progress.creditsRequired) credits")
                Spacer()
                if let gpa = progress.gpa {
                    Text(String(format: "GPA %.2f", gpa))
                }
            }
            .font(ABitTheme.micro)
            .foregroundStyle(ABitTheme.mist)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ABitTheme.inkElevated)
        )
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Transcript")
                .font(ABitTheme.titleSm)
                .foregroundStyle(ABitTheme.chalk)

            let rows = store.engine.transcript()
            if rows.isEmpty {
                Text("Pass a course final standing to post grades here.")
                    .font(ABitTheme.body)
                    .foregroundStyle(ABitTheme.mist)
            } else {
                ForEach(rows) { row in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(ABitTheme.chalk)
                            Text("\(row.department) · \(row.credits) cr")
                                .font(ABitTheme.micro)
                                .foregroundStyle(ABitTheme.mist)
                        }
                        Spacer()
                        Text(row.grade.rawValue)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(row.passed ? ABitTheme.lime : Color(red: 0.9, green: 0.35, blue: 0.3))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}


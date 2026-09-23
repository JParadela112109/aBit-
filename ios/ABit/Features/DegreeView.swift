import SwiftUI

struct DegreeView: View {
    @Environment(AppStore.self) private var store

    private var earned: Bool { store.progress >= 0.99 && !store.bites.isEmpty }

    var body: some View {
        ZStack {
            AtmosphereBackground()
            VStack(spacing: 24) {
                Text("aBit Degree")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(ABitTheme.chalk)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(ABitTheme.inkElevated)
                        .frame(height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(ABitTheme.lime.opacity(earned ? 0.8 : 0.2), lineWidth: 2)
                        )

                    VStack(spacing: 12) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(earned ? ABitTheme.lime : ABitTheme.mist)
                            .symbolEffect(.pulse, isActive: earned)

                        Text(earned ? "Bachelor of Bits" : "In progress")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundStyle(ABitTheme.chalk)

                        Text(earned ? "Death · Philosophy path cleared" : "Pass the course to claim your playful credential.")
                            .font(ABitTheme.body)
                            .foregroundStyle(ABitTheme.mist)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Text("Not an accredited university degree.")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(ABitTheme.mist.opacity(0.65))
                    }
                }
                .padding(.horizontal, 22)

                ProgressView(value: store.progress)
                    .tint(ABitTheme.lime)
                    .padding(.horizontal, 22)

                Spacer()
            }
            .padding(.top, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

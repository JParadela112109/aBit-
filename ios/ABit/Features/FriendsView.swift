import SwiftUI

struct FriendsView: View {
    @Environment(AppStore.self) private var store
    @State private var appear = false

    private var leaderboard: [FriendActivity] {
        var rows = store.friends
        rows.append(
            FriendActivity(
                id: "you",
                name: "You",
                studying: store.enrolledPrograms.first.map(\.fullName) ?? "Undeclared",
                bitsToday: store.bitsCompletedToday
            )
        )
        return rows.sorted { $0.bitsToday > $1.bitsToday }
    }

    var body: some View {
        ZStack {
            AtmosphereBackground(accent: .ocean)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Friends")
                            .font(ABitTheme.display)
                            .foregroundStyle(ABitTheme.chalk)
                        Text("Daily bits — your streak is \(store.currentStreak) day\(store.currentStreak == 1 ? "" : "s"). Best: \(store.longestStreak).")
                            .font(ABitTheme.body)
                            .foregroundStyle(ABitTheme.mist)
                    }
                    .padding(.top, 28)

                    Text("BITS TODAY")
                        .font(ABitTheme.caption)
                        .tracking(1.4)
                        .foregroundStyle(ABitTheme.lime)
                        .padding(.top, 8)

                    ForEach(Array(leaderboard.enumerated()), id: \.element.id) { rank, friend in
                        friendRow(rank: rank + 1, friend: friend, isYou: friend.id == "you")
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 14)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.84).delay(0.05 + Double(rank) * 0.07),
                                value: appear
                            )
                    }

                    Text("Live friends sync comes next — for now this is a local leaderboard with demo classmates.")
                        .font(ABitTheme.micro)
                        .foregroundStyle(ABitTheme.mist.opacity(0.65))
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation { appear = true }
        }
    }

    private func friendRow(rank: Int, friend: FriendActivity, isYou: Bool) -> some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(rank == 1 ? ABitTheme.lime : ABitTheme.mist)
                .frame(width: 28)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [ABitTheme.lime.opacity(isYou ? 0.7 : 0.45), ABitTheme.inkSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(friend.name.prefix(1)))
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundStyle(ABitTheme.chalk)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(ABitTheme.chalk)
                Text(friend.studying)
                    .font(ABitTheme.caption)
                    .foregroundStyle(ABitTheme.mist)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(friend.bitsToday)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(ABitTheme.lime)
                Text("bits")
                    .font(ABitTheme.micro)
                    .foregroundStyle(ABitTheme.mist)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ABitTheme.inkElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isYou ? ABitTheme.lime.opacity(0.45) : .clear, lineWidth: 1)
                )
        )
    }
}

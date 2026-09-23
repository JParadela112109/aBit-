import SwiftUI

struct FriendsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            AtmosphereBackground()
            List {
                Section {
                    ForEach(store.friends.sorted { $0.bitsToday > $1.bitsToday }) { friend in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(ABitTheme.lime.opacity(0.25))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(friend.name.prefix(1)))
                                        .font(.system(.title3, design: .serif).weight(.bold))
                                        .foregroundStyle(ABitTheme.lime)
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

                            Text("\(friend.bitsToday)")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(ABitTheme.lime)
                        }
                        .listRowBackground(ABitTheme.inkElevated)
                    }
                } header: {
                    Text("Bits today")
                        .foregroundStyle(ABitTheme.mist)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Friends")
    }
}

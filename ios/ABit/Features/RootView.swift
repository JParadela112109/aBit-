import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab: Tab = .learn

    enum Tab: Hashable {
        case learn, degree, friends
    }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Learn", systemImage: "square.grid.2x2.fill") }
            .tag(Tab.learn)

            NavigationStack {
                DegreeView()
            }
            .tabItem { Label("Degree", systemImage: "graduationcap.fill") }
            .tag(Tab.degree)

            NavigationStack {
                FriendsView()
            }
            .tabItem { Label("Friends", systemImage: "person.2.fill") }
            .tag(Tab.friends)
        }
        .tint(ABitTheme.lime)
        .toolbarBackground(ABitTheme.ink, for: .tabBar)
    }
}

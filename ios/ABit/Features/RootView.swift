import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab: Tab = .learn

    enum Tab: Hashable { case learn, degree, friends }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Learn", systemImage: "square.stack.3d.up.fill") }
            .tag(Tab.learn)

            NavigationStack {
                DegreeView()
            }
            .tabItem { Label("Degree", systemImage: "seal.fill") }
            .tag(Tab.degree)

            NavigationStack {
                FriendsView()
            }
            .tabItem { Label("Friends", systemImage: "person.2.fill") }
            .tag(Tab.friends)
        }
        .tint(ABitTheme.lime)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

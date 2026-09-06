import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("stellarJadeTotal") private var stellarJadeTotal = 0

    var body: some View {
        TabView {
            HomeView(stellarJadeTotal: stellarJadeTotal)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            CharacterListView()
                .tabItem {
                    Label("Characters", systemImage: "person.3")
                }

            StellarJadesView(stellarJadeTotal: $stellarJadeTotal)
                .tabItem {
                    Label("Jades", systemImage: "sparkles")
                }

            SettingsView(stellarJadeTotal: $stellarJadeTotal)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CharacterProgress.self, inMemory: true)
}

import SwiftUI

struct HomeView: View {
    let stellarJadeTotal: Int

    var body: some View {
        NavigationViewWrapper {
            List {
                Section("Current Balance") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stellar Jades")
                            .font(.headline)

                        Text(stellarJadeTotal.formatted())
                            .font(.largeTitle.bold())
                            .monospacedDigit()

                        Text("Running total earned from app activities.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView(stellarJadeTotal: 320)
}

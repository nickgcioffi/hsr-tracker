import SwiftUI

struct SettingsView: View {
    @Binding var stellarJadeTotal: Int

    var body: some View {
        NavigationViewWrapper {
            List {
                Section("Stellar Jades") {
                    Text("Current total: \(stellarJadeTotal.formatted())")
                        .monospacedDigit()

                    Button(role: .destructive, action: resetJades) {
                        Label("Reset Jade Count", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(stellarJadeTotal == 0)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func resetJades() {
        stellarJadeTotal = 0
    }
}

#Preview {
    SettingsView(stellarJadeTotal: .constant(160))
}

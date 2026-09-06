import SwiftUI

struct StellarJadesView: View {
    @Binding var stellarJadeTotal: Int

    private let claimOptions = [
        JadeClaimOption(title: "Box 1", reward: 5),
        JadeClaimOption(title: "Box 2", reward: 10),
        JadeClaimOption(title: "Box 3", reward: 20),
        JadeClaimOption(title: "Box 4", reward: 40)
    ]

    var body: some View {
        NavigationViewWrapper {
            List {
                Section("Current Balance") {
                    Text("\(stellarJadeTotal.formatted()) Stellar Jades")
                        .font(.headline)
                        .monospacedDigit()
                }

                Section("Claim Jades") {
                    ForEach(claimOptions) { option in
                        Button(action: { addJades(option.reward) }) {
                            HStack {
                                Text(option.title)
                                Spacer()
                                Text("+\(option.reward)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stellar Jades")
        }
    }

    private func addJades(_ amount: Int) {
        stellarJadeTotal += amount
    }
}

private struct JadeClaimOption: Identifiable {
    let title: String
    let reward: Int

    var id: String { title }
}

#Preview {
    StellarJadesView(stellarJadeTotal: .constant(75))
}

import SwiftUI
import SwiftData

struct CharacterProgressRow: View {
    @Bindable var progress: CharacterProgress
    let character: GameCharacter?
    let relicSet: RelicSet?
    let planarSet: RelicSet?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ResourceImageView(resourcePath: character?.icon, size: 40, fallbackSystemImage: "person.crop.circle")

                VStack(alignment: .leading, spacing: 2) {
                    Text(character?.name ?? "Unknown Character")
                        .font(.headline)
                    Text(characterDetailText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { progress.isComplete.toggle() }) {
                    Label(
                        progress.isComplete ? "Complete" : "Incomplete",
                        systemImage: progress.isComplete ? "checkmark.square.fill" : "checkmark.square"
                    )
                }
                .labelStyle(.iconOnly)
            }

            Text("Relic: \(relicSet?.name ?? progress.relicGoal)")
                .font(.subheadline)

            Text("Planar: \(planarSet?.name ?? progress.planarGoal)")
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private var characterDetailText: String {
        guard let character else {
            return "Missing bundled character data"
        }

        return "\(character.element) | \(character.rarity)-star"
    }
}

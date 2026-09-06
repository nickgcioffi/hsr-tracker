import SwiftUI

struct CharacterProgressRow: View {
    let character: GameCharacter?

    var body: some View {
        HStack(spacing: 12) {
            ResourceImageView(
                resourcePath: character?.portrait ?? character?.icon,
                size: 52,
                fallbackSystemImage: "person.crop.circle"
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(character?.name ?? "Unknown Character")
                    .font(.headline)
                Text(characterDetailText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var characterDetailText: String {
        guard let character else {
            return "Missing bundled character data"
        }

        return "\(character.element) | \(character.path) | \(character.rarity)-star"
    }
}

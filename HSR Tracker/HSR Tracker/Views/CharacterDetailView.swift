import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    @Bindable var progress: CharacterProgress
    let character: GameCharacter?
    let recommendation: CharacterBuildRecommendation?
    let lightConeByID: [String: LightCone]
    let relicSetByID: [String: RelicSet]
    let planarSetByID: [String: RelicSet]

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ResourceImageView(
                        resourcePath: character?.portrait ?? character?.icon,
                        size: 88,
                        fallbackSystemImage: "person.crop.circle"
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(character?.name ?? "Unknown Character")
                            .font(.title2.bold())
                        Text(characterDetailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Tracked Goal") {
                Toggle(isOn: $progress.isComplete) {
                    Text("Build Complete")
                }

                Text("Relic: \(relicSetByID[progress.relicGoal]?.name ?? progress.relicGoal)")
                Text("Planar: \(planarSetByID[progress.planarGoal]?.name ?? progress.planarGoal)")
            }

            Section("Recommendation") {
                BuildRecommendationSummaryView(
                    recommendation: recommendation,
                    lightConeByID: lightConeByID,
                    relicSetByID: relicSetByID,
                    planarSetByID: planarSetByID
                )
            }

            if let recommendation, recommendation.builds.count > 1 {
                Section("Build Variants") {
                    ForEach(recommendation.builds) { build in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(build.label)
                                .font(.headline)

                            BuildRecommendationSummaryView(
                                recommendation: recommendation,
                                lightConeByID: lightConeByID,
                                relicSetByID: relicSetByID,
                                planarSetByID: planarSetByID,
                                selectedBuild: build
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if let notes = recommendation?.builds.first?.notes {
                NotesSection(title: "Relic Notes", notes: notes.relics)
                NotesSection(title: "Other Notes", notes: notes.general)
            }
        }
        .navigationTitle(character?.name ?? "Character")
    }

    private var characterDetailText: String {
        guard let character else {
            return "Missing bundled character data"
        }

        return "\(character.element) | \(character.path) | \(character.rarity)-star"
    }
}

private struct NotesSection: View {
    let title: String
    let notes: [String]

    var body: some View {
        if !notes.isEmpty {
            Section(title) {
                ForEach(notes, id: \.self) { note in
                    Text(note)
                        .font(.subheadline)
                }
            }
        }
    }
}

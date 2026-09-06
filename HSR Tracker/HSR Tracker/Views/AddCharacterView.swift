import SwiftUI

struct AddCharacterView: View {
    let availableCharacters: [GameCharacter]
    let relicSets: [RelicSet]
    let planarSets: [RelicSet]
    let selectedCharacter: GameCharacter?
    let recommendation: CharacterBuildRecommendation?
    let lightConeByID: [String: LightCone]
    let relicSetByID: [String: RelicSet]
    let planarSetByID: [String: RelicSet]
    @Binding var selectedCharacterID: String
    @Binding var selectedRelicSetID: String
    @Binding var selectedPlanarSetID: String
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    private var previewCharacter: GameCharacter? {
        selectedCharacter ?? availableCharacters.first
    }

    private var previewRelicSet: RelicSet? {
        relicSets.first { $0.id == selectedRelicSetID } ?? relicSets.first
    }

    private var previewPlanarSet: RelicSet? {
        planarSets.first { $0.id == selectedPlanarSetID } ?? planarSets.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Character") {
                    Menu {
                        ForEach(availableCharacters) { character in
                            Button(action: { selectedCharacterID = character.id }) {
                                HStack(spacing: 8) {
                                    ResourceImageView(resourcePath: character.icon, size: 24, fallbackSystemImage: "person.crop.circle")
                                    Text(character.name)
                                }
                            }
                        }
                    } label: {
                        SelectionMenuLabel(
                            title: "Character",
                            selection: previewCharacter?.name ?? "Select a character"
                        )
                    }
                }

                Section("Recommendation") {
                    BuildRecommendationSummaryView(
                        recommendation: recommendation,
                        lightConeByID: lightConeByID,
                        relicSetByID: relicSetByID,
                        planarSetByID: planarSetByID,
                        isCompact: true
                    )
                }

                Section("Goals") {
                    Menu {
                        ForEach(relicSets) { relicSet in
                            Button(action: { selectedRelicSetID = relicSet.id }) {
                                HStack(spacing: 8) {
                                    ResourceImageView(resourcePath: relicSet.icon, size: 24, fallbackSystemImage: "seal")
                                    Text(relicSet.name)
                                }
                            }
                        }
                    } label: {
                        SelectionMenuLabel(
                            title: "Relic set",
                            selection: previewRelicSet?.name ?? "Select a relic set"
                        )
                    }

                    Menu {
                        ForEach(planarSets) { planarSet in
                            Button(action: { selectedPlanarSetID = planarSet.id }) {
                                HStack(spacing: 8) {
                                    ResourceImageView(resourcePath: planarSet.icon, size: 24, fallbackSystemImage: "circle.hexagongrid")
                                    Text(planarSet.name)
                                }
                            }
                        }
                    } label: {
                        SelectionMenuLabel(
                            title: "Planar set",
                            selection: previewPlanarSet?.name ?? "Select a planar set"
                        )
                    }
                }

                Section("Preview") {
                    HStack(alignment: .top, spacing: 16) {
                        GoalPreviewItem(
                            title: previewCharacter?.name ?? "Character",
                            subtitle: previewCharacter.map { "\($0.element) | \($0.rarity)-star" } ?? "Select a character",
                            resourcePath: previewCharacter?.portrait ?? previewCharacter?.icon,
                            fallbackSystemImage: "person.crop.circle",
                            imageSize: 88
                        )

                        GoalPreviewItem(
                            title: previewRelicSet?.name ?? "Relic set",
                            subtitle: "Relic",
                            resourcePath: previewRelicSet?.icon,
                            fallbackSystemImage: "seal",
                            imageSize: 56
                        )

                        GoalPreviewItem(
                            title: previewPlanarSet?.name ?? "Planar set",
                            subtitle: "Planar",
                            resourcePath: previewPlanarSet?.icon,
                            fallbackSystemImage: "circle.hexagongrid",
                            imageSize: 56
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(!canSave)
                }
            }
        }
    }
}

private struct SelectionMenuLabel: View {
    let title: String
    let selection: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Text(selection)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}

private struct GoalPreviewItem: View {
    let title: String
    let subtitle: String
    let resourcePath: String?
    let fallbackSystemImage: String
    let imageSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ResourceImageView(
                resourcePath: resourcePath,
                size: imageSize,
                fallbackSystemImage: fallbackSystemImage
            )

            Text(title)
                .font(.caption)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 120, alignment: .topLeading)
    }
}

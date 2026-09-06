import SwiftUI
import SwiftData

struct CharacterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressItems: [CharacterProgress]

    @State private var gameData = GameData.empty
    @State private var dataLoadError: String?
    @State private var showingAddSheet = false
    @State private var selectedCharacterID = ""
    @State private var selectedRelicSetID = ""
    @State private var selectedPlanarSetID = ""

    private var characterByID: [String: GameCharacter] {
        Dictionary(uniqueKeysWithValues: gameData.characters.map { ($0.id, $0) })
    }

    private var lightConeByID: [String: LightCone] {
        Dictionary(uniqueKeysWithValues: gameData.lightCones.map { ($0.id, $0) })
    }

    private var relicSetByID: [String: RelicSet] {
        Dictionary(uniqueKeysWithValues: gameData.relicSets.map { ($0.id, $0) })
    }

    private var planarSetByID: [String: RelicSet] {
        Dictionary(uniqueKeysWithValues: gameData.planarSets.map { ($0.id, $0) })
    }

    private var selectedCharacter: GameCharacter? {
        characterByID[selectedCharacterID]
    }

    private var selectedRecommendation: CharacterBuildRecommendation? {
        gameData.buildRecommendations[selectedCharacterID]
    }

    private var trackedProgress: [CharacterProgress] {
        progressItems.sorted { first, second in
            let firstName = characterByID[first.characterID]?.name ?? first.characterID
            let secondName = characterByID[second.characterID]?.name ?? second.characterID
            return firstName.localizedStandardCompare(secondName) == .orderedAscending
        }
    }

    private var availableCharacters: [GameCharacter] {
        let trackedIDs = Set(progressItems.map(\.characterID))
        return gameData.characters.filter { !trackedIDs.contains($0.id) }
    }

    private var canSaveCharacter: Bool {
        availableCharacters.contains { $0.id == selectedCharacterID }
            && relicSetByID[selectedRelicSetID] != nil
            && planarSetByID[selectedPlanarSetID] != nil
    }

    var body: some View {
        NavigationViewWrapper {
            List {
                if let dataLoadError {
                    Text(dataLoadError)
                        .foregroundStyle(.red)
                }

                Section("Tracked Characters") {
                    if trackedProgress.isEmpty {
                        Text("No characters tracked yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trackedProgress) { progress in
                            HStack(spacing: 12) {
                                Button(action: { progress.isComplete.toggle() }) {
                                    Image(systemName: progress.isComplete ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(progress.isComplete ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(progress.isComplete ? "Mark incomplete" : "Mark complete")

                                NavigationLink {
                                    CharacterDetailView(
                                        progress: progress,
                                        character: characterByID[progress.characterID],
                                        recommendation: gameData.buildRecommendations[progress.characterID],
                                        lightConeByID: lightConeByID,
                                        relicSetByID: relicSetByID,
                                        planarSetByID: planarSetByID
                                    )
                                } label: {
                                    CharacterProgressRow(character: characterByID[progress.characterID])
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("Tracked Characters")
            .toolbar {
                ToolbarItem {
                    Button(action: showAddSheet) {
                        Label("Add a Character", systemImage: "plus")
                    }
                    .disabled(availableCharacters.isEmpty || gameData.relicSets.isEmpty || gameData.planarSets.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCharacterView(
                    availableCharacters: availableCharacters,
                    relicSets: gameData.relicSets,
                    planarSets: gameData.planarSets,
                    selectedCharacter: selectedCharacter,
                    recommendation: selectedRecommendation,
                    lightConeByID: lightConeByID,
                    relicSetByID: relicSetByID,
                    planarSetByID: planarSetByID,
                    selectedCharacterID: $selectedCharacterID,
                    selectedRelicSetID: $selectedRelicSetID,
                    selectedPlanarSetID: $selectedPlanarSetID,
                    canSave: canSaveCharacter,
                    onCancel: closeAddSheet,
                    onSave: addCharacterProgress
                )
            }
            .task(loadGameData)
        }
    }

    private func loadGameData() async {
        do {
            gameData = try GameDataService.shared.loadGameData()
            dataLoadError = nil
        } catch {
            gameData = .empty
            dataLoadError = error.localizedDescription
        }
    }

    private func showAddSheet() {
        selectedCharacterID = availableCharacters.first?.id ?? ""
        selectedRelicSetID = gameData.relicSets.first?.id ?? ""
        selectedPlanarSetID = gameData.planarSets.first?.id ?? ""
        showingAddSheet = true
    }

    private func closeAddSheet() {
        showingAddSheet = false
        resetNewCharacterFields()
    }

    private func addCharacterProgress() {
        guard canSaveCharacter else {
            return
        }

        withAnimation {
            let progress = CharacterProgress(
                characterID: selectedCharacterID,
                relicGoal: selectedRelicSetID,
                planarGoal: selectedPlanarSetID
            )
            modelContext.insert(progress)
        }

        closeAddSheet()
    }

    private func resetNewCharacterFields() {
        selectedCharacterID = ""
        selectedRelicSetID = ""
        selectedPlanarSetID = ""
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(trackedProgress[index])
            }
        }
    }
}

#Preview {
    CharacterListView()
        .modelContainer(for: CharacterProgress.self, inMemory: true)
}

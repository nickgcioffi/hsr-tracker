//
//  ContentView.swift
//  HSR Tracker
//
//  Created by Nick Cioffi on 7/31/26.
//

import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ContentView: View {
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

    private var relicSetByID: [String: RelicSet] {
        Dictionary(uniqueKeysWithValues: gameData.relicSets.map { ($0.id, $0) })
    }

    private var planarSetByID: [String: RelicSet] {
        Dictionary(uniqueKeysWithValues: gameData.planarSets.map { ($0.id, $0) })
    }

    private var selectedCharacter: GameCharacter? {
        characterByID[selectedCharacterID]
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
                            CharacterProgressRow(
                                progress: progress,
                                character: characterByID[progress.characterID],
                                relicSet: relicSetByID[progress.relicGoal],
                                planarSet: planarSetByID[progress.planarGoal]
                            )
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("HSR Tracker")
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

private struct CharacterIconView: View {
    let resourcePath: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let image = loadImage() {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityHidden(true)
    }

    private func loadImage() -> Image? {
        guard let resourcePath,
              let url = GameDataService.shared.imageURL(for: resourcePath) else {
            return nil
        }

#if os(iOS)
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        return Image(uiImage: image)
#elseif os(macOS)
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        return Image(nsImage: image)
#else
        return nil
#endif
    }
}

private struct CharacterProgressRow: View {
    @Bindable var progress: CharacterProgress
    let character: GameCharacter?
    let relicSet: RelicSet?
    let planarSet: RelicSet?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                CharacterIconView(resourcePath: character?.icon, size: 40)

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

private struct AddCharacterView: View {
    let availableCharacters: [GameCharacter]
    let relicSets: [RelicSet]
    let planarSets: [RelicSet]
    let selectedCharacter: GameCharacter?
    @Binding var selectedCharacterID: String
    @Binding var selectedRelicSetID: String
    @Binding var selectedPlanarSetID: String
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Character") {
                    Picker("Character", selection: $selectedCharacterID) {
                        ForEach(availableCharacters) { character in
                            Text(character.name).tag(character.id)
                        }
                    }

                    if let selectedCharacter {
                        HStack(spacing: 12) {
                            CharacterIconView(resourcePath: selectedCharacter.icon, size: 56)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedCharacter.name)
                                    .font(.headline)
                                Text("\(selectedCharacter.element) | \(selectedCharacter.rarity)-star")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Goals") {
                    Picker("Relic set", selection: $selectedRelicSetID) {
                        ForEach(relicSets) { relicSet in
                            Text(relicSet.name).tag(relicSet.id)
                        }
                    }

                    Picker("Planar set", selection: $selectedPlanarSetID) {
                        ForEach(planarSets) { planarSet in
                            Text(planarSet.name).tag(planarSet.id)
                        }
                    }
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

fileprivate struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
#if os(macOS)
        NavigationSplitView {
            content()
        } detail: {
            Text("Select an item")
        }
#elseif os(iOS)
        NavigationStack {
            content()
        }
#endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CharacterProgress.self, inMemory: true)
}

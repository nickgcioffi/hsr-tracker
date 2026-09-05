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

private struct ResourceImageView: View {
    let resourcePath: String?
    let size: CGFloat
    let fallbackSystemImage: String

    var body: some View {
        Group {
            if let image = loadImage() {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSystemImage)
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

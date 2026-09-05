//
//  ContentView.swift
//  HSR Tracker
//
//  Created by Nick Cioffi on 7/31/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chars: [Char]
    @State private var newName: String = ""
    @State private var newRelic: String = ""
    @State private var newPlanet: String = ""
    @State private var showingAddSheet = false

    var body: some View {
        NavigationViewWrapper{
            List {
                ForEach(chars) { char in
                    VStack(alignment: .leading) {
                        HStack() {
                            Button(action: {char.complete.toggle()}) {
                                Label("Completed", systemImage: char.complete ? "checkmark.square.fill" : "checkmark.square")
                            }
                        }
                        Text(char.name)
                        Text(char.relic)
                        Text(char.planet)
                        }
                    }
                .onDelete(perform: deleteItems)
                }
            
            // For the top bar
            .toolbar {
                ToolbarItem {
                    Button(action: {showingAddSheet.toggle()}) {
                        Label("Add a Character", systemImage: "plus")
                        }
                    }
                }
            // For typing in a character
            .sheet(isPresented: $showingAddSheet) {
                TextField("Character Name", text: $newName)
                TextField("Relic Set", text:$newRelic)
                TextField("Planet Sets", text:$newPlanet)
                Button(action: {
                    if addChar() {
                        showingAddSheet.toggle()
                        resetNewCharacterFields()
                    }
                }) {
                    Text("Save")
                }
                .disabled(!canSaveCharacter)
                }
            
            }
        
    }

    private var canSaveCharacter: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addChar() -> Bool {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let relic = newRelic.trimmingCharacters(in: .whitespacesAndNewlines)
        let planet = newPlanet.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            return false
        }

        withAnimation {
            let newChar = Char(name: name, relic: relic, planet: planet, complete: false)
            modelContext.insert(newChar)
        }

        return true
    }

    private func resetNewCharacterFields() {
        newName = ""
        newRelic = ""
        newPlanet = ""
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(chars[index])
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
        
}

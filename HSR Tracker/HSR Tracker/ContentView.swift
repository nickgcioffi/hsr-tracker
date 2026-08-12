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
        // Color.black
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
            
            .toolbar {
                ToolbarItem {
                    Button(action: {showingAddSheet.toggle()}) {
                        Label("Add a Character", systemImage: "plus")
                        }
                    }
                }
            .sheet(isPresented: $showingAddSheet) {
                TextField("Character Name", text: $newName)
                TextField("Relic Set", text:$newRelic)
                TextField("Planet Sets", text:$newPlanet)
                Button(action: {addChar(); showingAddSheet.toggle(); newName = ""; newRelic = ""; newPlanet = ""}) {
                    Text("Save")
                }
                }
            }
        
    }

    private func addChar() {
        withAnimation {
            let newChar = Char(name: newName, relic: newRelic, planet: newPlanet, complete: false)
            modelContext.insert(newChar)
        }
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

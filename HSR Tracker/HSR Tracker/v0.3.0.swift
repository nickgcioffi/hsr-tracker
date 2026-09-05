//
//  v0.3.0.swift
//  HSR Tracker
//
//  Created by Nick Cioffi on 8/12/26.
//

import Foundation
import SwiftData

struct GameCharacter: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let tag: String
    let rarity: Int
    let path: String
    let element: String
    let maxSP: Int
    let icon: String
    let preview: String
    let portrait: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tag
        case rarity
        case path
        case element
        case maxSP = "max_sp"
        case icon
        case preview
        case portrait
    }
}

struct LightCone: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let rarity: Int
    let path: String
    let description: String
    let icon: String
    let preview: String
    let portrait: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rarity
        case path
        case description = "desc"
        case icon
        case preview
        case portrait
    }
}

struct Relic: Codable, Identifiable, Hashable {
    let id: String
    let setID: String
    let name: String
    let rarity: Int
    let type: String
    let maxLevel: Int
    let mainAffixID: String
    let subAffixID: String
    let icon: String

    enum CodingKeys: String, CodingKey {
        case id
        case setID = "set_id"
        case name
        case rarity
        case type
        case maxLevel = "max_level"
        case mainAffixID = "main_affix_id"
        case subAffixID = "sub_affix_id"
        case icon
    }
}

struct GameData {
    let characters: [GameCharacter]
    let lightCones: [LightCone]
    let relics: [Relic]

    static let empty = GameData(characters: [], lightCones: [], relics: [])
}

enum GameDataError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Could not find \(name).json in the app bundle."
        }
    }
}

final class GameDataService {
    static let shared = GameDataService()

    private init() {}

    func loadGameData() throws -> GameData {
        GameData(
            characters: try loadDictionaryResource("characters", as: GameCharacter.self),
            lightCones: try loadDictionaryResource("light_cones", as: LightCone.self),
            relics: try loadDictionaryResource("relics", as: Relic.self)
        )
    }

    private func loadDictionaryResource<T: Decodable>(_ resourceName: String, as type: T.Type) throws -> [T] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw GameDataError.missingResource(resourceName)
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([String: T].self, from: data)

        return decoded
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map(\.value)
    }
}

@Model
final class CharacterProgress {
    var characterID: String
    var relicGoal: String
    var planarGoal: String
    var isComplete: Bool

    init(characterID: String, relicGoal: String = "", planarGoal: String = "", isComplete: Bool = false) {
        self.characterID = characterID
        self.relicGoal = relicGoal
        self.planarGoal = planarGoal
        self.isComplete = isComplete
    }
}

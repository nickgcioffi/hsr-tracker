import Foundation

struct GameCharacter: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let tag: String
    let rarity: Int
    let path: String
    let element: String
    let maxSP: Int?
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

struct RelicSet: Identifiable, Hashable {
    enum Category {
        case relic
        case planar
    }

    let id: String
    let name: String
    let category: Category
    let icon: String
}

struct GameData {
    let characters: [GameCharacter]
    let lightCones: [LightCone]
    let relics: [Relic]
    let relicSets: [RelicSet]
    let planarSets: [RelicSet]

    static let empty = GameData(characters: [], lightCones: [], relics: [], relicSets: [], planarSets: [])
}

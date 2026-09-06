import Foundation

struct CharacterBuildRecommendation: Codable, Hashable {
    let characterID: String
    let sourceCharacterName: String
    let source: BuildRecommendationSource
    let builds: [RecommendedBuild]

    enum CodingKeys: String, CodingKey {
        case characterID = "character_id"
        case sourceCharacterName = "source_character_name"
        case source
        case builds
    }
}

struct BuildRecommendationSource: Codable, Hashable {
    let name: String
    let version: String
}

struct RecommendedBuild: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let roles: [String]
    let archetypes: [String]
    let lightCones: [RecommendedLightCone]
    let relicSets: [RecommendedRelicSet]
    let planarSets: [RecommendedRelicSet]
    let mainStats: RecommendedMainStats
    let substats: [RecommendedSubstatPriority]
    let statTargets: [RecommendedStatTarget]
    let abilityPriority: [RecommendedAbilityPriority]
    let notableEidolons: [String]
    let notes: RecommendedBuildNotes

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case roles
        case archetypes
        case lightCones = "light_cones"
        case relicSets = "relic_sets"
        case planarSets = "planar_sets"
        case mainStats = "main_stats"
        case substats
        case statTargets = "stat_targets"
        case abilityPriority = "ability_priority"
        case notableEidolons = "notable_eidolons"
        case notes
    }
}

struct RecommendedLightCone: Codable, Hashable {
    let lightConeID: String?
    let sourceName: String
    let rank: Int?
    let tied: Bool
    let special: Bool
    let availability: [String]?
    let conditions: [String]
    let footnoteRefs: [String]

    enum CodingKeys: String, CodingKey {
        case lightConeID = "light_cone_id"
        case sourceName = "source_name"
        case rank
        case tied
        case special
        case availability
        case conditions
        case footnoteRefs = "footnote_refs"
    }
}

struct RecommendedRelicSet: Codable, Hashable {
    let setID: String?
    let sourceName: String
    let pieces: Int?
    let rank: Int?
    let tied: Bool
    let special: Bool
    let availability: [String]?
    let conditions: [String]
    let footnoteRefs: [String]

    enum CodingKeys: String, CodingKey {
        case setID = "set_id"
        case sourceName = "source_name"
        case pieces
        case rank
        case tied
        case special
        case availability
        case conditions
        case footnoteRefs = "footnote_refs"
    }
}

struct RecommendedMainStats: Codable, Hashable {
    let body: [RecommendedStat]
    let feet: [RecommendedStat]
    let sphere: [RecommendedStat]
    let rope: [RecommendedStat]
}

struct RecommendedSubstatPriority: Codable, Hashable {
    let rank: Int?
    let stats: [RecommendedStat]
    let tied: Bool
    let footnoteRefs: [String]

    enum CodingKeys: String, CodingKey {
        case rank
        case stats
        case tied
        case footnoteRefs = "footnote_refs"
    }
}

struct RecommendedStatTarget: Codable, Hashable {
    let stat: RecommendedStat?
    let target: String?
    let sourceText: String?
    let footnoteRefs: [String]

    enum CodingKeys: String, CodingKey {
        case stat
        case target
        case sourceText = "source_text"
        case footnoteRefs = "footnote_refs"
    }
}

struct RecommendedAbilityPriority: Codable, Hashable {
    let rank: Int?
    let ability: String
    let tied: Bool
    let footnoteRefs: [String]

    enum CodingKeys: String, CodingKey {
        case rank
        case ability
        case tied
        case footnoteRefs = "footnote_refs"
    }
}

struct RecommendedBuildNotes: Codable, Hashable {
    let relics: [String]
    let abilities: [String]
    let general: [String]
    let references: [String]
}

struct RecommendedStat: Codable, Hashable {
    let id: String?
    let source: String?

    init(id: String) {
        self.id = id
        self.source = nil
    }

    init(source: String) {
        self.id = nil
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            id = value
            source = nil
            return
        }

        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        id = nil
        source = try keyedContainer.decode(String.self, forKey: .source)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let id {
            try container.encode(id)
            return
        }

        try container.encode(["source": source ?? "Unknown"])
    }

    private enum CodingKeys: String, CodingKey {
        case source
    }
}

extension RecommendedStat {
    var displayName: String {
        let value = id ?? source ?? "Unknown"
        return value
            .replacingOccurrences(of: "_percent", with: "%")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

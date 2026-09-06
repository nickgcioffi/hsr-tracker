import Foundation

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
        let relics = try loadDictionaryResource("relics", as: Relic.self)
        let sets = try loadDictionaryResource("relic_sets", as: RelicSet.self)

        return GameData(
            characters: try loadDictionaryResource("characters", as: GameCharacter.self),
            lightCones: try loadDictionaryResource("light_cones", as: LightCone.self),
            relics: relics,
            relicSets: sets.filter { $0.category == .relic },
            planarSets: sets.filter { $0.category == .planar },
            buildRecommendations: try loadDictionaryMap("build_recommendations", as: CharacterBuildRecommendation.self)
        )
    }

    func imageURL(for resourcePath: String) -> URL? {
        if let url = bundledResourceURL(for: resourcePath) {
            return url
        }

        let avatarPath = resourcePath.replacingOccurrences(of: "icon/character/", with: "icon/avatar/")
        return bundledResourceURL(for: avatarPath)
    }

    private func loadDictionaryResource<T: Decodable>(_ resourceName: String, as type: T.Type) throws -> [T] {
        let decoded = try loadDictionaryMap(resourceName, as: type)

        return decoded
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map(\.value)
    }

    private func loadDictionaryMap<T: Decodable>(_ resourceName: String, as type: T.Type) throws -> [String: T] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw GameDataError.missingResource(resourceName)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: T].self, from: data)
    }

    private func bundledResourceURL(for resourcePath: String) -> URL? {
        let url = URL(fileURLWithPath: resourcePath)
        let resourceName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        let subdirectory = url.deletingLastPathComponent().relativePath

        if let resourceBundle = resourceBundle,
           let url = resourceBundle.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: subdirectory.isEmpty ? nil : subdirectory
           ) {
            return url
        }

        return Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: subdirectory.isEmpty ? nil : subdirectory
        )
    }

    private var resourceBundle: Bundle? {
        guard let url = Bundle.main.url(forResource: "HSRResources", withExtension: "bundle") else {
            return nil
        }

        return Bundle(url: url)
    }
}

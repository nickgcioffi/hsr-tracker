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
        let sets = buildRelicSets(from: relics)

        return GameData(
            characters: try loadDictionaryResource("characters", as: GameCharacter.self),
            lightCones: try loadDictionaryResource("light_cones", as: LightCone.self),
            relics: relics,
            relicSets: sets.filter { $0.category == .relic },
            planarSets: sets.filter { $0.category == .planar }
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
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw GameDataError.missingResource(resourceName)
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([String: T].self, from: data)

        return decoded
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map(\.value)
    }

    private func buildRelicSets(from relics: [Relic]) -> [RelicSet] {
        let groupedRelics = Dictionary(grouping: relics, by: \.setID)

        return groupedRelics.compactMap { setID, relics in
            guard let representative = representativeRelic(from: relics) else {
                return nil
            }

            return RelicSet(
                id: setID,
                name: representative.name,
                category: setID.hasPrefix("3") ? .planar : .relic,
                icon: representative.icon
            )
        }
        .sorted { first, second in
            first.id.localizedStandardCompare(second.id) == .orderedAscending
        }
    }

    private func representativeRelic(from relics: [Relic]) -> Relic? {
        let preferredTypes = ["HEAD", "NECK", "HAND", "OBJECT", "BODY", "FOOT"]

        for type in preferredTypes {
            if let relic = relics.first(where: { $0.type == type }) {
                return relic
            }
        }

        return relics.first
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

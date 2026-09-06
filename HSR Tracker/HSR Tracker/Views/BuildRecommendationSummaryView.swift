import SwiftUI

struct BuildRecommendationSummaryView: View {
    let recommendation: CharacterBuildRecommendation?
    let lightConeByID: [String: LightCone]
    let relicSetByID: [String: RelicSet]
    let planarSetByID: [String: RelicSet]
    var selectedBuild: RecommendedBuild?
    var isCompact = false

    private var build: RecommendedBuild? {
        selectedBuild ?? recommendation?.builds.first
    }

    var body: some View {
        Group {
            if let build {
                VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                    if recommendation?.builds.count ?? 0 > 1, selectedBuild == nil {
                        Text("Showing: \(build.label)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    RecommendationLine(title: "Relic", value: relicSummary(from: build.relicSets, lookup: relicSetByID))
                    RecommendationLine(title: "Planar", value: relicSummary(from: build.planarSets, lookup: planarSetByID))
                    RecommendationLine(title: "Stats", value: mainStatsSummary(from: build.mainStats))

                    if !isCompact {
                        RecommendationLine(title: "Light Cone", value: lightConeSummary(from: build.lightCones))
                        RecommendationLine(title: "Substats", value: substatSummary(from: build.substats))
                        RecommendationLine(title: "Targets", value: statTargetSummary(from: build.statTargets))
                        RecommendationLine(title: "Abilities", value: abilitySummary(from: build.abilityPriority))
                    }
                }
            } else {
                Text("No build recommendation available for this character yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func lightConeSummary(from items: [RecommendedLightCone]) -> String {
        items.prefix(isCompact ? 2 : 5).map { item in
            displayName(for: item, lookup: lightConeByID)
        }.joined(separator: " / ")
    }

    private func relicSummary(from items: [RecommendedRelicSet], lookup: [String: RelicSet]) -> String {
        items.prefix(isCompact ? 2 : 5).map { item in
            displayName(for: item, lookup: lookup)
        }.joined(separator: " / ")
    }

    private func mainStatsSummary(from mainStats: RecommendedMainStats) -> String {
        [
            "Body: \(statList(mainStats.body))",
            "Feet: \(statList(mainStats.feet))",
            "Sphere: \(statList(mainStats.sphere))",
            "Rope: \(statList(mainStats.rope))"
        ].joined(separator: " • ")
    }

    private func substatSummary(from substats: [RecommendedSubstatPriority]) -> String {
        substats.prefix(4).map { priority in
            let rank = priority.rank.map { "\($0). " } ?? ""
            return rank + statList(priority.stats)
        }.joined(separator: " • ")
    }

    private func statTargetSummary(from targets: [RecommendedStatTarget]) -> String {
        targets.map { target in
            if let stat = target.stat, let value = target.target {
                return "\(stat.displayName): \(value)"
            }

            return target.sourceText ?? "Unparsed target"
        }.joined(separator: " • ")
    }

    private func abilitySummary(from abilities: [RecommendedAbilityPriority]) -> String {
        abilities.map { ability in
            let rank = ability.rank.map { "\($0). " } ?? ""
            let tiePrefix = ability.tied ? "T" : ""
            return tiePrefix + rank + ability.ability
        }.joined(separator: " • ")
    }

    private func statList(_ stats: [RecommendedStat]) -> String {
        stats.map(\.displayName).joined(separator: " / ")
    }

    private func displayName(for item: RecommendedLightCone, lookup: [String: LightCone]) -> String {
        if let id = item.lightConeID, let lightCone = lookup[id] {
            return rankedName(rank: item.rank, tied: item.tied, name: lightCone.name)
        }

        return rankedName(rank: item.rank, tied: item.tied, name: item.sourceName)
    }

    private func displayName(for item: RecommendedRelicSet, lookup: [String: RelicSet]) -> String {
        if let id = item.setID, let relicSet = lookup[id] {
            return rankedName(rank: item.rank, tied: item.tied, name: relicSet.name)
        }

        return rankedName(rank: item.rank, tied: item.tied, name: item.sourceName)
    }

    private func rankedName(rank: Int?, tied: Bool, name: String) -> String {
        let prefix = rank.map { tied ? "T\($0). " : "\($0). " } ?? ""
        return prefix + name
    }
}

private struct RecommendationLine: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "Not listed" : value)
                .font(.subheadline)
        }
    }
}

import Foundation
import SwiftData

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

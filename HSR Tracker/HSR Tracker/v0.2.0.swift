//
//  Item.swift
//  HSR Tracker
//
//  Created by Nick Cioffi on 7/31/26.
//

import Foundation
import SwiftData

@Model
    final class Char {
        var name: String
        var relic: String
        var planet: String
        var complete: Bool
        init(name: String, relic: String, planet: String, complete: Bool = false) {
            self.name = name
            self.relic = relic
            self.planet = planet
            self.complete = complete
        }

}

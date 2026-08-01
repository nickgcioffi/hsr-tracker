//
//  Item.swift
//  HSR Tracker
//
//  Created by Nick Cioffi on 7/31/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

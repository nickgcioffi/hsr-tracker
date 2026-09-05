//
//  v0.3.0.swift
//  HSR Tracker
//
//  Created by Nick Cioffi on 8/12/26.
//

import Foundation

// How the .jsons will be accessed
final class ResourceFileManager {
    static let shared = ResourceFileManager()
    var homedir = "/HSR_Tracker/HSR_Tracker/"

    private init() {}

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

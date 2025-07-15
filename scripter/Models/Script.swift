//
//  Script.swift
//  scripter
//
//  Created by Chandra Dasari on 7/11/25.
//

import AppKit

struct Script: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var content: String
    var createdAt = Date()
    // TODO: Need to figure out how to check for available shells on the system and allow user to pick, no need for shebang.
    var isExecutable: Bool {
        content.hasPrefix("#!/")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Script, rhs: Script) -> Bool {
        lhs.id == rhs.id
    }
}


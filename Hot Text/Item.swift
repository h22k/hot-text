//
//  Item.swift
//  Hot Text
//
//  Created by Halil Hakan Karabay on 25.12.2024.
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

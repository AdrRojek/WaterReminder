//
//  Item.swift
//  WaterReminder
//
//  Created by adrian on 16/02/2025.
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

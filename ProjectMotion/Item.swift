//
//  Item.swift
//  ProjectMotion
//
//  Created by Thomas B on 9/25/25.
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

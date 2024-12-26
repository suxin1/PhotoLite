//
//  Item.swift
//  PhotoLite
//
//  Created by Suxin on 2024/12/26.
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

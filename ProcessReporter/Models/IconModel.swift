//
//  IconModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/14.
//

import Foundation
import SwiftData

@Model
class IconModel {
    @Attribute(.unique)
    var id: UUID
    var name: String
    var url: String

    init( name: String, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
    }
}

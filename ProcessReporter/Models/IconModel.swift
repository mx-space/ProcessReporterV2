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
    var applicationIdentifier: String

    init(name: String, url: String, applicationIdentifier: String) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.applicationIdentifier = applicationIdentifier
    }
}

extension IconModel {
    @MainActor static func findIcon(for bundleID: String) -> IconModel? {
        guard let context = Database.shared.ctx else { return nil }
        let descriptor = FetchDescriptor<IconModel>(
            predicate: #Predicate<IconModel> { icon in
                icon.applicationIdentifier == bundleID
            }
        )

        let res = try? context.fetch(descriptor)
        return res?.first
    }
}

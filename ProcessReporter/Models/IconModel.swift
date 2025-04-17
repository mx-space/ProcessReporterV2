//
//  IconModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/14.
//

import Foundation
import SwiftData

enum IconModelV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [IconModel.self]
    }

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
}

enum IconModelV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [IconModel.self]
    }

    @Model
    class IconModel {
        var name: String
        var url: String
        @Attribute(.unique)
        var applicationIdentifier: String

        init(name: String, url: String, applicationIdentifier: String) {
            self.name = name
            self.url = url
            self.applicationIdentifier = applicationIdentifier
        }
    }
}

@Model
class IconModel {
    var name: String
    var url: String
    @Attribute(.unique)
    var applicationIdentifier: String

    init(name: String, url: String, applicationIdentifier: String) {
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

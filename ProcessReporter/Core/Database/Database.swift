//
//  Database.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/10.
//
import Foundation
import SwiftData

@MainActor
class Database {
    static let shared = Database()
    private var modelContainer: ModelContainer?

    public var ctx: ModelContext? {
        modelContainer?.mainContext
    }

    func initialize() {
        // Set up default location in Application Support directory
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let bundleID = Bundle.main.bundleIdentifier!
        let directoryURL = appSupportURL.appendingPathComponent(bundleID)

        // Set the path to the name of the store you want to set up
        let fileURL = directoryURL.appendingPathComponent("db.store")

        debugPrint(fileURL)
        // Create a schema for your model (**Item 1**)
        let schema = Schema([ReportModel.self, IconModel.self])

        do {
            // This next line will create a new directory called Example in Application Support if one doesn't already exist, and will do nothing if one already exists, so we have a valid place to put our store
            try fileManager.createDirectory(
                at: directoryURL, withIntermediateDirectories: true, attributes: nil)

            // Create our `ModelConfiguration` (**Item 3**)
            let defaultConfiguration = ModelConfiguration(bundleID, schema: schema, url: fileURL)

            do {
                // Create our `ModelContainer`
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: MigrationPlan.self,
                    configurations: defaultConfiguration
                )
            } catch {
                fatalError("Could not initialise the container…")
            }
        } catch {
            fatalError("Could not find/create Example folder in Application Support")
        }
    }
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ReportModelV1.self, IconModelV1.self, IconModelV2.self]
    }

    static var stages: [MigrationStage] {
        [
            MigrationStage.custom(
                fromVersion: IconModelV1.self,
                toVersion: IconModelV2.self,
                willMigrate: { context in
                    try migrateIconModelToV2(context: context)
                },
                didMigrate: nil
            )
        ]
    }

    static func migrateIconModelToV2(context: ModelContext) throws {
        let fetchDescriptor = FetchDescriptor<IconModel>()
        let allIcons = try context.fetch(fetchDescriptor)

        // Group by applicationIdentifier
        var iconsByIdentifier: [String: [IconModel]] = [:]

        for icon in allIcons {
            if iconsByIdentifier[icon.applicationIdentifier] == nil {
                iconsByIdentifier[icon.applicationIdentifier] = []
            }
            iconsByIdentifier[icon.applicationIdentifier]?.append(icon)
        }

        // Keep first item, delete duplicates
        for (_, icons) in iconsByIdentifier {
            if icons.count > 1 {
                // Keep the first one
                let firstIcon = icons[0]

                // Delete the rest
                for i in 1..<icons.count {
                    context.delete(icons[i])
                }
            }
        }
    }
}

//
//  Reporter+S3.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/14.
//

import Foundation
import SwiftData

private let name = "S3"

extension Reporter {
    func registerS3() {
        register(
            name: name,
            options: ReporterOptions(
                onSend: { data in
                    if !PreferencesDataModel.shared.s3Integration.value.isEnabled {
                        return .failure(.cancelled)
                    }

                    guard let nsImage = data.processInfoRaw?.icon, let iconData = nsImage.data,
                          let applicationIdentifier = data.processInfoRaw?.applicationIdentifier

                    else {
                        return .failure(.cancelled)
                    }

                    let icon = IconModel.findIcon(for: applicationIdentifier)
                    if icon != nil {
                        return .success(())
                    }

                    guard
                        let url = try? await S3Uploader.uploadIconToS3(
                            iconData, appName: data.processName
                        )
                    else {
                        return .failure(.networkError("Upload failed"))
                    }

                    let iconModel = IconModel(
                        name: data.processName, url: url,
                        applicationIdentifier: applicationIdentifier
                    )
                    if let context = Database.shared.ctx {
                        context.insert(iconModel)
                        do {
                            try context.save()
                        } catch {
                            print("Failed to save icon model: \(error)")
                            
                        }
                    }

                    return .success(())
                }
            )
        )
    }

    func unregisterS3() {
        unregister(name: name)
    }
}

extension S3Uploader {
    static func uploadIconToS3(_ imageData: Data, appName: String) async throws -> String {
        let config = PreferencesDataModel.s3Integration.value

        // Create S3Uploader
        let options = S3UploaderOptions(
            bucket: config.bucket,
            region: config.region,
            accessKey: config.accessKey,
            secretKey: config.secretKey,
            endpoint: config.endpoint.isEmpty ? nil : config.endpoint
        )

        let uploader = S3Uploader(options: options)

        return try await uploader.uploadImage(imageData, to: "app-icons")
    }
}

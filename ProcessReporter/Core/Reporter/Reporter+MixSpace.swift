//
//  Reporter+MixSpace.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/10.
//

import Alamofire
import Foundation

private struct MixSpaceDataPayload: Codable {
    struct MediaInfo: Codable {
        let artist: String?
        let title: String?
        let duration: Double?
        let elapsedTime: Double?
        let processName: String?
    }

    struct Meta: Codable {
        let iconBase64: String?
        let iconUrl: String?
        let description: String?
    }

    let media: MediaInfo?
    let process: String
    let key: String
    let timestamp: UInt
    let meta: Meta?

    init(media: MediaInfo?, process: String, key: String, meta: Meta? = nil) {
        self.media = media
        self.process = process
        self.key = key
        timestamp = UInt(Int(Date().timeIntervalSince1970))
        self.meta = meta
    }
}

private func sendMixSpaceRequest(data: ReportModel) async -> Result<Void, ReporterError> {
    let config = PreferencesDataModel.shared.mixSpaceIntegration.value
    let endpoint = config.endpoint
    let method = config.requestMethod
    let token = config.apiToken

    let requestPayload = MixSpaceDataPayload(
        media: .init(
            artist: data.artist,
            title: data.mediaName,
            duration: data.mediaDuration,
            elapsedTime: data.mediaElapsedTime,
            processName: data.mediaProcessName
        ),
        process: data.processName,
        key: token
    )

    let headers: HTTPHeaders = [
        "Content-Type": "application/json",
    ]

    do {
        _ = try await AF.request(
            endpoint,
            method: .init(rawValue: method),
            parameters: requestPayload,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .serializingData()
        .value

        return .success(())
    } catch {
        print("MixSpace request failed: \(error.localizedDescription)")
        return .failure(.networkError(error.localizedDescription))
    }
}

private let name = "MixSpace"
extension Reporter {
    func registerMixSpace() {
        register(
            name: name,
            options: ReporterOptions(
                onSend: { data in
                    if !PreferencesDataModel.shared.mixSpaceIntegration.value.isEnabled { return .failure(.cancelled) }

                    return await sendMixSpaceRequest(data: data)
                }
            )
        )
    }

    func unregisterMixSpace() {
        unregister(name: name)
    }
}

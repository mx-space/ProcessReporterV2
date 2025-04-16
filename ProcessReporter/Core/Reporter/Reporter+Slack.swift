//
//  Reporter+Slack.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/16.
//

import Alamofire
import Foundation

private let stackEndpoint = "https://slack.com/api/users.profile.set"

private struct ProfileData: Codable {
    var status_text: String
    var status_emoji: String
    var status_expiration: Int
}
private let slackRatelimiter = Ratelimiter(
    capacity: 1,
    refillRate: 10.0 / 60.0,  // 每分钟十个请求
    minimumInterval: 10  // 最小间隔 10 秒
)

private let name = "Slack"
extension Reporter {
    func registerSlack() {
        let options: ReporterOptions = .init { data in
            let slackConfig = PreferencesDataModel.shared.slackIntegration.value
            guard slackConfig.isEnabled else {
                return .failure(.ignored)
            }
            guard slackRatelimiter.tryAcquire() else {
                return .failure(.ratelimitExceeded(message: "Slack integration is rate limited"))
            }

            var statusText = slackConfig.statusTextTemplateString
            if let mediaProcessName = data.mediaProcessName {
                statusText = slackConfig.statusTextTemplateString.replacingOccurrences(
                    of: "{media_process_name}", with: mediaProcessName)
            }

            if let mediaName = data.mediaName {
                statusText = statusText.replacingOccurrences(of: "{media_name}", with: mediaName)
            }

            if let artistName = data.mediaInfoRaw?.artist {
                statusText = statusText.replacingOccurrences(of: "{artist}", with: artistName)
            }

            if let mediaName = data.mediaName, let artistName = data.mediaInfoRaw?.artist {
                statusText = statusText.replacingOccurrences(
                    of: "{media_name_artist}", with: "\(artistName) - \(mediaName)")
            }

            if let processName = data.processName {
                statusText = statusText.replacingOccurrences(
                    of: "{process_name}", with: processName)
            }
            let statusExpiration = {
                let currentDate = Date()
                let duration = Int(data.mediaDuration ?? Double(slackConfig.expiration))
                return Calendar.current.date(
                    byAdding: .second, value: duration, to: currentDate)!
                    .timeIntervalSince1970
            }()

            let profile: ProfileData = .init(
                status_text: statusText, status_emoji: slackConfig.customEmoji,
                status_expiration: Int(statusExpiration))
            let token = slackConfig.apiToken

            if token.isEmpty {
                return .failure(
                    .unknown(message: "Missing Slack Api Token", successIntegrations: []))
            }
            do {
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer " + token,
                    "Content-Type": "application/json; charset=utf-8",
                ]
                _ = try await AF.request(
                    URL(string: stackEndpoint)!,
                    method: .post,
                    parameters: ["profile": profile],
                    encoder: JSONParameterEncoder.default,
                    headers: headers
                )
                .validate()
                .serializingData()
                .value

            } catch {
                print(
                    "MixSpace request failed: \(error.asAFError?.localizedDescription ?? error.localizedDescription)"
                )
                return .failure(.networkError(error.localizedDescription))
            }

            return .success(())
        }
        self.register(name: name, options: options)
    }

    func unregisterSlack() {
        self.unregister(name: name)
    }
}

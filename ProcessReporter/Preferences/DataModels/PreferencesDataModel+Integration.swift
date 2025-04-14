//
//  PreferencesDataModel+Integration.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import Foundation
import RxCocoa
import RxSwift

struct MixSpaceIntegration: UserDefaultsJSONStorable, DictionaryConvertible {
    var isEnabled: Bool = false
    var apiToken: String = ""
    var endpoint: String = ""
    var requestMethod: String = "POST"
}

struct SlackIntegration: UserDefaultsJSONStorable, DictionaryConvertible {
    var isEnabled: Bool = false
    var apiToken: String = ""
    var customEmoji: String = ""
    var customStatusText: String = ""
}
// MARK: - S3 Integration Model
struct S3Integration: UserDefaultsJSONStorable, DictionaryConvertible {
    var isEnabled: Bool = false
    var bucket: String = ""
    var region: String = "us-east-1"
    var accessKey: String = ""
    var secretKey: String = ""
    var endpoint: String = ""
    var path: String = ""

    var customDomain: String = ""
}

extension PreferencesDataModel {
    @UserDefaultsRelay("mixSpaceIntegration", defaultValue: MixSpaceIntegration())
    static var mixSpaceIntegration: BehaviorRelay<MixSpaceIntegration>

    @UserDefaultsRelay("slackIntegration", defaultValue: SlackIntegration())
    static var slackIntegration: BehaviorRelay<SlackIntegration>
}

extension MixSpaceIntegration {
    static func fromDictionary(_ dict: [String: Any]) -> MixSpaceIntegration {
        var integration = MixSpaceIntegration()
        integration.isEnabled = dict["isEnabled"] as? Bool ?? false
        integration.apiToken = dict["apiToken"] as? String ?? ""
        integration.endpoint = dict["endpoint"] as? String ?? ""
        integration.requestMethod = dict["requestMethod"] as? String ?? "POST"
        return integration
    }
}

extension SlackIntegration {
    static func fromDictionary(_ dict: [String: Any]) -> SlackIntegration {
        var integration = SlackIntegration()
        integration.isEnabled = dict["isEnabled"] as? Bool ?? false
        integration.apiToken = dict["apiToken"] as? String ?? ""
        integration.customEmoji = dict["customEmoji"] as? String ?? ""
        integration.customStatusText = dict["customStatusText"] as? String ?? ""
        return integration
    }
}

extension S3Integration {
    static func fromDictionary(_ dict: [String: Any]) -> S3Integration {
        var integration = S3Integration()
        integration.isEnabled = dict["isEnabled"] as? Bool ?? false
        integration.bucket = dict["bucket"] as? String ?? ""
        integration.region = dict["region"] as? String ?? "us-east-1"
        integration.accessKey = dict["accessKey"] as? String ?? ""
        integration.secretKey = dict["secretKey"] as? String ?? ""
        integration.endpoint = dict["endpoint"] as? String ?? ""
        integration.path = dict["path"] as? String ?? ""
        integration.customDomain = dict["customDomain"] as? String ?? ""
        return integration
    }
}

extension PreferencesDataModel {
    @UserDefaultsRelay("s3Integration", defaultValue: S3Integration())
    static var s3Integration: BehaviorRelay<S3Integration>
}

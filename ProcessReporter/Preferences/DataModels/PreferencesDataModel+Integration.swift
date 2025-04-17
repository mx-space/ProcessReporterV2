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
    var globalCustomEmoji: String = "🎵"
    var statusTextTemplateString: String = "{me} 正在使用 {media_process_name} 听 {media_name_artist}"
    var expiration: Int = 60
    var defaultEmoji: String = ""
    var defaultStatusText: String = ""
    var customEmojiConditionList: EmojiConditionList = .init()
}

struct EmojiConditionList: Codable, UserDefaultsStorable, DictionaryConvertible, DictionaryConvertibleDelegate {
    func toDictionary() -> Any {
        return conditions.map { $0.toDictionary() }
    }

    struct EmojiCondition: Codable, Equatable, UserDefaultsJSONStorable, DictionaryConvertible {
        static func fromDictionary(_ dict: [String: Any]) -> EmojiConditionList.EmojiCondition {
            let when = dict["when"] as? String ?? ""
            let emoji = dict["emoji"] as? String ?? ""
            return EmojiCondition(when: when, emoji: emoji)
        }

        let when: String
        let emoji: String
    }

    private var conditions: [EmojiCondition] = []

    init(conditions: [EmojiCondition] = []) {
        self.conditions = conditions
    }

    func toStorable() -> Any? {
        return conditions.map { $0.toDictionary() }
    }

    static func fromStorable(_ value: Any?) -> EmojiConditionList? {
        guard let array = value as? [[String: Any]] else { return nil }
        let conditions = array.compactMap { EmojiCondition.fromDictionary($0) }
        return EmojiConditionList(conditions: conditions)
    }

    static func fromDictionary(_ dict: [String: Any]) -> EmojiConditionList {
        if let conditions = dict as? [[String: Any]] {
            return EmojiConditionList(conditions: conditions.compactMap { EmojiCondition.fromDictionary($0) })
        }
        return EmojiConditionList()
    }
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
        integration.globalCustomEmoji = dict["globalCustomEmoji"] as? String ?? ""
        integration.statusTextTemplateString = dict["statusTextTemplateString"] as? String ?? ""
        integration.expiration = dict["expiration"] as? Int ?? 60
        integration.defaultEmoji = dict["defaultEmoji"] as? String ?? ""
        integration.defaultStatusText = dict["defaultStatusText"] as? String ?? ""
        if let conditions = dict["customEmojiConditionList"] as? [[String: Any]] {
            integration.customEmojiConditionList = EmojiConditionList(conditions: conditions.compactMap { EmojiConditionList.EmojiCondition.fromDictionary($0) })
        }
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

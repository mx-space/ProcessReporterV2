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

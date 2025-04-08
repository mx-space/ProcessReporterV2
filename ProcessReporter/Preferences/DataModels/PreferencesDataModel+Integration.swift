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

protocol DictionaryConvertible {
    func toDictionary() -> [String: Any]
}

extension DictionaryConvertible {
    func toDictionary() -> [String: Any] {
        let mirror = Mirror(reflecting: self)
        var dict: [String: Any] = [:]

        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            dict[propertyName] = child.value
        }

        return dict
    }
}

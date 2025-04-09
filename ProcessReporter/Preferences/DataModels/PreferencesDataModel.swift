//
//  PreferencesDataModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/7.
//

import Foundation
import RxCocoa
import RxSwift

class PreferencesDataModel {
    public static let shared = PreferencesDataModel.self

    static func collectPreferences() -> [String: Any] {
        [
            "isEnabled": PreferencesDataModel.isEnabled.value,
            "focusReport": PreferencesDataModel.focusReport.value,
            "sendInterval": PreferencesDataModel.sendInterval.value.rawValue,
            "mixSpaceIntegration": PreferencesDataModel.mixSpaceIntegration.value.toDictionary(),
            "slackIntegration": PreferencesDataModel.slackIntegration.value.toDictionary(),
        ]
    }

    public static func exportToPlist() -> Data? {
        let dictionary = collectPreferences()

        return try? PropertyListSerialization.data(
            fromPropertyList: dictionary,
            format: .xml,
            options: 0
        )
    }

    public static func importFromPlist(data: Data) -> Bool {
        do {
            guard
                let dictionary = try PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil) as? [String: Any]
            else {
                return false
            }

            if let isEnabled = dictionary["isEnabled"] as? Bool {
                PreferencesDataModel.isEnabled.accept(isEnabled)
            }
            if let focusReport = dictionary["focusReport"] as? Bool {
                PreferencesDataModel.focusReport.accept(focusReport)
            }
            if let sendIntervalRaw = dictionary["sendInterval"] as? Int,
                let sendInterval = SendInterval(rawValue: sendIntervalRaw)
            {
                PreferencesDataModel.sendInterval.accept(sendInterval)
            }
            if let mixSpaceDict = dictionary["mixSpaceIntegration"] as? [String: Any] {
                PreferencesDataModel.mixSpaceIntegration.accept(
                    MixSpaceIntegration.fromDictionary(mixSpaceDict))
            }
            if let slackDict = dictionary["slackIntegration"] as? [String: Any] {
                PreferencesDataModel.slackIntegration.accept(
                    SlackIntegration.fromDictionary(slackDict))
            }

            return true
        } catch {
            return false
        }
    }
}

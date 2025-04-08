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
}

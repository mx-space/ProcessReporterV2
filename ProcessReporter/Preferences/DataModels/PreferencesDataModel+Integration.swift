//
//  PreferencesDataModel+Integration.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import Foundation
import RxCocoa
import RxSwift

struct MixSpaceIntegration: UserDefaultsJSONStorable {
    var isEnabled: Bool = false
    var apiToken: String = ""
    var endpoint: String = ""
    var requestMethod: String = "POST"
}

extension PreferencesDataModel {
    @UserDefaultsRelay("mixSpaceIntegration", defaultValue: MixSpaceIntegration())
    static var mixSpaceIntegration: BehaviorRelay<MixSpaceIntegration>
}

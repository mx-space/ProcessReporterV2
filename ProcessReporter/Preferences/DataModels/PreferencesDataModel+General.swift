//
//  PreferencesDataModel+General.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import Foundation
import RxSwift
import RxCocoa

extension PreferencesDataModel {
    @UserDefaultsRelay("isEnabled", defaultValue: false)
    static var isEnabled: BehaviorRelay<Bool>

    @UserDefaultsRelay("sendInterval", defaultValue: SendInterval.tenSeconds)
    static var sendInterval: BehaviorRelay<SendInterval>

    @UserDefaultsRelay("focusReport", defaultValue: true)
    static var focusReport: BehaviorRelay<Bool>
}

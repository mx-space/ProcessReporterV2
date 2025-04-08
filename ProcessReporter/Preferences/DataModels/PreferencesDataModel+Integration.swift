//
//  PreferencesDataModel+Integration.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import Foundation
import RxCocoa
import RxSwift

struct MixSpaceIntegration: Codable {
    var isEnabled: Bool = false
    var apiToken: String = ""
    var endpoint: String = ""
    var requestMethod: String = "POST"
}

extension MixSpaceIntegration: UserDefaultsStorable {
    func toStorable() -> Any? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let jsonData = try? encoder.encode(self) {
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString ?? ""
        }
        return nil
    }

    static func fromStorable(_ value: Any?) -> MixSpaceIntegration? {
        guard let value = value as? String else {
            return nil
        }
        let decoder = JSONDecoder()
        if let jsonData = value.data(using: .utf8) {
            if let mixSpaceIntegration = try? decoder.decode(MixSpaceIntegration.self, from: jsonData) {
                return mixSpaceIntegration
            }
        }
        return nil
    }
}

extension PreferencesDataModel {
    @UserDefaultsRelay("mixSpaceIntegration", defaultValue: MixSpaceIntegration())
    static var mixSpaceIntegration: BehaviorRelay<MixSpaceIntegration>
}

//
//  SendInterval.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import Foundation

enum SendInterval: Int, CaseIterable {
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60

    func toString() -> String {
        switch self {
        case .tenSeconds:
            return "10s"
        case .thirtySeconds:
            return "30s"
        case .oneMinute:
            return "60s"
        }
    }

    static func toLabels() -> [String] {
        return SendInterval.allCases.map { $0.toString() }
    }

    static func labelToValue(_ label: String) -> SendInterval? {
        return SendInterval.allCases.first { $0.toString() == label }
    }
}

extension SendInterval: UserDefaultsStorable {
    func toStorable() -> Any {
        return rawValue
    }

    static func fromStorable(_ value: Any) -> SendInterval? {
        if let intValue = value as? Int {
            return SendInterval(rawValue: intValue)
        }
        return nil
    }
}

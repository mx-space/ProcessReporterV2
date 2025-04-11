//
//  Date.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/11.
//

import Foundation

extension Date {
    func relativeTimeDescription() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        switch interval {
        case ..<1:
            return "just now"
        case 1..<60:
            return "\(Int(interval))s ago"
        case 60..<3600:
            return "\(Int(interval / 60))m ago"
        case 3600..<86400:
            return "\(Int(interval / 3600))h ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
    }
}


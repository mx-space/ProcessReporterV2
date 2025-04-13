//
//  Date.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/11.
//

import Foundation

extension Date {
    func relativeTimeDescription() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        // 小于 1s
        if self.timeIntervalSinceNow > -1 && self.timeIntervalSinceNow < 1 {
            return "Just now"
        }

        let relativeDate = formatter.localizedString(for: self, relativeTo: Date.now)
        return relativeDate
    }
}

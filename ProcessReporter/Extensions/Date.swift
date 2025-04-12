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

        let relativeDate = formatter.localizedString(for: self, relativeTo: Date.now)
        return relativeDate
    }
}

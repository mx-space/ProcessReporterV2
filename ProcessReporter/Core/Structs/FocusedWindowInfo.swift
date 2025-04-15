//
//  FocusedWindowInfo.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/15.
//

import Foundation
import Cocoa

struct FocusedWindowInfo {
    let appName: String
    let icon: NSImage?
    let applicationIdentifier: String

    let title: String?

    init(appName: String, icon: NSImage?, applicationIdentifier: String, title: String? = nil) {
        self.appName = appName
        self.icon = icon
        self.applicationIdentifier = applicationIdentifier
        self.title = title
    }
}

//
//  NSMenuItem.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/11.
//

import Cocoa

extension NSMenuItem {
    convenience init(title: String, action: Selector?, keyEquivalent: String, target: AnyObject) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.target = target
    }
}

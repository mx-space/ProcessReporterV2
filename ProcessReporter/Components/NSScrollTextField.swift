//
//  NSScrollTextField.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/14.
//

import Cocoa

class NSScrollTextField: NSTextField {
    convenience init() {
        self.init(frame: .zero)
        self.cell?.isScrollable = true
    }
}

class NSScrollSecureTextField: NSSecureTextField {
    convenience init() {
        self.init(frame: .zero)
        self.cell?.isScrollable = true
    }
}

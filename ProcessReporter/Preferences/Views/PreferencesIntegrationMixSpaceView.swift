//
//  PreferencesIntegrationMixSpaceView.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import AppKit
import SnapKit

class PreferencesIntegrationMixSpaceView: NSView {
    private var textField: NSTextField

    init() {
        textField = NSTextField(labelWithString: "Integration Mix Space")
        super.init(frame: .zero)

        wantsLayer = true
        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

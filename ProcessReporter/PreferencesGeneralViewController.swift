//
//  PreferencesGeneralViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//
import AppKit

class PreferencesGeneralViewController: NSViewController, SettingWindowProtocol {
    final let frameSize: NSSize = NSSize(width: 800, height: 600)
    override func viewDidAppear() {
        super.viewDidAppear()
        view.frame.size = frameSize

        let label = NSTextField(labelWithString: "General Settings")
        label.font = NSFont.systemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.snp.makeConstraints { make in

            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(200)
        }
        label.isEditable = false
    }
}

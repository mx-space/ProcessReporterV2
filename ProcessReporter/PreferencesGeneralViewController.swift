//
//  PreferencesGeneralViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//

import AppKit
import SnapKit

class PreferencesGeneralViewController: NSViewController, SettingWindowProtocol {
    final let frameSize: NSSize = NSSize(width: 800, height: 600)

    private var gridView: NSGridView!
    private var enabledButton: NSButton!
    private var intervalPopup: NSPopUpButton!

    private let spacer = NSView()

    override func loadView() {
        super.loadView()
        view.frame = NSRect(origin: .zero, size: frameSize)
        setupGridView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func setupGridView() {
        gridView = NSGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 16
        gridView.columnSpacing = 12

        view.addSubview(gridView)

        gridView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.width.lessThanOrEqualToSuperview().inset(40)
        }
        // 1. Interval (Label + Popup)
        let intervalLabel = NSTextField(labelWithString: "Interval:")
        intervalLabel.alignment = .right
        intervalPopup = NSPopUpButton()
        intervalPopup.addItems(withTitles: ["1s", "2s", "5s"])
        gridView.addRow(with: [intervalLabel, intervalPopup])

        // 2. Enabled checkbox (full width)
        enabledButton = NSButton(
            checkboxWithTitle: "Enabled", target: self, action: #selector(enabledButtonClicked))
        gridView.addRow(with: [spacer, enabledButton])
    }

    @objc private func enabledButtonClicked(sender: NSButton) {
        // handle change
    }
}

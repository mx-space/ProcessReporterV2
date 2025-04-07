//
//  PreferencesGeneralViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//

import AppKit
import os.log
import ServiceManagement
import SnapKit

class PreferencesGeneralViewController: NSViewController, SettingWindowProtocol {
    private let logger = Logger()
    final let frameSize: NSSize = NSSize(width: 600, height: 300)

    private var gridView: NSGridView!
    private var enabledButton: NSButton!
    private var intervalPopup: NSPopUpButton!
    private var focusReportButton: NSButton!
    private var startupButton: NSButton!

    private var spacer: NSView {
        NSView()
    }

    override func loadView() {
        super.loadView()
        view.frame = NSRect(origin: .zero, size: frameSize)
        setupGridView()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        synchronizeUI()
    }

    private func synchronizeUI() {
        enabledButton.state = PreferencesDataModel.shared.isEnabled.value ? .on : .off
        intervalPopup.selectItem(
            withTitle: PreferencesDataModel.shared.sendInterval.value.toString())
        focusReportButton.state = PreferencesDataModel.shared.focusReport.value ? .on : .off
        startupButton.state = checkWasLaunchedAtLogin() ? .on : .off
    }

    private func setupGridView() {
        gridView = NSGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 16
        gridView.columnSpacing = 12

        view.addSubview(gridView)

        gridView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
            make.width.lessThanOrEqualToSuperview().inset(40)
        }

        // Enabled checkbox

        enabledButton = NSButton(
            checkboxWithTitle: "Enabled", target: self, action: #selector(enabledButtonClicked))
        createRow(leftView: NSTextField(labelWithString: "App:"), rightView: enabledButton)

        startupButton = NSButton(
            checkboxWithTitle: "Start at login", target: self, action: #selector(toggleStartAtLogin)
        )
        createRow(leftView: spacer, rightView: startupButton)

        focusReportButton = NSButton(
            checkboxWithTitle: "Report when application focused", target: self,
            action: #selector(focusReportButtonClicked))
        createRow(
            leftView: NSTextField(labelWithString: "Focus Report:"), rightView: focusReportButton)

        // Send Interval label and popup

        intervalPopup = NSPopUpButton()
        intervalPopup.addItems(
            withTitles:
            SendInterval.toLabels()
        )
        intervalPopup.action = #selector(switchInterval)
        createRow(
            leftView: NSTextField(labelWithString: "Send Interval:"), rightView: intervalPopup)
    }

    private func checkWasLaunchedAtLogin() -> Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}

extension PreferencesGeneralViewController {
    private func createRow(leftView: NSView, rightView: NSView) {
        gridView.addRow(with: [leftView, rightView])
        gridView.cell(for: leftView)?.xPlacement = .trailing
    }
}

extension PreferencesGeneralViewController {
    @objc private func switchInterval(sender: NSPopUpButton) {
        let label = sender.itemTitles[sender.indexOfSelectedItem]
        PreferencesDataModel.shared.sendInterval.accept(
            SendInterval.labelToValue(label) ?? .tenSeconds)
    }

    @objc private func enabledButtonClicked(sender: NSButton) {
        PreferencesDataModel.shared.isEnabled.accept(sender.state == .on)
    }

    @objc private func focusReportButtonClicked(sender: NSButton) {
        PreferencesDataModel.shared.focusReport.accept(sender.state == .on)
    }

    @objc private func toggleStartAtLogin(sender: NSButton) {
        let isOn = sender.state == .on

        do {
            if isOn {
                if SMAppService.mainApp.status == .enabled {
                    try? SMAppService.mainApp.unregister()
                }

                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Failed to \(isOn ? "enable" : "disable") launch at login: \(error.localizedDescription)")
        }
    }
}

//
//  PreferencesGeneralViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//

import AppKit
import ServiceManagement
import SnapKit
import os.log

class PreferencesGeneralViewController: NSViewController, SettingWindowProtocol {
    private let logger = Logger()
    final let frameSize: NSSize = NSSize(width: 600, height: 250)

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
        setupUI()
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

    private func setupUI() {
        gridView = NSGridView()
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
        intervalPopup.isEnabled = true
        intervalPopup.autoenablesItems = false
        intervalPopup.addItems(
            withTitles:
                SendInterval.toLabels()
        )
        intervalPopup.action = #selector(switchInterval)
        intervalPopup.target = self
        createRow(
            leftView: NSTextField(labelWithString: "Send Interval:"), rightView: intervalPopup)

        // Separator
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        // 添加分隔符行并设置为跨列
        gridView.addRow(with: [separator])
        gridView.row(at: gridView.numberOfRows - 1).mergeCells(in: NSRange(location: 0, length: 2))

        // Data Control Stack
        let dataControlStackView = NSStackView()
        dataControlStackView.orientation = .horizontal
        dataControlStackView.spacing = 8

        // Data Control Label
        let dataControlLabel = NSTextField(labelWithString: "Setting Backup:")
        dataControlLabel.isEditable = false

        // Import Data button
        let dataImportButton = NSButton(
            title: "Import Settings", target: self, action: #selector(importData))
        dataImportButton.bezelStyle = .rounded
        dataControlStackView.addArrangedSubview(dataImportButton)

        // Export Data button
        let dataExportButton = NSButton(
            title: "Export Settings", target: self, action: #selector(exportData))
        dataExportButton.bezelStyle = .rounded
        dataControlStackView.addArrangedSubview(dataExportButton)

        // 将整个 stack 添加到 gridView 中
        createRow(leftView: dataControlLabel, rightView: dataControlStackView)
    }

    private func checkWasLaunchedAtLogin() -> Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue
                == keyAELaunchedAsLogInItem
    }
}

// MARK: UI Utils

extension PreferencesGeneralViewController {
    private func createRow(leftView: NSView, rightView: NSView) {
        gridView.addRow(with: [leftView, rightView])
        gridView.cell(for: leftView)?.xPlacement = .trailing
    }
}

// MARK: Actions

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
            logger.error(
                "Failed to \(isOn ? "enable" : "disable") launch at login: \(error.localizedDescription)"
            )
        }
    }

    @objc func exportData() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Choose a directory to export data"
        openPanel.showsHiddenFiles = false
        openPanel.prompt = "Export"

        let fileName = "ProcessReporterData.plist"

        let data = PreferencesDataModel.shared.exportToPlist()
        guard let data = data else { return }

        if openPanel.runModal() == .OK {
            guard let selectedURL = openPanel.url else {
                return
            }

            let fileManager = FileManager.default
            let filePathURL = selectedURL.appendingPathComponent(fileName)
            let filePath = filePathURL.path

            do {
                // 检查文件是否已存在
                if fileManager.fileExists(atPath: filePath) {
                    try fileManager.removeItem(atPath: filePath)
                }

                try data.write(to: filePathURL, options: [.atomic])

                print("文件创建成功，路径: \(filePath)")

            } catch {
                print("创建文件失败: \(error.localizedDescription)")
            }
        } else {
            print("用户取消了选择")
        }
    }

    @objc func importData() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Choose a file to import data"
        openPanel.showsHiddenFiles = true
        openPanel.prompt = "Import"
        openPanel.allowedContentTypes = [.propertyList]

        if openPanel.runModal() != .OK {
            return
        }

        guard let selectedURL = openPanel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: selectedURL)
            if PreferencesDataModel.importFromPlist(data: data) {
                ToastManager.shared.success("Import successfully")
                synchronizeUI()
            } else {
                ToastManager.shared.error("Import failed: Invalid data format")
            }
        } catch {
            ToastManager.shared.error("Import failed: \(error.localizedDescription)")
        }
    }
}

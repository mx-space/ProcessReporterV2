//
//  PreferencesIntegrationMixSpaceView.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import AppKit
import SnapKit

class PreferencesIntegrationMixSpaceView: IntegrationView {
    // Controls
    private let enabledButton: NSButton
    private let endpointInput: NSTextField
    private let methodSelect: NSPopUpButton
    private let apiKeyInput: NSSecureTextField

    private lazy var saveButton: NSButton = {
        var saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .push
        saveButton.bezelColor = .accent
        return saveButton
    }()

    private lazy var resetButton: NSButton = {
        var resetButton = NSButton(title: "Reset", target: self, action: #selector(reset))
        resetButton.bezelStyle = .rounded
        return resetButton
    }()

    init() {
        // Initialize controls
        enabledButton = NSButton(checkboxWithTitle: "", target: nil, action: nil)

        endpointInput = NSTextField(frame: .zero)
        endpointInput.placeholderString = "Enter endpoint URL"

        methodSelect = NSPopUpButton(frame: .zero, pullsDown: false)
        methodSelect.addItems(withTitles: ["GET", "POST", "PUT", "DELETE"])
        methodSelect.controlSize = .regular
        methodSelect.font = .systemFont(ofSize: NSFont.systemFontSize)

        apiKeyInput = NSSecureTextField(frame: .zero)
        apiKeyInput.placeholderString = "Enter API Key"

        super.init(frame: .zero)

        setupGridView()
        synchronizeUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func synchronizeUI() {
        // Synchronize UI with data model
        let integration = PreferencesDataModel.shared.mixSpaceIntegration.value
        enabledButton.state = integration.isEnabled ? .on : .off
        endpointInput.stringValue = integration.endpoint
        methodSelect.selectItem(withTitle: integration.requestMethod)
        apiKeyInput.stringValue = integration.apiToken
    }

    @objc
    private func reset() {
        synchronizeUI()
    }

    @objc
    private func save() {
        // Save the integration settings
        var integration = PreferencesDataModel.shared.mixSpaceIntegration.value
        integration.isEnabled = enabledButton.state == .on
        integration.endpoint = endpointInput.stringValue
        integration.requestMethod = methodSelect.selectedItem?.title ?? "POST"
        integration.apiToken = apiKeyInput.stringValue
        PreferencesDataModel.shared.mixSpaceIntegration.accept(integration)
    }

    private func setupGridView() {
        setupUI()

        // Enabled row
        createRow(
            leftView: NSTextField(labelWithString: "Enabled"),
            rightView: enabledButton
        )

        // Endpoint row
        createRow(
            leftView: NSTextField(labelWithString: "Endpoint"),
            rightView: endpointInput
        )

        // Method row
        createRow(
            leftView: NSTextField(labelWithString: "Request Method"),
            rightView: methodSelect
        )

        // API Key row
        createRow(
            leftView: NSTextField(labelWithString: "API Key"),
            rightView: apiKeyInput
        )

        // Save button row
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.addArrangedSubview(resetButton)
        buttonStack.addArrangedSubview(saveButton)
        gridView.addRow(with: [NSView(), buttonStack])
        gridView.cell(for: buttonStack)?.xPlacement = .trailing
    }
}

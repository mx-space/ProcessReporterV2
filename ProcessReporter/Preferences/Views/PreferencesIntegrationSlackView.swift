//
//  PreferencesIntegrationSlackView.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import AppKit
import RxCocoa
import RxSwift
import SnapKit

class PreferencesIntegrationSlackView: IntegrationView {
    private lazy var enabledButton: NSButton = {
        let button = NSButton(
            checkboxWithTitle: "", target: nil, action: nil)

        return button
    }()

    private lazy var customEmojiInput: NSTextField = {
        let textField = NSTextField()
        textField.placeholderString = "Custom Emoji"
        textField.isEditable = true
        textField.isSelectable = true
        textField.cell?.isScrollable = true
        return textField
    }()

    private lazy var customStatusTextInput: NSTextField = {
        let textField = NSTextField()
        textField.placeholderString = "Custom Status Text"
        textField.isEditable = true
        textField.isSelectable = true
        textField.cell?.isScrollable = true
        return textField
    }()

    private lazy var apiKeyInput: NSSecureTextField = {
        let textField = NSSecureTextField()
        textField.placeholderString = "API Key"
        textField.isEditable = true
        textField.isSelectable = true
        textField.cell?.isScrollable = true
        return textField
    }()

    private lazy var saveButton: NSButton = {
        let button = NSButton(title: "Save", target: nil, action: nil)
        button.bezelStyle = .push
        button.bezelColor = .accent
        return button
    }()

    private lazy var resetButton: NSButton = {
        let button = NSButton(title: "Reset", target: nil, action: nil)
        button.bezelStyle = .rounded
        return button
    }()

    init() {
        super.init(frame: .zero)

        setupUI()
        synchronizeUI()
    }

    override internal func setupUI() {
        super.setupUI()

        // Enabled row
        createRow(
            leftView: NSTextField(labelWithString: "Enabled"),
            rightView: enabledButton
        )

        // Api Key row
        createRow(
            leftView: NSTextField(labelWithString: "API Key"),
            rightView: apiKeyInput
        )

        // Custom Emoji row
        createRow(
            leftView: NSTextField(labelWithString: "Custom Emoji"),
            rightView: customEmojiInput
        )

        // Custom Status Text row
        createRow(
            leftView: NSTextField(labelWithString: "Custom Status Text"),
            rightView: customStatusTextInput
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func synchronizeUI() {
        // Synchronize UI with data model
        let integration = PreferencesDataModel.shared.slackIntegration.value
        enabledButton.state = integration.isEnabled ? .on : .off
        customEmojiInput.stringValue = integration.customEmoji
        customStatusTextInput.stringValue = integration.customStatusText
    }

    @objc private func reset() {
        synchronizeUI()
    }

    @objc private func save() {
        var integration = PreferencesDataModel.shared.slackIntegration.value
        integration.isEnabled = enabledButton.state == .on
        integration.customEmoji = customEmojiInput.stringValue
        integration.customStatusText = customStatusTextInput.stringValue
        PreferencesDataModel.shared.slackIntegration.accept(integration)
        ToastManager.shared.success("Saved!")
    }
}

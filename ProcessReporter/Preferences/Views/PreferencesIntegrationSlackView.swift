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

private let statusExpirationOptions = [30, 60, 120, 300]

class PreferencesIntegrationSlackView: IntegrationView {
    private lazy var enabledButton: NSButton = {
        let button = NSButton(
            checkboxWithTitle: "", target: nil, action: nil
        )

        return button
    }()

    private lazy var customEmojiInput: NSScrollTextField = {
        let textField = NSScrollTextField()
        textField.placeholderString = "Custom Emoji"

        return textField
    }()

    private lazy var statusTextTemplateStringInput: NSScrollTextField = {
        let textField = NSScrollTextField()
        textField.placeholderString = "Custom Status Text"
        return textField
    }()

    private lazy var apiKeyInput: NSScrollSecureTextField = {
        let textField = NSScrollSecureTextField()
        textField.placeholderString = "API Key"
        return textField
    }()

    private lazy var statusExpirationDropdown: NSPopUpButton = {
        let button = NSPopUpButton()
        button.addItems(withTitles: statusExpirationOptions.map { String($0) })

        return button
    }()

    private lazy var defaultEmojiInput: NSScrollTextField = {
        let textField = NSScrollTextField()
        textField.placeholderString = "Default Emoji"
        return textField
    }()

    private lazy var defaultStatusTextInput: NSScrollTextField = {
        let textField = NSScrollTextField()
        textField.placeholderString = "Default Status Text"
        return textField
    }()

    private lazy var saveButton: NSButton = {
        let button = NSButton(title: "Save", target: nil, action: nil)
        button.bezelStyle = .push
        button.keyEquivalent = "\r"
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

    override func setupUI() {
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
            leftView: NSTextField(labelWithString: "Emoji"),
            rightView: customEmojiInput
        )

        // Custom Status Text row
        createRow(
            leftView: NSTextField(labelWithString: "Status Text"),
            rightView: statusTextTemplateStringInput
        )

        // Status Expiration row
        createRow(
            leftView: NSTextField(labelWithString: "Status Expiration"),
            rightView: statusExpirationDropdown
        )

        // Default Emoji row
        createRow(
            leftView: NSTextField(labelWithString: "Default Emoji"),
            rightView: defaultEmojiInput
        )

        // Default Status Text row
        createRow(
            leftView: NSTextField(labelWithString: "Default Status Text"),
            rightView: defaultStatusTextInput
        )

        createRow(
            leftView: NSView(),
            rightView: {
                let textField = NSTextField(
                    labelWithString:
                        """
                        Template String Usage:
                        1. {media_process_name} - Current media process name
                        2. {media_name} - Current media name
                        3. {artist} - Current media artist
                        4. {media_name_artist} - Current media name and artist
                        5. {process_name} - Current process name
                        """
                )

                textField.textColor = .secondaryLabelColor
                textField.font = .systemFont(ofSize: 12)
                return textField
            }())

        // Save button row
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.addArrangedSubview(resetButton)
        buttonStack.addArrangedSubview(saveButton)
        gridView.addRow(with: [NSView(), buttonStack])
        gridView.cell(for: buttonStack)?.xPlacement = .trailing
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func synchronizeUI() {
        // Synchronize UI with data model
        let integration = PreferencesDataModel.shared.slackIntegration.value
        enabledButton.state = integration.isEnabled ? .on : .off
        customEmojiInput.stringValue = integration.customEmoji
        statusTextTemplateStringInput.stringValue = integration.statusTextTemplateString
        statusExpirationDropdown.selectItem(
            at: statusExpirationOptions.firstIndex(of: integration.expiration) ?? 0)
        defaultEmojiInput.stringValue = integration.defaultEmoji
        defaultStatusTextInput.stringValue = integration.defaultStatusText
    }

    @objc private func reset() {
        synchronizeUI()
    }

    @objc private func save() {
        var integration = PreferencesDataModel.shared.slackIntegration.value
        integration.isEnabled = enabledButton.state == .on
        integration.customEmoji = customEmojiInput.stringValue
        integration.statusTextTemplateString = statusTextTemplateStringInput.stringValue
        integration.expiration =
            statusExpirationOptions[statusExpirationDropdown.indexOfSelectedItem]
        integration.defaultEmoji = defaultEmojiInput.stringValue
        integration.defaultStatusText = defaultStatusTextInput.stringValue
        PreferencesDataModel.shared.slackIntegration.accept(integration)
        ToastManager.shared.success("Saved!")
    }

}

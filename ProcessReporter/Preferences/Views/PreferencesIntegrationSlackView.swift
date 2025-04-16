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
        textField.placeholderString = "xoxp-"
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
        let button = NSButton(title: "Save", target: self, action: #selector(save))
        button.bezelStyle = .push
        button.keyEquivalent = "\r"
        return button
    }()

    private lazy var resetButton: NSButton = {
        let button = NSButton(title: "Reset", target: self, action: #selector(reset))
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

        let text = "Go to https://api.slack.com/apps to create a new app"
        let url = "https://api.slack.com/apps"

        // 创建一个 NSMutableAttributedString 以便我们可以添加多个属性
        let attributedText = NSMutableAttributedString(string: text)

        // 设置整个文本的颜色
        attributedText.addAttribute(
            .foregroundColor,
            value: NSColor.secondaryLabelColor,
            range: NSRange(location: 0, length: text.count))

        // 找到 URL 的范围
        if let urlRange = text.range(of: url) {
            let nsRange = NSRange(urlRange, in: text)

            // 添加链接属性
            attributedText.addAttributes(
                [
                    .link: URL(string: url)!,
                    .foregroundColor: NSColor.linkColor,  // 使用系统默认的链接颜色
                ], range: nsRange)
        }

        createRowDescription(attributedText: attributedText)

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

        createRowDescription(
            text:
                """
                Template String Usage:
                1. {media_process_name}
                   - Current media process name
                2. {media_name}
                   - Current media name
                3. {artist}
                   - Current media artist
                4. {media_name_artist}
                   - Current media name and artist
                5. {process_name}
                   - Current process name
                """
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
        apiKeyInput.stringValue = integration.apiToken
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
        integration.apiToken = apiKeyInput.stringValue
        PreferencesDataModel.shared.slackIntegration.accept(integration)
        ToastManager.shared.success("Saved!")
    }

}

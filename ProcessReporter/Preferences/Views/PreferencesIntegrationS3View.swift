//
//  PreferencesIntegrationMixSpaceView.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import AppKit
import SnapKit
import SwiftUI

class PreferencesIntegrationS3View: IntegrationView {
    // Controls
    private let enabledButton = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private lazy var bucketInput: NSScrollTextField = .init()
    private lazy var regionInput: NSScrollTextField = .init()
    private lazy var accessKeyInput: NSScrollTextField = .init()
    private lazy var secretKeyInput: NSScrollSecureTextField = .init()
    private lazy var endpointInput: NSScrollTextField = .init()
    private lazy var pathInput: NSScrollTextField = .init()
    private lazy var customDomainInput: NSScrollTextField = .init()

    private lazy var testButton: NSButton = {
        let button = NSButton(
            title: "Select App & Test Upload", target: self, action: #selector(testUpload)
        )
        button.bezelStyle = .rounded
        return button
    }()

    private lazy var saveButton: NSButton = {
        let button = NSButton(title: "Save", target: self, action: #selector(save))
        button.bezelStyle = .push
        button.bezelColor = .accent
        return button
    }()

    private lazy var resetButton: NSButton = {
        let button = NSButton(title: "Reset", target: self, action: #selector(reset))
        button.bezelStyle = .rounded
        return button
    }()

    init() {
        super.init(frame: .zero)

        // Configure controls
        bucketInput.placeholderString = "Enter S3 bucket name"
        regionInput.placeholderString = "Enter region (e.g., us-east-1)"
        accessKeyInput.placeholderString = "Enter Access Key"
        secretKeyInput.placeholderString = "Enter Secret Key"
        endpointInput.placeholderString = "Custom endpoint (optional)"

        setupGridView()
        synchronizeUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func synchronizeUI() {
        // Synchronize UI with data model
        let integration = PreferencesDataModel.s3Integration.value
        enabledButton.state = integration.isEnabled ? .on : .off
        bucketInput.stringValue = integration.bucket
        regionInput.stringValue = integration.region
        accessKeyInput.stringValue = integration.accessKey
        secretKeyInput.stringValue = integration.secretKey
        endpointInput.stringValue = integration.endpoint
        customDomainInput.stringValue = integration.customDomain
    }

    @objc private func reset() {
        synchronizeUI()
    }

    @objc private func save() {
        // Save the integration settings
        var integration = PreferencesDataModel.s3Integration.value
        integration.isEnabled = enabledButton.state == .on
        integration.bucket = bucketInput.stringValue
        integration.region = regionInput.stringValue
        integration.accessKey = accessKeyInput.stringValue
        integration.secretKey = secretKeyInput.stringValue
        integration.endpoint = endpointInput.stringValue
        integration.customDomain = customDomainInput.stringValue

        PreferencesDataModel.s3Integration.accept(integration)
        ToastManager.shared.success("Saved!")
    }

    @objc private func testUpload() {
        // Create app picker view
        showAppPicker { appId, appURL in
            guard appId != nil, let appURL = appURL else {
                return  // User canceled
            }

            // Get app icon
            let appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
            if let iconData = appIcon.data {
                // Perform upload
                self.uploadIconToS3(iconData, appName: appURL.lastPathComponent)
            } else {
                ToastManager.shared.error("Failed to convert app icon to image data")
            }
        }
    }

    private func uploadIconToS3(_ imageData: Data, appName: String) {
        let config = PreferencesDataModel.s3Integration.value

        // Create S3Uploader
        let options = S3UploaderOptions(
            bucket: config.bucket,
            region: config.region,
            accessKey: config.accessKey,
            secretKey: config.secretKey,
            endpoint: config.endpoint.isEmpty ? nil : config.endpoint
        )

        let uploader = S3Uploader(options: options)

        // Upload the image
        Task {
            do {
                let url = try await uploader.uploadImage(imageData, to: "app-icons")
                DispatchQueue.main.async {
                    ToastManager.shared.success("Upload successful: \(url)")
                }
            } catch {
                DispatchQueue.main.async {
                    ToastManager.shared.error("Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showAppPicker(completion: @escaping (String?, URL?) -> Void) {
        let appPicker = AppPickerView(onSelectApp: completion)
        let hostingController = NSHostingController(rootView: appPicker)

        let popover = NSPopover()
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.show(relativeTo: testButton.bounds, of: testButton, preferredEdge: .maxY)
    }

    private func setupGridView() {
        setupUI()

        // Enabled row
        createRow(
            leftView: NSTextField(labelWithString: "Enabled"),
            rightView: enabledButton
        )

        // Bucket row
        createRow(
            leftView: NSTextField(labelWithString: "Bucket"),
            rightView: bucketInput
        )

        // Region row
        createRow(
            leftView: NSTextField(labelWithString: "Region"),
            rightView: regionInput
        )

        // Access Key row
        createRow(
            leftView: NSTextField(labelWithString: "Access Key"),
            rightView: accessKeyInput
        )

        // Secret Key row
        createRow(
            leftView: NSTextField(labelWithString: "Secret Key"),
            rightView: secretKeyInput
        )

        // Endpoint row
        createRow(
            leftView: NSTextField(labelWithString: "Custom Endpoint"),
            rightView: endpointInput
        )

        // Custom Domain row
        createRow(
            leftView: NSTextField(labelWithString: "Custom Domain"),
            rightView: customDomainInput
        )

        // Path row
        createRow(
            leftView: NSTextField(labelWithString: "Path"),
            rightView: pathInput
        )

        // Test button row
        createRow(
            leftView: NSView(),
            rightView: testButton
        )
        gridView.cell(for: testButton)?.xPlacement = .trailing

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

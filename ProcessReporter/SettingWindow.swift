//
//  SettingWindow.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//

import AppKit
import SnapKit

class SettingWindow: NSWindow, NSWindowDelegate {
    private let generalVC = PreferencesGeneralViewController()
    private let integrationVC = PreferencesIntegrationViewController()

    private let rootViewController = NSViewController()
    public static let shared = SettingWindow()

    private let defaultFrameSize: NSSize = NSSize(width: 800, height: 600)

    // UserDefaults keys for window position and size
    private let windowFrameKey = "SettingWindowFrame"

    convenience init() {
        self.init(
            contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        contentViewController = rootViewController

        rootViewController.view.frame.size = defaultFrameSize

        title = "Settings"

        // Try to restore saved position and size
        if let savedFrameData = UserDefaults.standard.data(forKey: windowFrameKey),
           let nsValue = try? NSKeyedUnarchiver.unarchivedObject(
               ofClass: NSValue.self, from: savedFrameData),
           let savedFrame = nsValue.rectValue as NSRect? {
            // Check if the saved frame is visible on any current screen
            var isOnScreen = false
            for screen in NSScreen.screens {
                if screen.frame.intersects(savedFrame) {
                    isOnScreen = true
                    break
                }
            }

            if isOnScreen {
                setFrame(savedFrame, display: true)
            } else {
                // Fallback to default center position
                setFrame(.init(origin: .zero, size: defaultFrameSize), display: true)
                centerWindowOnScreen()
            }
        } else {
            // No saved data, use default
            setFrame(.init(origin: .zero, size: defaultFrameSize), display: true)
            centerWindowOnScreen()
        }

        delegate = self

        loadView()
        switchToTab(.general)
    }

    private func centerWindowOnScreen() {
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let windowFrame = frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func loadView() {
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = .general
        toolbarStyle = .preference
        self.toolbar = toolbar
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func windowDidBecomeKey(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    func windowDidResignKey(_ notification: Notification) {
        let sender = notification.object as! NSWindow
        if !sender.isVisible {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @objc private func switchToGeneral() {
        switchToTab(.general)
    }

    @objc private func switchToIntegration() {
        switchToTab(.integration)
    }

    private func switchToTab(_ tab: TabIdentifier) {
        let vc: NSViewController

        switch tab {
        case .general: vc = generalVC
        case .integration: vc = integrationVC
        }

        // Remove existing view controllers
        for child in rootViewController.children {
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        rootViewController.addChild(vc)
        rootViewController.view.addSubview(vc.view)
        toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: tab.rawValue)
        //        NSAnimationContext.runAnimationGroup(
        //            { context in
        //                context.duration = 0.3
        //                context.allowsImplicitAnimation = true
        //
        //                window?.animator().setContentSize(
        //                    ((vc as? SettingWindowProtocol) != nil) ? (vc as! SettingWindowProtocol).frameSize : defaultFrameSize)
        //            }, completionHandler: nil)

        let targetSize =
            ((vc as? SettingWindowProtocol) != nil)
                ? (vc as! SettingWindowProtocol).frameSize : defaultFrameSize

        // FIXME: Multiple times will become ineffective.

        setFrame(
            NSRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: targetSize.width,
                height: targetSize.height
            ), display: true, animate: true)
    }

    enum TabIdentifier: String {
        case general
        case integration
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
            orderOut(nil)
        }
    }

    @objc func closeWindow() {
        orderOut(nil)
    }

    // Save window position and size when window is moved or resized
    func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }

    private func saveWindowFrame() {
        let nsValue = NSValue(rect: frame)
        let frameData = try? NSKeyedArchiver.archivedData(
            withRootObject: nsValue, requiringSecureCoding: true)
        UserDefaults.standard.set(frameData, forKey: windowFrameKey)
    }
}

extension NSToolbarItem.Identifier {
    static let general = NSToolbarItem.Identifier("general")
    static let integration = NSToolbarItem.Identifier("integration")
}

// MARK: - Toolbar Delegate

extension SettingWindow: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .integration]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarAllowedItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarAllowedItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case .general:
            item.label = "General"
            item.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "General")
            item.action = #selector(switchToGeneral)
            item.isEnabled = true

        case .integration:
            item.label = "Integration"
            item.image = NSImage(
                systemSymbolName: "puzzlepiece.extension", accessibilityDescription: "Integration")
            item.action = #selector(switchToIntegration)
            item.isEnabled = true
        default:
            return nil
        }
        item.target = self
        return item
    }
}

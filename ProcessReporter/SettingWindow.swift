//
//  SettingWindow.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/6.
//

import AppKit
import SnapKit

class SettingWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    private let generalVC = PreferencesGeneralViewController()
    private let integrationVC = PreferencesIntegrationViewController()

    private let rootViewController = NSViewController()

    public static let shared = SettingWindow()

    private let defaultFrameSize: NSSize = NSSize(width: 800, height: 600)

    public func createWindow() -> NSWindow {
        if let existingWindow = window {
            return existingWindow
        }

        rootViewController.view.frame.size = defaultFrameSize
        let window = NSWindow(contentViewController: rootViewController)
        window.styleMask = [.titled, .closable]
        window.title = "Settings"
        window.setFrame(.init(origin: .zero, size: defaultFrameSize), display: true)
        window.delegate = self

        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = window
        loadView()
        switchToTab(.general)
        return window
    }

    func loadView() {
        guard let window = window else { return }

        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = .general
        window.toolbarStyle = .preference
        window.toolbar = toolbar
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
        window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: tab.rawValue)
//        NSAnimationContext.runAnimationGroup(
//            { context in
//                context.duration = 0.3
//                context.allowsImplicitAnimation = true
//
//                window?.animator().setContentSize(
//                    ((vc as? SettingWindowProtocol) != nil) ? (vc as! SettingWindowProtocol).frameSize : defaultFrameSize)
//            }, completionHandler: nil)

        let targetSize = ((vc as? SettingWindowProtocol) != nil) ? (vc as! SettingWindowProtocol).frameSize : defaultFrameSize

        if let window = window {
            
            // FIXME: Multiple times will become ineffective.
            window.setFrame(NSRect(
                x: window.frame.origin.x,
                y: window.frame.origin.y,
                width: targetSize.width,
                height: targetSize.height
            ), display: true, animate: true)
        }
    }

    enum TabIdentifier: String {
        case general
        case integration
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

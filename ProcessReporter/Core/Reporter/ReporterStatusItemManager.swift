//
//  ReporterStatusItemManager.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/10.
//

import Cocoa
import RxCocoa
import RxSwift

class ReporterStatusItemManager: NSObject {
    private var statusItem: NSStatusItem!

    // MARK: - Items

    private var currentProcessItem: NSMenuItem!
    private var enabledItem: NSMenuItem!

    private var disposers = [Disposable]()
    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        setupStatusItem()
        setupStatusSubscription()
    }

    private func setupStatusSubscription() {
        let p = PreferencesDataModel.shared.isEnabled.subscribe { [weak self] enabled in
            guard let self = self else { return }
            self.enabledItem.state = enabled ? .on : .off
        }
        disposers.append(p)
    }

    deinit {
        for d in disposers {
            d.dispose()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStatusItem() {
        let currentProcessSectionHeader = NSMenuItem.sectionHeader(title: "Current Process")

        toggleStatusItemIcon(.ready)

        let menu = NSMenu()
        currentProcessItem = NSMenuItem(
            title: "No Process", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(currentProcessSectionHeader)
        menu.addItem(currentProcessItem)
        menu.addItem(NSMenuItem.separator())

        enabledItem = NSMenuItem(
            title: "Enabled", action: #selector(noop), keyEquivalent: "s", target: self)
        menu.addItem(enabledItem)
        menu.addItem(
            NSMenuItem(
                title: "Settings", action: #selector(showSettings), keyEquivalent: ",", target: self))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu
    }

    @objc private func noop() {}

    @objc private func toggleEnabled() {
        let isEnabled = PreferencesDataModel.shared.isEnabled.value
        PreferencesDataModel.shared.isEnabled.accept(!isEnabled)
    }

    @objc private func showSettings() {
        let window = SettingWindow.shared
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    enum StatusItemIconStatus {
        case ready
        case syncing
        case offline
        case paused
    }

    func toggleStatusItemIcon(_ status: StatusItemIconStatus) {
        guard let button = statusItem?.button else { return }
        switch status {
        case .ready:
            button.image = NSImage(
                systemSymbolName: "icloud.fill", accessibilityDescription: "Ready")
        case .offline:
            button.image = NSImage(
                systemSymbolName: "icloud.slash.fill", accessibilityDescription: "Network Error")
        case .paused:
            button.image = NSImage(
                systemSymbolName: "icloud.slash.fill", accessibilityDescription: "Paused")
        case .syncing:
            button.image = NSImage(
                systemSymbolName: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill",
                accessibilityDescription: "Syncing")
        }
    }

    func updateCurrentProcessItem(_ info: FocusedWindowInfo) {
        currentProcessItem.title = info.appName
    }
}

extension ReporterStatusItemManager: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        guard let info = ApplicationMonitor.shared.getFocusedWindowInfo() else { return }
        updateCurrentProcessItem(info)

        enabledItem.state = PreferencesDataModel.shared.isEnabled.value ? .on : .off
    }
}

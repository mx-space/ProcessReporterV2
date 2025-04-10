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

    private var enabledItem: NSMenuItem!

    private var currentProcessItem: NSMenuItem!
    private var currentMediaNameItem: NSMenuItem!
    private var currentMediaArtistItem: NSMenuItem!

    private var lastSendProcessNameItem: NSMenuItem!
    private var lastSendProcessTimeItem: NSMenuItem!

    private var disposers = [Disposable]()
    private var lastReportTime: Date?
    private var updateTimer: Timer?

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
        updateTimer?.invalidate()
        updateTimer = nil
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStatusItem() {
        toggleStatusItemIcon(.ready)

        let menu = NSMenu()
        currentProcessItem = NSMenuItem(
            title: "No Process", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(NSMenuItem.sectionHeader(title: "Current Process"))
        menu.addItem(currentProcessItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem.sectionHeader(title: "Current Media"))
        currentMediaNameItem = NSMenuItem(
            title: "No Media", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(currentMediaNameItem)
        currentMediaArtistItem = NSMenuItem(
            title: "No Artist", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(currentMediaArtistItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem.sectionHeader(title: "Last Send Process"))

        lastSendProcessNameItem = NSMenuItem(
            title: "Last Process", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendProcessNameItem)
        lastSendProcessTimeItem = NSMenuItem(
            title: "Last Time", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendProcessTimeItem)

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

        setupUpdateTimer()
    }

    private func setupUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateLastSendTimeDisplay()
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }

    private func updateLastSendTimeDisplay() {
        guard let lastTime = lastReportTime else { return }
        lastSendProcessTimeItem.title = "Updated at \(lastTime.relativeTimeDescription())"
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

    func updateCurrentMediaItem(name: String?, artist: String?) {
        currentMediaNameItem.title = name == nil ? "No Media" : name!
        currentMediaArtistItem.title = artist == nil ? "No Artist" : artist!
    }

    func updateLastSendProcessNameItem(_ info: ReportModel) {
        lastSendProcessNameItem.title = info.processName
        lastReportTime = info.timeStamp
        updateLastSendTimeDisplay()

        currentMediaNameItem.title = info.mediaName == nil ? "No Media" : info.mediaName!
        currentMediaArtistItem.title = info.artist == nil ? "No Artist" : info.artist!
    }
}

extension ReporterStatusItemManager: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        guard let info = ApplicationMonitor.shared.getFocusedWindowInfo() else { return }
        updateCurrentProcessItem(info)
        let (mediaName, artist) = getMediaInfo()
        updateCurrentMediaItem(name: mediaName, artist: artist)

        enabledItem.state = PreferencesDataModel.shared.isEnabled.value ? .on : .off
    }
}

extension Date {
    func relativeTimeDescription() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        switch interval {
        case ..<1:
            return "just now"
        case 1..<60:
            return "\(Int(interval))s ago"
        case 60..<3600:
            return "\(Int(interval / 60))m ago"
        case 3600..<86400:
            return "\(Int(interval / 3600))h ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
    }
}

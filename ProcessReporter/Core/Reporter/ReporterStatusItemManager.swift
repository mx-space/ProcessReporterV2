//
//  ReporterStatusItemManager.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/10.
//

import Cocoa
import RxCocoa
import RxSwift

@MainActor
class ReporterStatusItemManager: NSObject {
    private var statusItem: NSStatusItem!

    // MARK: - Items

    private var enabledItem: NSMenuItem!

    private var currentProcessItem: NSMenuItem!
    private var currentMediaNameItem: NSMenuItem!
    private var currentMediaArtistItem: NSMenuItem!

    private var lastSendProcessNameItem: NSMenuItem!
    private var lastSendProcessTimeItem: NSMenuItem!
    private var lastSendMediaNameItem: NSMenuItem!
    private var lastSendMediaArtistItem: NSMenuItem!

    private var lastReportTime: Date?
    private var updateTimer: Timer?

    // Action
    private var enableMediaReportButton: NSMenuItem!
    private var enableProcessReportButton: NSMenuItem!

    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        setupStatusItem()
        synchronizeUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func synchronizeUI() {
        let preferences = PreferencesDataModel.shared
        enabledItem.state = preferences.isEnabled.value ? .on : .off
        enableMediaReportButton.state = preferences.enabledTypes.value.types.contains(.media) ? .on : .off
        enableProcessReportButton.state = preferences.enabledTypes.value.types.contains(.process) ? .on : .off
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
            NSMenuItem.sectionHeader(title: "Last Send"))

        lastSendProcessNameItem = NSMenuItem(
            title: "..Last Process", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendProcessNameItem)
        lastSendMediaNameItem = NSMenuItem(
            title: "..Last Media", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendMediaNameItem)
        lastSendMediaArtistItem = NSMenuItem(
            title: "..Last Artist", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendMediaArtistItem)
        lastSendProcessTimeItem = NSMenuItem(
            title: "..Last Time", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendProcessTimeItem)

        menu.addItem(NSMenuItem.separator())

        enabledItem = NSMenuItem(
            title: "Enabled", action: #selector(noop), keyEquivalent: "s", target: self)
        menu.addItem(enabledItem)
        menu.addItem(
            NSMenuItem(
                title: "Settings", action: #selector(showSettings), keyEquivalent: ",", target: self))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem.sectionHeader(title: "Enabled Reporters"))
        enableMediaReportButton = NSMenuItem(title: "Media", action: #selector(toggleEnableMedia), keyEquivalent: "", target: self)
        enableProcessReportButton = NSMenuItem(title: "Process", action: #selector(toggleEnableProcess), keyEquivalent: "", target: self)
        menu.addItem(enableMediaReportButton)
        menu.addItem(enableProcessReportButton)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu

        setupUpdateTimer()
    }

    private func setupUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLastSendTimeDisplay()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }

    private func updateLastSendTimeDisplay() {
        guard let lastTime = lastReportTime else { return }
        lastSendProcessTimeItem.title = lastTime.relativeTimeDescription()
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
        currentProcessItem.image = {
            let icon = info.icon
            icon?.size = NSSize(width: 16, height: 16)
            return icon
        }()
    }

    func updateCurrentMediaItem(
        _ mediaInfo: MediaInfo? = nil
    ) {
        if let mediaInfo = mediaInfo, let name = mediaInfo.name {
            currentMediaNameItem.title = name
            currentMediaArtistItem.title = mediaInfo.artist ?? "No Artist"
            if let base64 = mediaInfo.image, let data = Data(base64Encoded: base64) {
                currentMediaNameItem.image = {
                    let image = NSImage(data: data)
                    image?.size = NSSize(width: 36, height: 36)

                    return image?.withRoundedCorners(radius: 6)
                }()
            }

        } else {
            currentMediaNameItem.title = "No Media"
            currentMediaArtistItem.title = "No Artist"
        }
    }

    func updateLastSendProcessNameItem(_ info: ReportModel) {
        lastSendProcessNameItem.title = info.processName
        lastReportTime = info.timeStamp
        updateLastSendTimeDisplay()

        currentMediaNameItem.title = info.mediaName == nil ? "No Media" : info.mediaName!
        currentMediaArtistItem.title = info.artist == nil ? "No Artist" : info.artist!
        lastSendMediaNameItem.title = info.mediaName == nil ? "No Media" : info.mediaName!
        lastSendMediaArtistItem.title = info.artist == nil ? "No Artist" : info.artist!
    }
}

// MARK: - Menu Delegate

extension ReporterStatusItemManager: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        synchronizeUI()
        guard let info = ApplicationMonitor.shared.getFocusedWindowInfo() else { return }
        updateCurrentProcessItem(info)

        guard let mediaInfo = getMediaInfo() else { return }
        if mediaInfo.playing {
            updateCurrentMediaItem(mediaInfo)
        }

//        #if DEBUG
//        let timer = Timer.init(timeInterval: 3, repeats: false) { _ in
//            print("Debug: Menu opened")
//            sleep(5)
//        }
//        RunLoop.main.add(timer, forMode: .common)
//        #endif
    }
    
}

// MARK: - Menu Actions

extension ReporterStatusItemManager {
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

    @objc private func toggleEnableMedia(sender: NSMenuItem) {
        let currentState = sender.state

        var snapshot = PreferencesDataModel.shared.enabledTypes.value.types
        if currentState == .on {
            snapshot.remove(.media)
        } else {
            snapshot.insert(.media)
        }
        PreferencesDataModel.shared.enabledTypes.accept(.init(types: snapshot))
    }

    @objc private func toggleEnableProcess(sender: NSMenuItem) {
        let currentState = sender.state

        var snapshot = PreferencesDataModel.shared.enabledTypes.value.types
        if currentState == .on {
            snapshot.remove(.process)
        } else {
            snapshot.insert(.process)
        }
        PreferencesDataModel.shared.enabledTypes.accept(.init(types: snapshot))
    }
}

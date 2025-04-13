//
//  ReporterStatusItemManager.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/10.
//

import Cocoa
import RxCocoa
import RxSwift
import SnapKit
import SwiftUI

@MainActor
class ReporterStatusItemManager: NSObject {
    private var statusItem: NSStatusItem!

    // MARK: - Items

    private var enabledItem: NSMenuItem!

    private var currentProcessItem: NSMenuItem!
    private var currentMediaNameItem: NSMenuItem!

    private var lastSendProcessNameItem: NSMenuItem!
    private var lastSendProcessTimeItem: NSMenuItem!
    private var lastSendMediaNameItem: NSMenuItem!

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
        enableMediaReportButton.state =
            preferences.enabledTypes.value.types.contains(.media) ? .on : .off
        enableProcessReportButton.state =
            preferences.enabledTypes.value.types.contains(.process) ? .on : .off
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

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem.sectionHeader(title: "Last Send"))

        lastSendProcessNameItem = NSMenuItem(
            title: "..Last Process", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendProcessNameItem)
        lastSendMediaNameItem = NSMenuItem(
            title: "..Last Media", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendMediaNameItem)
        lastSendProcessTimeItem = NSMenuItem(
            title: "..Last Time", action: #selector(noop), keyEquivalent: "", target: self)
        menu.addItem(lastSendProcessTimeItem)

        menu.addItem(NSMenuItem.separator())

        enabledItem = NSMenuItem(
            title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "s", target: self)
        menu.addItem(enabledItem)
        menu.addItem(
            NSMenuItem(
                title: "Settings", action: #selector(showSettings), keyEquivalent: ",", target: self))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem.sectionHeader(title: "Enabled Reporters"))
        enableMediaReportButton = NSMenuItem(
            title: "Media", action: #selector(toggleEnableMedia), keyEquivalent: "", target: self)
        enableProcessReportButton = NSMenuItem(
            title: "Process", action: #selector(toggleEnableProcess), keyEquivalent: "",
            target: self)
        menu.addItem(enableMediaReportButton)
        menu.addItem(enableProcessReportButton)

        menu.addItem(NSMenuItem.separator())

        #if DEBUG
            let debugItem = NSMenuItem(
                title: "Debug UI", action: nil, keyEquivalent: "", target: self)

            debugItem.view = DebugUICell()

            menu.addItem(debugItem)
            debugItem.view!.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(22)
            }

        #endif
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
        case partialError
        case error
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
        case .partialError:
            button.image = NSImage(
                systemSymbolName: "exclamationmark.icloud",
                accessibilityDescription: "Partial Error")
        case .error:
            button.image = NSImage(
                systemSymbolName: "exclamationmark.icloud.fill", accessibilityDescription: "Error")
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
            currentMediaNameItem.title = formatMediaName(name, mediaInfo.artist)
            if let base64 = mediaInfo.image, let data = Data(base64Encoded: base64) {
                //                let nsView = NSView()
                //                let hStack = NSStackView()
                //                hStack.orientation = .horizontal
                //                hStack.spacing = 4
                //                let imageView = NSImageView(image: NSImage(data: data)!)
                //                imageView.wantsLayer = true
                //                imageView.layer?.cornerRadius = 6
                //                imageView.layer?.masksToBounds = true
                //                imageView.snp.makeConstraints { make in
                //
                //                    make.width.height.equalTo(36)
                //                }
                //                hStack.addArrangedSubview(imageView)
                //                let vStack = NSStackView()
                //                // hStack.addArrangedSubview(
                //                //     NSTextField(labelWithString: formatMediaName(name, mediaInfo.artist)))
                //                vStack.orientation = .vertical
                //                vStack.spacing = 4
                //                vStack.addArrangedSubview(
                //                    NSTextField(labelWithString: name))
                //                vStack.addArrangedSubview(
                //                    NSTextField(labelWithString: mediaInfo.artist ?? "-"))
                //                vStack.layerContentsPlacement = .left
                //                hStack.addArrangedSubview(vStack)
                //                nsView.addSubview(hStack)
                //                currentMediaNameItem.view = nsView
                //                nsView.snp.makeConstraints { make in
                //                    make.height.equalTo(36)
                //                    make.width.equalToSuperview()
                //                }
                //                hStack.snp.makeConstraints { make in
                //                    make.horizontalEdges.equalToSuperview().offset(24)
                //                }
                let cell = NSHostingView(
                    rootView: MediaInfoCellView(
                        mediaName: name, artist: mediaInfo.artist, image: NSImage(data: data)))
                cell.wantsLayer = true
                currentMediaNameItem.view = cell
                cell.snp.makeConstraints { make in
                    make.height.equalTo(50)
                }
            }
            //     currentMediaNameItem.image = {
            //         let image = NSImage(data: data)
            //         image?.size = NSSize(width: 36, height: 36)

            //         return image?.withRoundedCorners(radius: 6)
            //     }()
            // }

        } else {
            currentMediaNameItem.title = "..No Media"
        }
    }

    func updateLastSendProcessNameItem(_ info: ReportModel) {
        lastSendProcessNameItem.title = info.processName
        lastReportTime = info.timeStamp
        updateLastSendTimeDisplay()

        lastSendMediaNameItem.title = formatMediaName(info.mediaName, info.artist)
    }

    func formatMediaName(_ mediaName: String?, _ artist: String?) -> String {
        if let mediaName = mediaName, let artist = artist {
            return "\(mediaName) - \(artist)"
        }
        return mediaName == nil ? "No Media" : mediaName!
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
        SettingWindowManager.shared.showWindow()
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

struct MediaInfoCellView: View {
    var mediaName: String?
    var artist: String?
    var image: NSImage?

    @State var hover: Bool = false
    var body: some View {
        ZStack {
            Color(NSColor.controlAccentColor).opacity(hover ? 1 : 0).clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 5)
            HStack {
                Image(nsImage: image ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    Text(mediaName ?? "No Media")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(artist ?? "-")
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.secondary)
                }.padding(.leading, 4)
                Spacer()
            }.frame(minWidth: 0, minHeight: 40).padding(.leading, 24)

        }.onHover { hover in
            self.hover = hover
        }
    }
}

#if DEBUG
    class DebugUICell: NSStackView {
        var backgroundView: NSView!
        convenience init() {
            self.init(frame: .zero)

            let stackView = self
            stackView.orientation = .horizontal
            stackView.spacing = 8
            backgroundView = NSView()
            stackView.addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview()
                make.verticalEdges.equalToSuperview()
                make.width.equalToSuperview()
            }

            backgroundView.wantsLayer = true
            backgroundView.layer?.opacity = 0
            backgroundView.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            backgroundView.layer?.cornerRadius = 4

            let debugIcon = NSImageView(
                image: NSImage(systemSymbolName: "snowflake", accessibilityDescription: "Debug UI")!
            )
            debugIcon.frame.size = NSSize(width: 16, height: 16)
            stackView.addArrangedSubview(debugIcon)
            debugIcon.snp.makeConstraints { make in
                make.left.equalTo(24)
            }
            let debugLabel = NSTextField(labelWithString: "Debug UI")

            debugLabel.isEditable = false
            stackView.addArrangedSubview(debugLabel)

            stackView.gestureRecognizers = [
                NSClickGestureRecognizer(target: self, action: #selector(debugUI))
            ]
        }

        override func awakeFromNib() {
            // 创建 NSTrackingArea
            let trackingArea = NSTrackingArea(
                rect: bounds, // 跟踪区域（这里是整个视图）
                options: [.mouseEnteredAndExited, .activeAlways], // 跟踪选项
                owner: self, // 事件处理对象
                userInfo: nil // 可选的用户信息
            )

            // 添加到视图
            addTrackingArea(trackingArea)
        }

        @objc private func debugUI() {
            let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                sleep(50)
            }
            RunLoop.main.add(timer, forMode: .common)
        }

        override func mouseEntered(with event: NSEvent) {
            backgroundView.layer?.opacity = 1
        }

        override func mouseExited(with event: NSEvent) {
            backgroundView.layer?.opacity = 0
        }
    }
#endif

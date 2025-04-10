import Cocoa
import RxSwift
import SystemConfiguration

private func isNetworkAvailable() -> Bool {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)

    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }

    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }

    return flags.contains(.reachable) && !flags.contains(.connectionRequired)
}

enum ReporterError: Error {
    case networkError(String)
    case cancelled
    case unknown(message: String, successIntegrations: [String])
}

struct ReporterOptions {
    let onSend: (_ data: ReportModel) async -> Result<Void, ReporterError>
}

class Reporter {
    private var statusItem: NSStatusItem!

    private var mapping = [String: ReporterOptions]()

    public func register(name: String, options: ReporterOptions) {
        mapping[name] = options
    }

    public func unregister(name: String) {
        mapping.removeValue(forKey: name)
    }

    public func send(data: ReportModel) async -> Result<[String], ReporterError> {
        let results = await withTaskGroup(of: (String, Result<Void, ReporterError>).self) { group in
            for (name, options) in mapping {
                group.addTask {
                    let result = await options.onSend(data)
                    return (name, result)
                }
            }

            var allResults = [(String, Result<Void, ReporterError>)]()
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }

        var successNames = [String]()
        // 检查是否所有的结果都是成功的
        let failures = results.filter {
            if case .failure = $0.1 { return true }
            if case .success = $0.1 { successNames.append($0.0) }
            return false
        }

        if failures.isEmpty {
            return .success(successNames)
        } else {
            // 如果有失败的情况，将所有失败信息组合起来
            let errorMessage =
                failures
                    .map { "\($0.0): \($0.1)" }
                    .joined(separator: ", ")
            return .failure(
                .unknown(
                    message: "Some handlers failed: \(errorMessage)", successIntegrations: successNames))
        }
    }

    private func monitor() {
        ApplicationMonitor.shared.startMouseMonitoring()
        ApplicationMonitor.shared.startWindowFocusMonitoring()
        ApplicationMonitor.shared.onWindowFocusChanged = { [unowned self] info in
            if PreferencesDataModel.shared.focusReport.value {
                self.prepareSend(appName: info.appName)
            }
        }

        toggleStatusItemIcon(.syncing)
    }

    private func prepareSend(appName: String) {
        if !isNetworkAvailable() {
            toggleStatusItemIcon(.offline)
            return
        } else {
            toggleStatusItemIcon(.syncing)
        }

        let (mediaName, artist) = getMediaInfo()

        let dataModel = ReportModel(
            processName: appName,
            artist: artist,
            mediaName: mediaName,
            integrations: [])
        Task {
            let result = await self.send(data: dataModel)
            switch result {
            case let .success(successNames):
                dataModel.integrations = successNames
            case let .failure(.unknown(_, successNames)):
                dataModel.integrations = successNames
            default:
                break
            }

            if let context = await Database.shared.ctx {
                context.insert(dataModel)
                try context.save()
            }
        }
    }

    private func dispose() {
        ApplicationMonitor.shared.stopMouseMonitoring()
        ApplicationMonitor.shared.stopWindowFocusMonitoring()

        toggleStatusItemIcon(.paused)
    }

    private var disposers: [Disposable] = []
    private var timer: Timer?
    private func setupTimer() {
        disposeTimer()

        let interval = PreferencesDataModel.shared.sendInterval.value
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval.rawValue), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let info = ApplicationMonitor.shared.getFocusedWindowInfo() {
                self.prepareSend(appName: info.appName)
            }
        }
    }

    private func disposeTimer() {
        timer?.invalidate()
    }

    init() {
        setupStatusItem()

        let preferences = PreferencesDataModel.shared

        let d1 = preferences.isEnabled.subscribe { [weak self] enabled in
            guard let self = self else { return }
            if enabled {
                self.monitor()
            } else {
                self.dispose()
                self.disposeTimer()
            }
        }

        let d2 = preferences.mixSpaceIntegration.subscribe { event in
            guard let config = event.element else { return }
            if config.isEnabled {
                self.registerMixSpace()
            } else {
                self.unregisterMixSpace()
            }
        }

        let d3 = preferences.sendInterval.subscribe { [weak self] _ in
            guard let self = self else { return }
            if preferences.isEnabled.value {
                self.setupTimer()
            } else {
                self.disposeTimer()
            }
        }

        disposers.append(contentsOf: [d1, d2, d3])
    }

    deinit {
        for disposer in disposers {
            disposer.dispose()
        }
    }
}

extension Reporter {
    private func getMediaInfo() -> (mediaName: String?, artist: String?) {
        // Get media information using NowPlaying
        let argv = ["nowplaying", "get", "title", "artist"]
        let argc = Int32(argv.count)
        let cStrings = argv.map { strdup($0) }
        var cStringArray = cStrings.map { UnsafeMutablePointer<Int8>($0) }

        let mediaInfo = NowPlaying.processCommand(withArgc: argc, argv: &cStringArray)

        // Clean up allocated memory
        cStrings.forEach { free($0) }
        var mediaName: String?
        var artist: String?
        if let components = mediaInfo?.components(separatedBy: "\n") {
            mediaName = components.count > 0 ? components[0] : nil
            artist = components.count > 1 ? components[1] : nil
        }

        return (mediaName, artist)
    }
}

// MARK: - App Menu Item

extension Reporter {
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        toggleStatusItemIcon(.ready)

        let menu = NSMenu()

        menu.addItem(
            NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func showSettings() {
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
            button.image = NSImage(systemSymbolName: "icloud.fill", accessibilityDescription: "Ready")
        case .offline:
            button.image = NSImage(systemSymbolName: "icloud.slash.fill", accessibilityDescription: "Network Error")
        case .paused:
            button.image = NSImage(systemSymbolName: "icloud.slash.fill", accessibilityDescription: "Paused")
        case .syncing:
            button.image = NSImage(systemSymbolName: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill", accessibilityDescription: "Syncing")
        }
    }
}

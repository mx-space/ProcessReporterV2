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

@MainActor
class Reporter {
    private var mapping = [String: ReporterOptions]()
    private var statusItemManager = ReporterStatusItemManager()

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

        statusItemManager.toggleStatusItemIcon(.syncing)
    }

    private func prepareSend(appName: String) {
        if !isNetworkAvailable() {
            statusItemManager.toggleStatusItemIcon(.offline)
            return
        } else {
            statusItemManager.toggleStatusItemIcon(.syncing)
        }

        let (mediaName, artist) = getMediaInfo()

        let dataModel = ReportModel(
            processName: appName,
            artist: artist,
            mediaName: mediaName,
            integrations: [])
        
        statusItemManager.updateCurrentMediaItem(name: dataModel.mediaName, artist: dataModel.artist)
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

            let partiallySuccess = dataModel.integrations.count > 0

            if partiallySuccess {
                statusItemManager.updateLastSendProcessNameItem(dataModel)
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

        statusItemManager.toggleStatusItemIcon(.paused)
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
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func disposeTimer() {
        timer?.invalidate()
    }

    init() {
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

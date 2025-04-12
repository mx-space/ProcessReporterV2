import Cocoa
import RxSwift

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
        let enabledTypes = PreferencesDataModel.shared.enabledTypes.value.types
        if enabledTypes.isEmpty {
            statusItemManager.toggleStatusItemIcon(.paused)
            return
        }
        if !isNetworkAvailable() {
            statusItemManager.toggleStatusItemIcon(.offline)
            return
        } else {
            statusItemManager.toggleStatusItemIcon(.syncing)
        }

        let mediaInfo = getMediaInfo()

        let dataModel = ReportModel(
            processName: "",
            integrations: [],
            mediaInfo: mediaInfo)

        let shouldIgnoreArtistNull = PreferencesDataModel.shared.ignoreNullArtist.value
        if enabledTypes.contains(.media), let mediaInfo = mediaInfo, mediaInfo.playing {
            if !shouldIgnoreArtistNull || (mediaInfo.artist != nil && !mediaInfo.artist!.isEmpty) {
                dataModel.mediaName = mediaInfo.name
                dataModel.artist = mediaInfo.artist
            }
        }
        if enabledTypes.contains(.process) {
            dataModel.processName = appName
        }
        if let mediaInfo = mediaInfo, mediaInfo.playing {
            statusItemManager.updateCurrentMediaItem(mediaInfo)
        }

        Task { @MainActor in
            let result = await self.send(data: dataModel)
            var isAllSuccess = false
            var isAllFailed = false
            switch result {
            case let .success(successNames):
                dataModel.integrations = successNames
                isAllSuccess = true
            case let .failure(.unknown(_, successNames)):
                dataModel.integrations = successNames
                isAllFailed = dataModel.integrations.isEmpty
            default:
                break
            }

            let partiallySuccess = dataModel.integrations.count > 0

            if partiallySuccess {
                statusItemManager.updateLastSendProcessNameItem(dataModel)
            }
            if isAllFailed {
                statusItemManager.toggleStatusItemIcon(.error)
            }

            if !isAllFailed && !isAllSuccess {
                statusItemManager.toggleStatusItemIcon(.partialError)
            }

            if let context = Database.shared.ctx {
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
            Task { @MainActor in
                guard let self = self else { return }
                if let info = ApplicationMonitor.shared.getFocusedWindowInfo() {
                    self.prepareSend(appName: info.appName)
                }
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

        if preferences.isEnabled.value {
            if let appName = ApplicationMonitor.shared.getFocusedWindowInfo()?.appName {
                prepareSend(appName: appName)
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

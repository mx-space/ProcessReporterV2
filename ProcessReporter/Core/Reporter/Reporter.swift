import RxSwift

enum ReporterError: Error {
    case networkError(String)
    case cancelled
    case unknown(message: String, successIntegrations: [String])
}

struct ReporterOptions {
    let onSend: (_ data: ReportModel) async -> Result<Void, ReporterError>
}

class Reporter {
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
        ApplicationMonitor.shared.onWindowFocusChanged = { info in
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

            let dataModel = ReportModel(
                processName: info.appName,
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

                if let context =  await Database.shared.ctx {
                    context.insert(dataModel)
                    try context.save()
                }
            }
        }
        //        ApplicationMonitor.shared.onMouseClicked = { }
    }

    private func dispose() {
        ApplicationMonitor.shared.stopMouseMonitoring()
        ApplicationMonitor.shared.stopWindowFocusMonitoring()
    }

    private var disposers: [Disposable] = []

    init() {
        let preferences = PreferencesDataModel.shared
        let d1 = preferences.isEnabled.subscribe { [weak self] enabled in
            guard let self = self else { return }
            if enabled {
                self.monitor()
            } else {
                self.dispose()
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

        disposers.append(contentsOf: [d1, d2])
    }

    deinit {
        for disposer in disposers {
            disposer.dispose()
        }
    }
}

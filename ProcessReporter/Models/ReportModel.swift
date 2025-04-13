//
//  ReportModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//
import Cocoa
import Foundation
import Frostflake
import SwiftData

@Model
class ReportModel {
    @Attribute(.unique)
    var id: UInt64

    var processName: String
    var timeStamp: Date

    // MARK: - Media Info

    var artist: String?
    var mediaName: String?
    var mediaProcessName: String?
    var mediaDuration: Double?
    var mediaElapsedTime: Double?

    @Transient
    var mediaImage: NSImage?
    @Transient
    var mediaInfoRaw: MediaInfo?

    // 持久化字段：存储 JSON 字符串
    @Attribute
    private var integrationsRaw: String

    // 外部使用的 [String] 接口
    var integrations: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(self.integrationsRaw.utf8))) ?? []
        }
        set {
            self.integrationsRaw =
                (try? JSONEncoder().encode(newValue)).flatMap { String(data: $0, encoding: .utf8) }
                    ?? "[]"
        }
    }

    func setMediaInfo(_ mediaInfo: MediaInfo) {
        self.artist = mediaInfo.artist
        self.mediaName = mediaInfo.name
        self.mediaProcessName = mediaInfo.processName
        self.mediaDuration = mediaInfo.duration
        self.mediaElapsedTime = mediaInfo.elapsedTime
        if let base64 = mediaInfo.image, let data = Data(base64Encoded: base64) {
            self.mediaImage = NSImage(data: data)
        }
        self.mediaInfoRaw = mediaInfo
    }

    init(
        processName: String,
        integrations: [String],
        mediaInfo: MediaInfo?
    ) {
        self.id = Frostflake.generate().rawValue
        self.processName = processName
        self.timeStamp = .now
        self.integrationsRaw =
            (try? JSONEncoder().encode(integrations)).flatMap { String(data: $0, encoding: .utf8) }
                ?? "[]"
        self.mediaInfoRaw = mediaInfo

        if let mediaInfo = mediaInfo {
            self.setMediaInfo(mediaInfo)
        }
    }
}

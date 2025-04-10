//
//  ReportModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//
import Foundation
import Frostflake
import SwiftData

@Model
class ReportModel {
    @Attribute(.unique)
    var id: UInt64

    var processName: String
    var timeStamp: Date
    var artist: String?
    var mediaName: String?

    // 持久化字段：存储 JSON 字符串
    @Attribute
    private var integrationsRaw: String

    // 外部使用的 [String] 接口
    var integrations: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(integrationsRaw.utf8))) ?? []
        }
        set {
            integrationsRaw = (try? JSONEncoder().encode(newValue)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
    }

    init(processName: String, artist: String?, mediaName: String?, integrations: [String]) {
        id = Frostflake.generate().rawValue
        self.processName = processName
        self.timeStamp = .now
        self.artist = artist
        self.mediaName = mediaName
        self.integrationsRaw = (try? JSONEncoder().encode(integrations)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }
}

//
//  ReportModel.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//
import Foundation
import SwiftData
import Frostflake

@Model
class ReportModel {
    @Attribute(.unique)
    var id: UInt64

    var processName: String
    var timeStamp: Date
    var artist: String?
    var mediaName: String?
    
    init(processName: String, timeStamp: Date, artist: String?, mediaName: String?) {
        self.id = Frostflake.generate().rawValue
        self.processName = processName
        self.timeStamp = timeStamp
        self.artist = artist
        self.mediaName = mediaName
    }
}

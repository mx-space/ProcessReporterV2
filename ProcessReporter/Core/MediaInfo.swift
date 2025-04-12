//
//  MediaInfo.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/11.
//

struct MediaInfo {
    let name: String?
    let artist: String?
    let album: String?
    let image: String?
    let duration: Double
    let elapsedTime: Double
    let processID: Int
    let processName: String
    let executablePath: String
    let playing: Bool
}

func getMediaInfo() -> MediaInfo? {
    if let nowPlayingInfo = NowPlaying.getInfo() {
        let name = nowPlayingInfo["name"] as? String
        let artist = nowPlayingInfo["artist"] as? String
        let elapsedTime = nowPlayingInfo["elapsedTime"] as? Double ?? 0
        let duration = nowPlayingInfo["duration"] as? Double ?? 0
        let processID = nowPlayingInfo["processID"] as? Int ?? 0
        let processName = nowPlayingInfo["processName"] as? String ?? ""
        let executablePath = nowPlayingInfo["executablePath"] as? String ?? ""
        let artworkData = nowPlayingInfo["artworkData"] as? String ?? ""
        let playing = nowPlayingInfo["isPlaying"] as? Bool ?? false
        let album = nowPlayingInfo["album"] as? String ?? ""

        return MediaInfo(
            name: name, artist: artist, album: album, image: artworkData, duration: duration,
            elapsedTime: elapsedTime, processID: processID, processName: processName,
            executablePath: executablePath, playing: playing)
    }
    return nil
}

//
//  MediaInfo.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/11.
//

func getMediaInfo() -> (mediaName: String?, artist: String?) {
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

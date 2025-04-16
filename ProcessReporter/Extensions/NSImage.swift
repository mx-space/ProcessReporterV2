//
//  NSImage.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/12.
//

import AppKit
import CoreGraphics

extension NSImage {
    func withRoundedCorners(radius: CGFloat) -> NSImage? {
        let newSize = size
        let roundedImage = NSImage(size: newSize)

        roundedImage.lockFocus()
        let rect = NSRect(origin: .zero, size: newSize)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()
        draw(in: rect)
        roundedImage.unlockFocus()

        return roundedImage
    }

    var data: Data? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = size
        return rep.representation(using: .png, properties: [:])
    }

    convenience init?(data: Data, size: CGSize) {
        self.init(data: data)
        self.size = size
    }
}

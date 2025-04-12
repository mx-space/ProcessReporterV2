//
//  NSImage.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/12.
//

import AppKit

extension NSImage {
    func withRoundedCorners(radius: CGFloat) -> NSImage? {
        let newSize = self.size
        let roundedImage = NSImage(size: newSize)

        roundedImage.lockFocus()
        let rect = NSRect(origin: .zero, size: newSize)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()
        self.draw(in: rect)
        roundedImage.unlockFocus()

        return roundedImage
    }
}

//
//  NSRect+axPosition.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Cocoa

extension NSRect {
    public func axPosition(
        on screen: NSScreen
    ) -> CGPoint {
        let rect = self
        guard let desktopTopY = NSScreen.screens.map(\.frame.maxY).max() else {
            return rect.origin
        }
        
        let appKitTop = rect.maxY
        
        let axY = desktopTopY - appKitTop
        
        return CGPoint(x: rect.origin.x, y: axY)
    }
}

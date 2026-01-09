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
        guard let primaryScreenHeight = NSScreen.screens.first?.frame.height else {
            return rect.origin
        }
        
        let appKitTop = rect.maxY
        
        let axY = primaryScreenHeight - appKitTop
        
        return CGPoint(x: rect.origin.x, y: axY)
    }
}

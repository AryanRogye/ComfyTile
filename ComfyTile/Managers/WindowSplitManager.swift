//
//  WindowSplitManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/7/26.
//

import ComfyLogger

extension ComfyLogger {
    public static let WindowSplitManager = ComfyLogger.Name("WindowSplitManager")
}

enum WindowSplitStyle {
    case primaryLeftStackedHorizontally
    case primaryRightStackedHorizontally
}

class WindowSplitManager {
    
    var lastStartingPrimary : Int = -1
    
    enum SplitDirection {
        case left
        case right
    }
    
    func splitWindows(window: [FetchedWindow], style: WindowSplitStyle) async {
        ComfyLogger.WindowSplitManager.insert("Called Split In Space: \(window.count)")
        switch style {
        case .primaryLeftStackedHorizontally:
            guard let primary = await createPrimarySplit(on: window, direction: .left) else { return }
            if window.count == 1 { return }
            /// Primary left so stacked right
            await calculateAndSetStacked(on: window, direction: .right, avoid: primary)
            
        case .primaryRightStackedHorizontally:
            guard let primary = await createPrimarySplit(on: window, direction: .right) else { return }
            if window.count == 1 { return }
            /// Primary left so stacked right
            await calculateAndSetStacked(on: window, direction: .left, avoid: primary)
        }
    }
    
    /// Calculate Horizontal Split Going Down
    /// Direction is if placing on left or right
    private func calculateAndSetStacked(on window: [FetchedWindow], direction: SplitDirection, avoid avoidRect: CGRect) async {
        if window.isEmpty {
            print("Window is Empty")
            return
        }
        guard let screen = WindowManagerHelpers.screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return
        }
        
        let n = window.count
        let primaryIndex = lastStartingPrimary
        let windows = (1..<n).map { window[(primaryIndex + $0) % n] }

        guard !windows.isEmpty else { return }
        
        let count = windows.count
        let frame = screen.visibleFrame
        
        /// height of each frame split by count
        let height = frame.height / CGFloat(count)
        
        /// Difference in primary and this one
        let width = frame.width - avoidRect.width
        
        let x: CGFloat = (direction == .right) ? avoidRect.maxX : frame.origin.x
        var y: CGFloat = frame.origin.y
        
        for w in windows {
            w.focusWindow()
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

            guard let foc = WindowManagerHelpers.getFocusedWindow() else { continue }
            
            let pos = WindowManagerHelpers.axPosition(for: NSRect(x: x, y: y, width: width, height: height), on: screen)
            
            foc.element.setPosition(x: pos.x, y: pos.y)
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

            foc.element.setSize(width: width, height: height)

            y += height
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            ComfyLogger.WindowSplitManager.insert(
                "\(w.bundleIdentifier) (Size) (Postion) Requested: (width: \(width), height: \(height))|(x: \(x), y: \(y))"
            )
            let appliedRect = foc.element.frame
            let appliedPos = WindowManagerHelpers.axPosition(for: appliedRect, on: screen)
            
            ComfyLogger.WindowSplitManager.insert(
                "\(w.bundleIdentifier) Applied  : (width: \(appliedRect.width), height: \(appliedRect.height)) | (x: \(appliedPos.x), y: \(appliedPos.y))"
            )
        }
    }
    
    private func createPrimarySplit(on window: [FetchedWindow], direction: SplitDirection) async -> CGRect? {
        if window.isEmpty {
            print("Window is Empty")
            return nil
        }
        guard let screen = WindowManagerHelpers.screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return nil
        }
        

        lastStartingPrimary = (lastStartingPrimary + 1) % window.count

        
        /// Primary Split is Half of Screen or Best it can be After Half
        let screenFrame = screen.visibleFrame
        
        /// if 1 window only, force that to be the full screen
        let newWidth : CGFloat = window.count == 1 ? screenFrame.width : screenFrame.width / 2
        let newHeight : CGFloat = screenFrame.height
        
        let newX : CGFloat = direction == .left ? screenFrame.origin.x : screenFrame.origin.x + screenFrame.width / 2
        let newY : CGFloat = screenFrame.origin.y
        
        /// Create a rect
        let rect = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)
        let pos = WindowManagerHelpers.axPosition(for: rect, on: screen)
        
        let primary = window[lastStartingPrimary]
        /// Focus
        primary.focusWindow()
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        /// Get Better Details When Focused
        guard let foc = WindowManagerHelpers.getFocusedWindow() else { return nil }

        foc.element.setPosition(x: pos.x, y: pos.y)
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        foc.element.setSize(width: rect.width, height: rect.height)
    
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        if direction == .left {
            return foc.element.frame
        } else {
            
            let applied = foc.element.frame
            let appliedWidth = applied.width
            
            // Build rect in screen coords (NOT using applied.origin!)
            let targetRect = CGRect(
                x: screenFrame.maxX - appliedWidth,   // anchor to right edge
                y: screenFrame.origin.y,
                width: appliedWidth,
                height: screenFrame.height
            )
            
            let targetPos = WindowManagerHelpers.axPosition(for: targetRect, on: screen)
            
            // Apply
            foc.element.setPosition(x: targetPos.x, y: targetPos.y)
            foc.element.setSize(width: targetRect.width, height: targetRect.height)
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            return foc.element.frame
            
        }
    }
}


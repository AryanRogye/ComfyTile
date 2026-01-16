//
//  WindowLayoutService.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import ComfyLogger
import Cocoa

extension ComfyLogger {
    public static let WindowSplitManager = ComfyLogger.Name("WindowSplitManager")
}

final class WindowLayoutService: WindowLayoutProviding {
    
    /// Needed for anything window related
    let windowCore : WindowCore
    
    /// Last index we used
    var lastStartingPrimary : Int = -1
    
    enum SplitDirection {
        case left
        case right
    }

    init(windowCore: WindowCore) {
        self.windowCore = windowCore
    }
    
    // MARK: - Primary Layout
    public func primaryLayout(window: [ComfyWindow]) async {
        await primaryOnlySplit(on: window)
    }
    
    // MARK: - primaryLeftStackedHorizontally
    public func primaryLeftStackedHorizontally(window: [ComfyWindow]) async {
        let (foc, primary) = await createPrimarySplit(on: window, direction: .left)
        
        guard let primary, let foc else { return }
        if window.count == 1 { return }
        /// Primary left so stacked right
        await calculateAndSetStacked(on: window, direction: .right, avoid: foc.element.frame)
        if let id = primary.windowID {
            WindowServerBridge.shared.focusApp(
                forUserWindowID: id,
                pid: primary.pid,
                element: primary.element.element
            )
        }
    }
    
    public func primaryRightStackedHorizontally(window: [ComfyWindow]) async {
        let (foc, primary) = await createPrimarySplit(on: window, direction: .right)
        guard let primary, let foc else { return }
        if window.count == 1 { return }
        /// Primary left so stacked right
        await calculateAndSetStacked(on: window, direction: .left, avoid: foc.element.frame)
        if let id = primary.windowID {
            WindowServerBridge.shared.focusApp(
                forUserWindowID: id,
                pid: primary.pid,
                element: primary.element.element
            )
        }
    }
}

extension WindowLayoutService {
    internal func primaryOnlySplit(on window: [ComfyWindow]) async {
        if window.isEmpty {
            print("Window is Empty")
            return
        }
        guard let screen = WindowCore.screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return
        }
        
        if window.count == 1 {
            lastStartingPrimary = (lastStartingPrimary + 1) % window.count
        } else {
            lastStartingPrimary = (lastStartingPrimary + 1) % window.count
        }
        
        let frame = screen.visibleFrame
        let pos = frame.axPosition(on: screen)
        
        let primary = window[lastStartingPrimary]
        
        primary.focusWindow()
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        guard let foc = windowCore.getFocusedWindow() else { return }
        
        foc.element.setPosition(x: pos.x, y: pos.y)
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        foc.element.setSize(width: frame.width, height: frame.height)
    }
    
    private func createPrimarySplit(on window: [ComfyWindow], direction: SplitDirection) async -> (ComfyWindow?, ComfyWindow?) {
        if window.isEmpty {
            print("Window is Empty")
            return (nil, nil)
        }
        guard let screen = WindowCore.screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return (nil, nil)
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
        let pos = rect.axPosition(on: screen)
        
        let primary = window[lastStartingPrimary]
        /// Focus
        primary.focusWindow()
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        /// Get Better Details When Focused
        guard let foc = windowCore.getFocusedWindow() else { return (nil, nil) }
        
        foc.element.setPosition(x: pos.x, y: pos.y)
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        foc.element.setSize(width: rect.width, height: rect.height)
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        if direction == .left {
            return (foc, primary)
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
            
            let targetPos = targetRect.axPosition(on: screen)
            
            // Apply
            foc.element.setPosition(x: targetPos.x, y: targetPos.y)
            foc.element.setSize(width: targetRect.width, height: targetRect.height)
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            return (foc, primary)
            
        }
    }
    
    /// Calculate Horizontal Split Going Down
    /// Direction is if placing on left or right
    private func calculateAndSetStacked(on window: [ComfyWindow], direction: SplitDirection, avoid avoidRect: CGRect) async {
        if window.isEmpty {
            print("Window is Empty")
            return
        }
        guard let screen = WindowCore.screenUnderMouse() else {
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
            
            guard let foc = windowCore.getFocusedWindow() else { continue }
            
            let rect = NSRect(x: x, y: y, width: width, height: height)
            let pos = rect.axPosition(on: screen)
            
            foc.element.setPosition(x: pos.x, y: pos.y)
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            foc.element.setSize(width: width, height: height)
            
            y += height
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            ComfyLogger.WindowSplitManager.insert(
                "\(w.bundleIdentifier, default: "Nil") (Size) (Postion) Requested: (width: \(width), height: \(height))|(x: \(x), y: \(y))"
            )
            let appliedRect = foc.element.frame
            let appliedPos = appliedRect.axPosition(on: screen)
            
            ComfyLogger.WindowSplitManager.insert(
                "\(w.bundleIdentifier, default: "Nil") Applied  : (width: \(appliedRect.width), height: \(appliedRect.height)) | (x: \(appliedPos.x), y: \(appliedPos.y))"
            )
        }
    }
}

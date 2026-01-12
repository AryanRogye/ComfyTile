//
//  WindowManagerHelpers.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import Cocoa
import ScreenCaptureKit
import ApplicationServices
import CoreGraphics

@MainActor
struct WindowManagerHelpers {
    
    static let ignore_list = [
        "com.aryanrogye.ComfyTile"
    ]
        
    /// Find the focused window and the screen under your mouse.
    ///
    /// - Returns: `FocusedWindow` if both the screen and focused window are found.
    ///   Otherwise returns `nil` and logs why.
    public static func getFocusedWindow() -> UserWindow? {
        
        // If we can't get the screen under the mouse, stop.
        guard let screen = screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return nil
        }
        
        // Get the frontmost app.
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        guard let bundle = app.bundleIdentifier else { return nil }
        let pid = app.processIdentifier
        
        if ignore_list.contains(bundle) { return nil }
        
        let appElement = AXUIElementCreateApplication(pid)
        
        // Ask Accessibility for the app's focused window.
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        // If that fails, stop.
        if result != .success {
            print("❌ Failed to get focused window: \(result)")
            return nil
        }
        
        let windowElement = focusedWindow as! AXUIElement
        let element = WindowElement(element: windowElement)
        return UserWindow(
            windowID: element.cgWindowID,
            windowTitle: element.title,
            element: element,
            screen: screen,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            /// Most Likely Focused will always be in space
            isInSpace: true
        )
    }
    
    public static func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(loc, $0.frame, false) }
    }    
}

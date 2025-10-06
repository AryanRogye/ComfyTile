//
//  WindowManagerHelpers.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import Cocoa

struct WindowManagerHelpers {
    
    struct FocusedWindow {
        var element: AXUIElement
        var screen: NSScreen
    }
    
    /// Find the focused window and the screen under your mouse.
    ///
    /// - Returns: `FocusedWindow` if both the screen and focused window are found.
    ///   Otherwise returns `nil` and logs why.
    public static func getFocusedWindow() -> FocusedWindow? {
        
        // If we can't get the screen under the mouse, stop.
        guard let screen = screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return nil
        }
        
        // Get the frontmost app.
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        let pid = app.processIdentifier
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
        return FocusedWindow(element: windowElement, screen: screen)
    }
    
    public static func windowFrame(_ element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        
        let posResult = AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        )
        
        let sizeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            &sizeValue
        )
        
        if posResult != .success || sizeResult != .success {
            print("❌ Failed to get window position or size")
            return nil
        }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        if let posVal = positionValue, AXValueGetType(posVal as! AXValue) == .cgPoint {
            AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        } else {
            print("❌ Position value is not of type CGPoint")
            return nil
        }
        
        if let sizeVal = sizeValue, AXValueGetType(sizeVal as! AXValue) == .cgSize {
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
        } else {
            print("❌ Size value is not of type CGSize")
            return nil
        }
        
        return CGRect(origin: position, size: size)
    }
    
    
    public static func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(loc, $0.frame, false) }
    }
    
    
    public static func setWindowSize(_ element: AXUIElement, size: CGSize) {
        var mutableSize = size
        guard let axValue = AXValueCreate(.cgSize, &mutableSize) else {
            print("❌ Failed to create AXValue for size")
            return
        }
        
        let result = AXUIElementSetAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            axValue
        )
        
        if result != .success {
            print("❌ Failed to set window size: \(result)")
        }
    }
    
    public static func setWindowPosition(_ element: AXUIElement, position: CGPoint) {
        var mutablePosition = position
        guard let axValue = AXValueCreate(.cgPoint, &mutablePosition) else {
            print("❌ Failed to create AXValue for position")
            return
        }
        
        let result = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, axValue)
        if result == AXError.success {
            // Success - no need to log
        } else {
            print("❌ Failed to set window position: \(result)")
        }
    }
    
    public static func getMenuBarHeight() -> CGFloat {
        if let screen = Self.screenUnderMouse() {
            let safeAreaInsets = screen.safeAreaInsets
            let calculatedHeight = safeAreaInsets.top
            
            /// Only return calculated height if it is greater than 0
            if calculatedHeight > 0 {
                return calculatedHeight
            }
        }
        
        /// If no screen is selected or height is 0, return fallback height
        let fallbackHeight = getMenuBarHeight()
        /// Make sure fallback height is greater than 0 or go to the fallback 40
        return fallbackHeight > 0 ? fallbackHeight : 40
    }
    
    // MARK: - Private Helpers
    private static func getMenuBarHeight(for screen: NSScreen? = NSScreen.main) -> CGFloat {
        guard let screen = screen else { return 0 }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // The difference between the full screen height and the visible height
        // is the menu bar height (plus maybe the dock if it's on top).
        return screenFrame.height - visibleFrame.height
    }
    
}

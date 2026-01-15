//
//  WindowCore.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import Foundation
import ScreenCaptureKit

@Observable
@MainActor
public final class WindowCore {
    public var windows: [ComfyWindow] = []
    private var elements: [CGWindowID: WindowElement] = [:]
    
    public init() {
        
    }
    
    @ObservationIgnored
    static let ignore_list = [
        "com.aryanrogye.ComfyTile"
    ]
    
    public func loadWindows() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
            let allOnScreenWindows = content.windows
            var userWindows: [ComfyWindow] = []
            
            /// Loop Through all screens for windows
            for window in allOnScreenWindows {
                if let window = await ComfyWindow(window: window) {
                    userWindows.append(window)
                }
            }
            
            
            // fast lookup of the newest snapshot by windowID
            let newByID = Dictionary(uniqueKeysWithValues: userWindows.map { ($0.windowID, $0) })
            
            var merged: [ComfyWindow] = []
            merged.reserveCapacity(userWindows.count)
            
            // 1) keep current (rearranged) order, but replace each element with the fresh snapshot
            for old in userWindows {
                if let updated = newByID[old.windowID] {
                    merged.append(updated)
                }
            }
            
            // 2) append brand new windows that weren't already in your list
            let existingIDs = Set(merged.map { $0.windowID })
            for w in userWindows where !existingIDs.contains(w.windowID) {
                merged.append(w)
            }
            
            self.windows = merged
        } catch {
            
        }
    }
    
    public func getFocusedWindow() -> ComfyWindow? {
        // If we can't get the screen under the mouse, stop.
        guard let screen = Self.screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return nil
        }
        
        // Get the frontmost app.
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        guard let bundle = app.bundleIdentifier else { return nil }
        let pid = app.processIdentifier
        
        if Self.ignore_list.contains(bundle) { return nil }
        
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
        return ComfyWindow(
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
        return NSScreen.screens.first {
            NSMouseInRect(loc, $0.frame, false)
        }
    }
}

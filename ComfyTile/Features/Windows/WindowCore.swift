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
    private var elementCache: [CGWindowID: WindowElement] = [:]
    
    public init() {
        Task {
            await self.loadWindows()
            
            for (k, e) in elementCache {
                print("\(k) -> \(e)")
            }
        }
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
                    if let _ = window.element.element, let windowID = window.windowID {
                        elementCache[windowID] = window.element
                    }
                    
                    /// if element is nil but id is not nil we can check our cache
                    if let windowID = window.windowID,
                       window.element.element == nil {
                        /// we have a WindowElement right here
                        if let element = elementCache[windowID] {
                            window.element = element
                        }
                    }
                    userWindows.append(window)
                }
            }
            
            // fast lookup of the newest snapshot by windowID
            let newByID = Dictionary(uniqueKeysWithValues: userWindows.map { ($0.windowID, $0) })
            
            var merged: [ComfyWindow] = []
            merged.reserveCapacity(userWindows.count)
            
            // 1) preserve previous order (self.windows), refreshing data when present
            var seen = Set<String>()
            seen.reserveCapacity(userWindows.count)
            
            for old in self.windows {
                if let updated = newByID[old.windowID] {
                    merged.append(updated)
                    seen.insert(old.id)
                }
            }
            
            // 2) append any brand-new windows (order = snapshot order for new ones)
            for w in userWindows where !seen.contains(w.id) {
                merged.append(w)
                seen.insert(w.id)
            }
            
            self.windows = merged
            
            self.windows.forEach {
                if $0.windowID == nil {
                    print("A WINDOW ID IS NIL FOR: \($0.bundleIdentifier, default: "Untitled")")
                }
            }
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
            app: app,
            windowID: element.cgWindowID,
            windowTitle: element.title ?? "Unamed",
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

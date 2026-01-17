//
//  ComfyWindow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import Cocoa
import ScreenCaptureKit

@MainActor
public final class ComfyWindow {
    
    public var id: String {
        if let wid = windowID {
            return "\(pid):\(wid)"
        }
        
        // UI-only fallback: title + frame fingerprint (stable-ish)
        let fx = Int(element.frame.origin.x.rounded())
        let fy = Int(element.frame.origin.y.rounded())
        let fw = Int(element.frame.size.width.rounded())
        let fh = Int(element.frame.size.height.rounded())
        
        return "\(pid):\(windowTitle):\(fx),\(fy),\(fw),\(fh)"
    }
    
    public let windowID : CGWindowID?
    public let windowTitle : String
    
    public let app: NSRunningApplication
    
    /// More stronger element
    public var element: WindowElement
    public var screen: NSScreen?
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let screenshot : CGImage?
    public var isInSpace  : Bool
    
    public func focusWindow() {
        if let id = windowID {
            WindowServerBridge.shared.focusApp(
                forUserWindowID: id,
                pid: pid,
                element: element.element,
                app: app
            )
        }
    }
    
    init?(
        window: SCWindow
    ) async {
        guard let app = window.owningApplication,
              window.windowLayer == 0,
              window.frame.size.width > 100
        else {
            // Skip junk like "Cursor", "Menubar", etc.
            return nil
        }
        
        /// Get Window Information
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionIncludingWindow], window.windowID) as? [[String: Any]],
              let firstWindow = windowInfo.first,
              let windowTitle = firstWindow["kCGWindowName"] as? String,
              let pid = firstWindow["kCGWindowOwnerPID"] as? pid_t
        else { return nil }
        
        /// Get AXElement, Doesnt matter if nil
        let axElement : AXUIElement? = WindowServerBridge.shared.findMatchingAXWindow(pid: pid, targetWindowID: window.windowID)
        
        if let axElement {
            print("""
                        AX Present in WindowID: \(window.windowID),
                        PID: \(pid),
                        Title: \(windowTitle),
                        AX: \(axElement)
                        """)
        }
        
        var screenshot: CGImage? = nil
        do {
            screenshot = try await ScreenshotHelper.capture(windowID: window.windowID)
        } catch {
            print("Coudlnt get screenshot: \(error)")
        }
        
        let spaces = Self.spacesForWindow(window.windowID)
        let isInSpace = !spaces.isEmpty
        
        let windowElement = WindowElement(element: axElement)
        
        let nsapp = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
        guard nsapp.count > 0 else {
            return nil
        }
        self.app = nsapp.first!
        self.windowID = window.windowID
        self.windowTitle = windowTitle
        self.element = windowElement
        self.bundleIdentifier = app.bundleIdentifier
        self.pid = pid
        self.screenshot = screenshot
        self.isInSpace = isInSpace
    }
    
    init(
        app: NSRunningApplication,
        windowID: CGWindowID?,
        windowTitle     : String,
        element: WindowElement,
        screen: NSScreen? = nil,
        bundleIdentifier: String?,
        pid: pid_t,
        screenshot: CGImage? = nil,
        isInSpace: Bool
    ) {
        self.app = app
        self.windowID = windowID
        self.windowTitle = windowTitle
        self.element = element
        self.screen = screen
        self.bundleIdentifier = bundleIdentifier
        self.pid = pid
        self.screenshot = screenshot
        self.isInSpace = isInSpace
    }
    
    private static func spacesForWindow(_ windowID: CGWindowID) -> [Int] {
        let cid = CGSConnectionID()
        let ids: CFArray = [NSNumber(value: Int(windowID))] as CFArray
        
        guard let unmanaged = CGSCopySpacesForWindows(cid, kCGSAllSpacesMask, ids) else {
            return []
        }
        
        // Usually retained for “Copy” functions
        let cfArray = unmanaged.takeRetainedValue()
        
        // Bridge to Swift
        let nums = cfArray as NSArray as? [NSNumber] ?? []
        return nums.map { $0.intValue }
    }
}

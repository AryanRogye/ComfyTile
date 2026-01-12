//
//  UserWindow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/6/26.
//

import Cocoa

struct UserWindow: Identifiable {
    var id: String { "\(pid):\(windowID ?? 0)" }
    
    let windowID : CGWindowID?
    let windowTitle : String?
    
    /// More stronger element
    var element: WindowElement
    var screen: NSScreen?
    let pid: pid_t
    let bundleIdentifier: String?
    let screenshot : CGImage?
    var isInSpace  : Bool
    
    init(
        windowID: CGWindowID?,
        windowTitle     : String?,
        element: WindowElement,
        screen: NSScreen? = nil,
        bundleIdentifier: String?,
        pid: pid_t,
        screenshot: CGImage? = nil,
        isInSpace: Bool
    ) {
        self.windowID = windowID
        self.windowTitle = windowTitle
        self.element = element
        self.screen = screen
        self.bundleIdentifier = bundleIdentifier
        self.pid = pid
        self.screenshot = screenshot
        self.isInSpace = isInSpace
    }
    
    public func focusWindow() {
        element.focusWindow(with: pid, for: windowID)
    }

}

//
//  FetchedWindow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/5/25.
//

import Cocoa

struct FetchedWindow: Identifiable {
    var id: CGWindowID { windowID }
    
    let windowID : CGWindowID
    let windowTitle     : String
    let pid : pid_t
    let element : WindowElement?
    let bundleIdentifier : String
    let screenshot : CGImage?
    var isInSpace  : Bool
    
    init(
        windowID : CGWindowID,
        windowTitle     : String,
        pid : pid_t,
        element: WindowElement? = nil,
        bundleIdentifier : String,
        screenshot: CGImage?,
        isInSpace : Bool = false
    ) {
        self.windowID = windowID
        self.windowTitle = windowTitle
        self.pid = pid
        self.element = element
        self.bundleIdentifier = bundleIdentifier
        self.screenshot = screenshot
        self.isInSpace  = isInSpace
    }
    
    func focusWindow() {
        if let element = element, let axElement = element.element {
            // Precise window focus
            activateApp(pid: pid)
            
            // Raise specific window using AX
            AXUIElementPerformAction(axElement, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(
                axElement,
                kAXMainAttribute as CFString,
                true as CFTypeRef
            )
        } else {
            // Fallback: just activate the app
            activateApp(pid: pid)
        }
    }
    
    private func activateApp(pid: pid_t) {
        let apps = NSWorkspace.shared.runningApplications
        if let app = apps.first(where: { $0.processIdentifier == pid }) {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}

//
//  FetchedWindow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/5/25.
//

import Cocoa

struct FetchedWindow : Hashable, Identifiable {
    var id: CGWindowID { windowID }
    
    let windowID : CGWindowID
    let windowTitle     : String
    let pid : pid_t
    let axElement : AXUIElement?
    let bundleIdentifier : String
    let screenshot : CGImage?
    
    init(
        windowID : CGWindowID,
        windowTitle     : String,
        pid : pid_t,
        axElement: AXUIElement? = nil,
        bundleIdentifier : String,
        screenshot: CGImage?
    ) {
        self.windowID = windowID
        self.windowTitle = windowTitle
        self.pid = pid
        self.axElement = axElement
        self.bundleIdentifier = bundleIdentifier
        self.screenshot = screenshot
    }
    
    func focusWindow() {
        if let axElement = axElement {
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

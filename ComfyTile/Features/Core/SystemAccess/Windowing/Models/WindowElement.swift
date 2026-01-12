//
//  WindowElement.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/7/26.
//

import Cocoa
import ComfyLogger

extension ComfyLogger {
    public static let WindowElement = ComfyLogger.Name("WindowElement")
}

class WindowElement {
    var element: AXUIElement?
    
    init(element: AXUIElement?) {
        self.element = element
    }
    
    var title: String? {
        get {
            return element?.getWrappedValue(.title)
        }
    }
    
    var frame: CGRect {
        guard let position = position, let size = size else { return .null }
        return .init(origin: position, size: size)
    }
    
    var cgWindowID: CGWindowID? {
        get {
            return element?._cgWindowID()
        }
    }
    
    var size: CGSize? {
        get {
            element?.getWrappedValue(.size)
        }
        set {
            guard let newValue = newValue else { return }
            element?.setValue(.size, newValue)
            ComfyLogger.WindowElement.insert("\(try? element?.title(), default: "-") Set Size: \(newValue)")
        }
    }
    
    var position: CGPoint? {
        get {
            element?.getWrappedValue(.position)
        }
        set {
            guard let newValue = newValue else { return }
            element?.setValue(.position, newValue)
            ComfyLogger.WindowElement.insert("\(try? element?.title(), default: "-") Set Position: \(newValue)")
        }
    }
    
    var windowFrame: CGRect? {
        guard let position else { return nil }
        guard let size else { return nil }
        return CGRect(origin: position, size: size)
    }
    
    public func setPosition(x: CGFloat, y: CGFloat) {
        position = CGPoint(x: x, y: y)
    }
    
    public func setSize(width: CGFloat, height: CGFloat) {
        size = CGSize(width: width, height: height)
    }
    
    public func setFrame(_ frame: CGRect, adjustSizeFirst: Bool = true) {
        if adjustSizeFirst {
            size = frame.size
        }
        position = frame.origin
        size = frame.size
    }
    
    public func focusWindow(
        with pid: pid_t,
        for window: CGWindowID? = nil
    ) {
        /// if window == nil do bottom
        if let window {
            SkylightHelpers.setFrontProcess(pid, window, mode: SLPSMode.allWindows)
        } else {
            if let axElement = element {
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
    }
    
    private func activateApp(pid: pid_t) {
        let apps = NSWorkspace.shared.runningApplications
        if let app = apps.first(where: { $0.processIdentifier == pid }) {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}

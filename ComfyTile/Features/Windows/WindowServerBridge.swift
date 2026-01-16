//
//  WindowServerBridge.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import Cocoa
import ComfyLogger

extension ComfyLogger {
    static let WindowServerBridge = ComfyLogger.Name("WindowServerBridge")
}

@MainActor
public class WindowServerBridge {
    public static let shared = WindowServerBridge(
        skylightPath: "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
        hiServicesPath: "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices"
    )
    
    private let skylightPath: UnsafePointer<CChar>
    private let hiServicesPath: UnsafePointer<CChar>
    
    private var skylightHandle: UnsafeMutableRawPointer?
    private var hiServicesHandle: UnsafeMutableRawPointer?
    
    public var setFrontProcessWithOptions: SLPSSetFrontProcessWithOptionsFn?
    public var postEventRecordTo: SLPSPostEventRecordToFn?
    public var getProcessForPID: GetProcessForPIDFn?
    public var axUIElementGetWindow: AXUIElementGetWindowFn?
    public var axUIElementCreateWithRemoteToken: AXUIElementCreateWithRemoteTokenFn?
    
    private let lock = NSLock()
    
    init(
        skylightPath: UnsafePointer<CChar>,
        hiServicesPath: UnsafePointer<CChar>
    ) {
        self.skylightPath = skylightPath
        self.hiServicesPath = hiServicesPath
        
        self.skylightHandle = nil
        self.hiServicesHandle = nil
        self.setFrontProcessWithOptions = nil
        self.postEventRecordTo = nil
        self.getProcessForPID = nil
        self.axUIElementGetWindow = nil
        self.axUIElementCreateWithRemoteToken = nil
        
        openHandle()
        setGetProcessForPID()
        setSLPSPostEventRecordTo()
        setSLPSSetFrontProcessWithOptions()
        setAXUIElementGetWindow()
        setAXUIElementCreateWithRemoteToken()
    }
    
    deinit {
        if let h = skylightHandle { dlclose(h) }
        if let h = hiServicesHandle { dlclose(h) }
    }
    
    public func focusApp(forUserWindowID windowID: UInt32, pid: pid_t, element: AXUIElement?) {
        guard let getProcessForPID else {
            ComfyLogger.WindowServerBridge.insert(
                "GetProcessForPID fn nil",
                level: .error
            )
            return
        }
        guard let setFrontProcessWithOptions else {
            ComfyLogger.WindowServerBridge.insert(
                "SLPSSetFrontProcessWithOptions fn nil",
                level: .error
            )
            return
        }
        guard let _ = postEventRecordTo else {
            ComfyLogger.WindowServerBridge.insert(
                "SLPSPostEventRecordTo fn nil",
                level: .error
            )
            return
        }
        
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: 0)
        let status = getProcessForPID(pid, &psn)
        if status != noErr {
            ComfyLogger.WindowServerBridge.insert(
                "Could Not Get Process For PID",
                level: .error
            )
            // keep behavior: don't hard-fail
            return
        }
        
        // 0x200 = userGenerated
        withUnsafePointer(to: psn) { psnPtr in
            setFrontProcessWithOptions(psnPtr, windowID, 0x200)
        }
        ComfyLogger.WindowServerBridge.insert(
            "Set Front Process With Options",
            level: .info
        )
        
        makeKeyWindow(forWindowID: windowID, psn: &psn)
        ComfyLogger.WindowServerBridge.insert(
            "Made Key Window For WindowID",
            level: .info
        )
        
        if let element {
            ComfyLogger.WindowServerBridge.insert(
                "AXElement Exists, Attempting To Raise",
                level: .debug
            )
            AXUIElementPerformAction(element, kAXRaiseAction as CFString)
            ComfyLogger.WindowServerBridge.insert(
                "Raising Done",
                level: .info
            )
        } else {
            for attempt in 0..<3 {
                if let found = findAXUIElement(forWindowID: windowID, pid: pid) {
                    ComfyLogger.WindowServerBridge.insert(
                        "AXElement Found, Raising",
                        level: .info
                    )
                    AXUIElementPerformAction(found, kAXRaiseAction as CFString)
                    // AXUIElement is CFType; ARC does not automatically release if created via remote token.
                    // We created it; release it.
                    break
                } else {
                    ComfyLogger.WindowServerBridge.insert(
                        "AXElement Not Found On Try: \(attempt)",
                        level: .warn
                    )
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.pid_focus(pid: pid)
        }
    }
    
    func pid_focus(pid :pid_t) {
        let apps = NSWorkspace.shared.runningApplications
        if let app = apps.first(where: { $0.processIdentifier == pid }) {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
    
    // Equivalent to your findMatchingAXWindowWithPid:targetWindowID:
    func findMatchingAXWindow(pid: pid_t, targetWindowID: CGWindowID) -> AXUIElement? {
        let appAX: AXUIElement = AXUIElementCreateApplication(pid)
        
        var windowsValue: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsValue)
        
        guard err == .success, let windowsValue else {
            return nil
        }
        
        guard CFGetTypeID(windowsValue) == CFArrayGetTypeID() else {
            return nil
        }
        
        let windows = windowsValue as! CFArray
        let count = CFArrayGetCount(windows)
        
        for i in 0..<count {
            let raw = CFArrayGetValueAtIndex(windows, i)
            let winAX = unsafeBitCast(raw, to: AXUIElement.self)
            
            var wid: CGWindowID = 0
            if axUIElementGetWindow?(winAX, &wid) == .success, wid == targetWindowID {
                return winAX
            }
        }
        
        return nil
    }
    
    // MARK: - Private APIs (packet + token probe)
    
    private func makeKeyWindow(forWindowID windowID: UInt32, psn: inout ProcessSerialNumber) {
        guard let postEventRecordTo else { return }
        
        var bytes = [UInt8](repeating: 0, count: 0xF8)
        
        bytes[0x04] = 0xF8
        bytes[0x08] = 0x01
        bytes[0x3A] = 0x10
        
        bytes[0x3C] = UInt8(windowID & 0xFF)
        bytes[0x3D] = UInt8((windowID >> 8) & 0xFF)
        bytes[0x3E] = UInt8((windowID >> 16) & 0xFF)
        bytes[0x3F] = UInt8((windowID >> 24) & 0xFF)
        
        let psnLow  = UInt64(UInt32(psn.lowLongOfPSN))
        let psnHigh = UInt64(UInt32(psn.highLongOfPSN))
        let psnValue = psnLow | (psnHigh << 32)
        
        for i in 0..<8 {
            bytes[0x20 + i] = UInt8((psnValue >> (i * 8)) & 0xFF)
        }
        
        bytes.withUnsafeBufferPointer { buf in
            withUnsafePointer(to: psn) { psnPtr in
                postEventRecordTo(psnPtr, buf.baseAddress!)
            }
        }
    }
    
    private func findAXUIElement(forWindowID windowID: UInt32, pid: pid_t) -> AXUIElement? {
        guard let axUIElementCreateWithRemoteToken,
              let axUIElementGetWindow else { return nil }
        
        // Probe token structures until we find the right one
        for tokenValue in UInt32(0)..<UInt32(65536) {
            var token = [UInt8](repeating: 0, count: 20)
            
            token[0] = 0x00
            token[1] = 0x62
            token[2] = 0x00
            token[3] = 0x00
            
            token[4] = UInt8(windowID & 0xFF)
            token[5] = UInt8((windowID >> 8) & 0xFF)
            token[6] = UInt8((windowID >> 16) & 0xFF)
            token[7] = UInt8((windowID >> 24) & 0xFF)
            
            token[8]  = UInt8(tokenValue & 0xFF)
            token[9]  = UInt8((tokenValue >> 8) & 0xFF)
            token[10] = 0x00
            token[11] = 0x00
            
            token[12] = 0x00
            token[13] = 0x00
            token[14] = 0x01
            token[15] = 0x00
            
            let tokenData = token.withUnsafeBytes { raw in
                CFDataCreate(kCFAllocatorDefault, raw.bindMemory(to: UInt8.self).baseAddress, 20)!
            }
            
            if let element = axUIElementCreateWithRemoteToken(tokenData) {
                var foundID: CGWindowID = 0
                let axErr = axUIElementGetWindow(element, &foundID)
                if axErr == .success && foundID == windowID {
                    // keep element, caller will CFRelease if needed
                    return element
                }
            }
        }
        
        return nil
    }
    
    // MARK: - dlopen/dlsym plumbing
    
    private func openHandle() {
        skylightHandle = dlopen(skylightPath, RTLD_LAZY | RTLD_GLOBAL)
        guard skylightHandle != nil else {
            ComfyLogger.WindowServerBridge.insert(
                "SkyLight Handle is Null",
                level: .error
            )
            exit(1)
        }
        
        hiServicesHandle = dlopen(hiServicesPath, RTLD_LAZY | RTLD_GLOBAL)
        guard hiServicesHandle != nil else {
            ComfyLogger.WindowServerBridge.insert(
                "HIServices Handle is Null",
                level: .error
            )
            exit(1)
        }
        
        ComfyLogger.WindowServerBridge.insert("✅ Handles are Ready", level: .info)
    }
    
    private func sym<T>(_ handle: UnsafeMutableRawPointer?,
                        primary: String,
                        fallback: String) -> T {
        guard let handle else {
            ComfyLogger.WindowServerBridge.insert(
                "Handle nil for \(primary)",
                level: .error
            )
            exit(1)
        }
        
        if let p = dlsym(handle, primary) {
            return unsafeBitCast(p, to: T.self)
        }
        
        if let p = dlsym(handle, fallback) {
            return unsafeBitCast(p, to: T.self)
        }
        
        if let err = dlerror() {
            ComfyLogger.WindowServerBridge.insert(
                "dlsym Cant be Found: \(String(cString: err))",
                level: .error
            )
        } else {
            ComfyLogger.WindowServerBridge.insert(
                "dlsym Cant be Found: \(primary) / \(fallback)",
                level: .error
            )
        }
        exit(1)
    }
    
    private func setAXUIElementCreateWithRemoteToken() {
        ComfyLogger.WindowServerBridge.insert(
            "Attempting AXUIElementCreateWithRemoteToken",
            level: .debug
        )
        axUIElementCreateWithRemoteToken = sym(
            hiServicesHandle,
            primary: "AXUIElementCreateWithRemoteToken",
            fallback: "_AXUIElementCreateWithRemoteToken"
        )
        ComfyLogger.WindowServerBridge.insert(
            "✅ AXUIElementCreateWithRemoteToken (or _) Success",
            level: .info
        )
    }
    
    private func setAXUIElementGetWindow() {
        ComfyLogger.WindowServerBridge.insert("Attempting AXUIElementGetWindow", level: .debug)
        axUIElementGetWindow = sym(
            hiServicesHandle,
            primary: "AXUIElementGetWindow",
            fallback: "_AXUIElementGetWindow"
        )
        ComfyLogger.WindowServerBridge.insert(
            "✅ AXUIElementGetWindow (or _) Success",
            level: .info
        )
    }
    
    private func setGetProcessForPID() {
        ComfyLogger.WindowServerBridge.insert("Attempting GetProcessForPID", level: .debug)
        getProcessForPID = sym(
            hiServicesHandle,
            primary: "GetProcessForPID",
            fallback: "_GetProcessForPID"
        )
        ComfyLogger.WindowServerBridge.insert("✅ GetProcessForPID (or _) Success", level: .info)
    }
    
    private func setSLPSSetFrontProcessWithOptions() {
        ComfyLogger.WindowServerBridge.insert(
            "Attempting SLPSSetFrontProcessWithOptions",
            level: .debug
        )
        setFrontProcessWithOptions = sym(
            skylightHandle,
            primary: "SLPSSetFrontProcessWithOptions",
            fallback: "_SLPSSetFrontProcessWithOptions"
        )
        ComfyLogger.WindowServerBridge.insert(
            "✅ SLPSSetFrontProcessWithOptions (or _) Success",
            level: .info
        )
    }
    
    private func setSLPSPostEventRecordTo() {
        ComfyLogger.WindowServerBridge.insert("Attempting SLPSPostEventRecordTo", level: .debug)
        postEventRecordTo = sym(
            skylightHandle,
            primary: "SLPSPostEventRecordTo",
            fallback: "_SLPSPostEventRecordTo"
        )
        ComfyLogger.WindowServerBridge.insert(
            "✅ SLPSPostEventRecordTo (or _) Success",
            level: .info
        )
    }
}


public typealias SLPSSetFrontProcessWithOptionsFn =
@convention(c) (_ psn: UnsafePointer<ProcessSerialNumber>,
                _ windowID: UInt32,
                _ options: UInt32) -> Void

public typealias SLPSPostEventRecordToFn =
@convention(c) (_ psn: UnsafePointer<ProcessSerialNumber>,
                _ bytes: UnsafePointer<UInt8>) -> Void

public typealias GetProcessForPIDFn =
@convention(c) (_ pid: pid_t,
                _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

public typealias AXUIElementGetWindowFn =
@convention(c) (_ element: AXUIElement,
                _ outWindowID: UnsafeMutablePointer<CGWindowID>) -> AXError

public typealias AXUIElementCreateWithRemoteTokenFn =
@convention(c) (_ token: CFData) -> AXUIElement?

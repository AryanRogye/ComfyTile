//
//  WindowServerBridge.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import Cocoa

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
            NSLog("\u{001B}[1;31mGetProcessForPID fn nil\u{001B}[0m")
            return
        }
        guard let setFrontProcessWithOptions else {
            NSLog("\u{001B}[1;31mSLPSSetFrontProcessWithOptions fn nil\u{001B}[0m")
            return
        }
        guard let _ = postEventRecordTo else {
            NSLog("\u{001B}[1;31mSLPSPostEventRecordTo fn nil\u{001B}[0m")
            return
        }
        
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: 0)
        let status = getProcessForPID(pid, &psn)
        if status != noErr {
            NSLog("\u{001B}[1;31mCould Not Get Process For PID\u{001B}[0m")
            // keep behavior: don't hard-fail
            return
        }
        
        // 0x200 = userGenerated
        withUnsafePointer(to: psn) { psnPtr in
            setFrontProcessWithOptions(psnPtr, windowID, 0x200)
        }
        NSLog("\u{001B}[1;32mSet Front Process With Options\u{001B}[0m")
        
        makeKeyWindow(forWindowID: windowID, psn: &psn)
        NSLog("\u{001B}[1;32mMade Key Window For WindowID\u{001B}[0m")
        
        if let element {
            NSLog("\u{001B}[1;32mAXElement Exists, Attempting To Raise\u{001B}[0m")
            AXUIElementPerformAction(element, kAXRaiseAction as CFString)
            NSLog("\u{001B}[1;32mRaising Done\u{001B}[0m")
        } else {
            for attempt in 0..<3 {
                if let found = findAXUIElement(forWindowID: windowID, pid: pid) {
                    NSLog("\u{001B}[1;32mAXElement Found, Raising\u{001B}[0m")
                    AXUIElementPerformAction(found, kAXRaiseAction as CFString)
                    // AXUIElement is CFType; ARC does not automatically release if created via remote token.
                    // We created it; release it.
                    break
                } else {
                    NSLog("\u{001B}[1;31mAXElement Not Found On Try: \(attempt)\u{001B}[0m")
                }
            }
        }
        pid_focus(pid: pid)
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
            NSLog("\u{001B}[1;31mSkyLight Handle is Null\u{001B}[0m")
            exit(1)
        }
        
        hiServicesHandle = dlopen(hiServicesPath, RTLD_LAZY | RTLD_GLOBAL)
        guard hiServicesHandle != nil else {
            NSLog("\u{001B}[1;31mHIServices Handle is Null\u{001B}[0m")
            exit(1)
        }
        
        NSLog("✅ Handles are Ready")
    }
    
    private func sym<T>(_ handle: UnsafeMutableRawPointer?,
                        primary: String,
                        fallback: String) -> T {
        guard let handle else {
            NSLog("\u{001B}[1;31mHandle nil for \(primary)\u{001B}[0m")
            exit(1)
        }
        
        if let p = dlsym(handle, primary) {
            return unsafeBitCast(p, to: T.self)
        }
        
        if let p = dlsym(handle, fallback) {
            return unsafeBitCast(p, to: T.self)
        }
        
        if let err = dlerror() {
            NSLog("\u{001B}[1;31mdlsym Cant be Found: \(String(cString: err))\u{001B}[0m")
        } else {
            NSLog("\u{001B}[1;31mdlsym Cant be Found: \(primary) / \(fallback)\u{001B}[0m")
        }
        exit(1)
    }
    
    private func setAXUIElementCreateWithRemoteToken() {
        NSLog("Attempting AXUIElementCreateWithRemoteToken")
        axUIElementCreateWithRemoteToken = sym(
            hiServicesHandle,
            primary: "AXUIElementCreateWithRemoteToken",
            fallback: "_AXUIElementCreateWithRemoteToken"
        )
        NSLog("✅ AXUIElementCreateWithRemoteToken (or _) Success")
    }
    
    private func setAXUIElementGetWindow() {
        NSLog("Attempting AXUIElementGetWindow")
        axUIElementGetWindow = sym(
            hiServicesHandle,
            primary: "AXUIElementGetWindow",
            fallback: "_AXUIElementGetWindow"
        )
        NSLog("✅ AXUIElementGetWindow (or _) Success")
    }
    
    private func setGetProcessForPID() {
        NSLog("Attempting GetProcessForPID")
        getProcessForPID = sym(
            hiServicesHandle,
            primary: "GetProcessForPID",
            fallback: "_GetProcessForPID"
        )
        NSLog("✅ GetProcessForPID (or _) Success")
    }
    
    private func setSLPSSetFrontProcessWithOptions() {
        NSLog("Attempting SLPSSetFrontProcessWithOptions")
        setFrontProcessWithOptions = sym(
            skylightHandle,
            primary: "SLPSSetFrontProcessWithOptions",
            fallback: "_SLPSSetFrontProcessWithOptions"
        )
        NSLog("✅ SLPSSetFrontProcessWithOptions (or _) Success")
    }
    
    private func setSLPSPostEventRecordTo() {
        NSLog("Attempting SLPSPostEventRecordTo")
        postEventRecordTo = sym(
            skylightHandle,
            primary: "SLPSPostEventRecordTo",
            fallback: "_SLPSPostEventRecordTo"
        )
        NSLog("✅ SLPSPostEventRecordTo (or _) Success")
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

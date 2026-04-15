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

final class DylibHandles: @unchecked Sendable {
    private var skylightHandle: UnsafeMutableRawPointer?
    private var hiServicesHandle: UnsafeMutableRawPointer?
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
        closeHandles()
    }
    
    nonisolated internal func closeHandles() {
        DispatchQueue.main.async {
            if let h = self.skylightHandle { dlclose(h) }
            if let h = self.hiServicesHandle { dlclose(h) }
        }
    }
    
    public func focusApp(forUserWindowID windowID: UInt32, pid: pid_t, element: AXUIElement?, app: NSRunningApplication) {
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
        makeKeyWindow(forWindowID: windowID, psn: &psn)
        
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
        }
        
        app.activate(options: [.activateIgnoringOtherApps])
        
        /// Then Check Element and bring above
        if let axElement = element {
            // Raise specific window using AX
            AXUIElementPerformAction(axElement, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(
                axElement,
                kAXMainAttribute as CFString,
                true as CFTypeRef
            )
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
    
    /// Discovers an AXUIElement for a window by brute-forcing the remote token API.
    ///
    /// construct a 20-byte token containing the PID and an incrementing
    /// AX element ID, then call `_AXUIElementCreateWithRemoteToken` to fabricate
    /// a reference.
    /// This finds windows that standard `kAXWindowsAttribute` misses — minimized windows,
    /// windows on other Spaces, and windows from apps that don't fully expose
    /// their AX hierarchy.
    func findMatchingAXWindowBruteForce(pid: pid_t, targetWindowID: CGWindowID) -> AXUIElement? {
        guard let createWithToken = axUIElementCreateWithRemoteToken,
              let getWindow = axUIElementGetWindow else { return nil }
        
        // Token layout (20 bytes):
        //   [0..3]   pid            (Int32, little-endian)
        //   [4..7]   reserved       (0)
        //   [8..11]  magic          (0x636F_636F — "coco")
        //   [12..19] AX element ID  (UInt64)
        var token = Data(count: 20)
        withUnsafeBytes(of: pid) { token.replaceSubrange(0..<4, with: $0) }
        withUnsafeBytes(of: Int32(0)) { token.replaceSubrange(4..<8, with: $0) }
        withUnsafeBytes(of: Int32(0x636F_636F)) { token.replaceSubrange(8..<12, with: $0) }
        
        for axID: UInt64 in 0..<1000 {
            withUnsafeBytes(of: axID) { token.replaceSubrange(12..<20, with: $0) }
            
            guard let element = createWithToken(token as CFData) else { continue }
            
            // Check if this element matches the target CGWindowID
            var wid: CGWindowID = 0
            if getWindow(element, &wid) == .success, wid == targetWindowID {
                // Verify it's a real window (has role=AXWindow)
                var roleValue: CFTypeRef?
                let roleErr = AXUIElementCopyAttributeValue(
                    element,
                    kAXRoleAttribute as CFString,
                    &roleValue
                )
                if roleErr == .success,
                   let role = roleValue as? String,
                   role == (kAXWindowRole as String) {
                    return element
                }
            }
        }
        
        return nil
    }
    
    /// Resolves an AXUIElement for a given window, trying the standard approach
    /// first and falling back to brute-force token fabrication.
    ///
    /// This is the primary API for getting an AX element for any window without
    /// requiring prior caching.
    func resolveAXElement(pid: pid_t, windowID: CGWindowID) -> AXUIElement? {
        // Fast path: standard kAXWindows enumeration
        if let ax = findMatchingAXWindow(pid: pid, targetWindowID: windowID) {
            return ax
        }
        // Slow path: brute-force via _AXUIElementCreateWithRemoteToken
        return findMatchingAXWindowBruteForce(pid: pid, targetWindowID: windowID)
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
            ComfyLogger.WindowServerBridge.insert("Handle nil for \(primary)", level: .error)
            fatalError("Handle nil for \(primary)")
        }
        
        // Clear any prior dlerror state (important)
        _ = dlerror()
        
        func resolve(_ name: String) -> UnsafeMutableRawPointer? {
            _ = dlerror() // clear before each dlsym
            let p = dlsym(handle, name)
            // If dlerror() returns non-nil, this dlsym failed even if p is non-nil (rare but happens)
            if dlerror() != nil { return nil }
            return p
        }
        
        guard let p = resolve(primary) ?? resolve(fallback) else {
            let msg = dlerror().map { String(cString: $0) } ?? "unknown dlerror"
            ComfyLogger.WindowServerBridge.insert(
                "dlsym not found: \(primary) / \(fallback) — \(msg)",
                level: .error
            )
            fatalError("dlsym not found: \(primary) / \(fallback) — \(msg)")
        }
        
        // Cast symbol address -> requested function pointer type
        return unsafeBitCast(p, to: T.self)
    }
    
    private func symGlobal<T>(primary: String, fallback: String) -> T {
        if let p = dlsym(UnsafeMutableRawPointer(bitPattern: -2), primary) { // RTLD_DEFAULT
            return unsafeBitCast(p, to: T.self)
        }
        if let p = dlsym(UnsafeMutableRawPointer(bitPattern: -2), fallback) {
            return unsafeBitCast(p, to: T.self)
        }
        fatalError("global dlsym failed: \(primary)/\(fallback)")
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
/**
 * SLSMainConnectionID:
 * function _SLSMainConnectionID {
 *      r31 = r31 + 0xffffffffffffffe0;
 *      arg_10 = r29;
 *      arg_18 = r30;
 *      r19 = objc_autoreleasePoolPush();
 *      r0 = _SLSMainConnection();
 *      if (r0 != 0x0) {
 *          r20 = r0[0x4];
 *      }
 *      else {
 *          r20 = 0x0;
 *      }
 *      objc_autoreleasePoolPop(r19);
 *      return;
 * }
 */

/*
 * This is deadass:
 * void _SLSGetWindowWorkspaceIgnoringVisibility() {
 *      abort();
 *      return;
 * }

 */
//public typealias SLSGetWindowWorkspaceIgnoringVisibilityFn =
//@convention(c) (_ cid: CGSConnectionID,
//                _ windowID: UInt32,
//                _ spaceID: UnsafeMutablePointer<Int>
//) -> Int

//public typealias SLSMainConnectionFn = @convention(c) () -> UnsafeMutableRawPointer?
//
//public typealias SLSConnectionID = Int32
//public typealias SLSMainConnectionIDFn = @convention(c) () -> SLSConnectionID

/**
 * void _SLSGetWindowWorkspace(int arg0, int arg1, int arg2) {
 *      r31 = r31 - 0x30;
 *      var_10 = r20;
 *      decomp_var_8 = r19;
 *      saved_fp = r29;
 *      decomp_var_m8 = r30;
 *      var_18 = **0x1e6b211e8;
 *      CGSGetWindowTags();
 *      *(int32_t *)arg2 = 0x10008 & (0x0 << 0x14) / 0x80000000;
 *      if (**0x1e6b211e8 != var_18) {
 *          __stack_chk_fail();
 *      }
 *      return;
 * }
 */
//public typealias SLSGetWindowWorkspaceFn =
//@convention(c) (
//    _ cid: UnsafeMutableRawPointer,
//    _ windowID: UInt32,
//    _ outSpace: UnsafeMutablePointer<UInt32>
//) -> Int32

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

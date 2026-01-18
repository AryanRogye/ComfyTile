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

        var didActivateFallback = false
        func activateAppFallback() {
            guard !didActivateFallback else { return }
            if app.isHidden {
                app.unhide()
            }
            app.activate(options: [.activateIgnoringOtherApps])
            didActivateFallback = true
        }

        func resolvedAXElement() -> AXUIElement? {
            if let element {
                if let axUIElementGetWindow {
                    var id: CGWindowID = 0
                    if axUIElementGetWindow(element, &id) == .success, id == windowID {
                        return element
                    }
                } else {
                    return element
                }
            }
            return findMatchingAXWindow(pid: pid, targetWindowID: windowID)
        }

        let maxRetries = 3
        var targetElement = resolvedAXElement()
        for attempt in 0..<maxRetries {
            // 0x200 = userGenerated
            let frontError = setFrontProcessWithOptions(&psn, windowID, 0x200)
            if frontError != .success {
                ComfyLogger.WindowServerBridge.insert(
                    "SLPSSetFrontProcessWithOptions error: \(frontError.rawValue)",
                    level: .warn
                )
                activateAppFallback()
            }
            makeKeyWindow(forWindowID: windowID, psn: &psn)

            if targetElement == nil {
                targetElement = resolvedAXElement()
            }

            if let targetElement {
                ComfyLogger.WindowServerBridge.insert(
                    "AXElement Exists, Attempting To Raise",
                    level: .debug
                )
                let raiseErr = AXUIElementPerformAction(targetElement, kAXRaiseAction as CFString)
                let mainErr = AXUIElementSetAttributeValue(
                    targetElement,
                    kAXMainAttribute as CFString,
                    true as CFTypeRef
                )
                let focusErr = AXUIElementSetAttributeValue(
                    targetElement,
                    kAXFocusedAttribute as CFString,
                    true as CFTypeRef
                )
                if raiseErr == .success && mainErr == .success {
                    ComfyLogger.WindowServerBridge.insert(
                        "Raising Done",
                        level: .info
                    )
                    break
                }

                if raiseErr == .cannotComplete || mainErr == .cannotComplete || focusErr == .cannotComplete {
                    ComfyLogger.WindowServerBridge.insert(
                        "AX raise cannotComplete, retrying (\(attempt + 1)/\(maxRetries))",
                        level: .warn
                    )
                } else if raiseErr != .success || mainErr != .success {
                    ComfyLogger.WindowServerBridge.insert(
                        "AX raise failed (\(raiseErr.rawValue), \(mainErr.rawValue))",
                        level: .warn
                    )
                    activateAppFallback()
                    break
                }
            } else {
                activateAppFallback()
            }

            if attempt < maxRetries - 1 {
                usleep(50_000)
            }
        }
//        else {
//            if let fn = getWindowWorkspaceFn, let slsMainConnection {
//                if let cid = slsMainConnection() {
//                    var space: UInt32 = 0
//                    let err = fn(cid, windowID, &space)
//                    print("RESULT: \(space): \(err)")
//                }
//            }
//        }
//        else {
            /// TODO: WARNING: FIX THIS HERE ATTEMPT TO USE A CACHE OR JUST FOCUS IT
//            for attempt in 0..<3 {
//                if let found = findAXUIElement(forWindowID: windowID, pid: pid) {
//                    ComfyLogger.WindowServerBridge.insert(
//                        "AXElement Found, Raising",
//                        level: .info
//                    )
//                    AXUIElementPerformAction(found, kAXRaiseAction as CFString)
//                    break
//                } else {
//                    ComfyLogger.WindowServerBridge.insert(
//                        "AXElement Not Found On Try: \(attempt)",
//                        level: .warn
//                    )
//                }
//            }
        //        }
//        self.pid_focus(pid: pid)
        
        if targetElement == nil {
            activateAppFallback()
        }
    }
    
//    func pid_focus(pid :pid_t) {
//        let apps = NSWorkspace.shared.runningApplications
//        if let app = apps.first(where: { $0.processIdentifier == pid }) {
//            for i in 0..<3 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(i)) {
//                    app.activate(options: [.activateIgnoringOtherApps])
//                }
//            }
//        }
//    }
    
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
    
    public func makeKeyWindow(forWindowID windowID: UInt32, psn: inout ProcessSerialNumber) {
        guard let postEventRecordTo else { return }

        var bytes = [UInt8](repeating: 0, count: 0xF8)
        bytes[0x04] = 0xF8
        bytes[0x3A] = 0x10

        var wid = windowID
        memcpy(&bytes[0x3C], &wid, MemoryLayout<UInt32>.size)
        memset(&bytes[0x20], 0xFF, 0x10)

        bytes[0x08] = 0x01
        bytes.withUnsafeMutableBufferPointer { buf in
            postEventRecordTo(&psn, buf.baseAddress!)
        }
        bytes[0x08] = 0x02
        bytes.withUnsafeMutableBufferPointer { buf in
            postEventRecordTo(&psn, buf.baseAddress!)
        }
    }
    
    public func findAXUIElement(forWindowID windowID: UInt32, pid: pid_t) -> AXUIElement? {
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
    
    /// Heuristic mapping from AX window to CG window when _AXUIElementGetWindow fails
    func mapAXToCG(axWindow: AXUIElement, candidates: [[String: AnyObject]], excluding: Set<CGWindowID>) -> CGWindowID? {
        
        let element = WindowElement(element: axWindow)
        
        let axTitle = (try? axWindow.title())?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let axPos = element.position
        let axSize = element.size
        
        // 1) Exact title match among unused candidates
        if !axTitle.isEmpty {
            if let match = candidates.first(where: { desc in
                let title = (desc[kCGWindowName as String] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let wid = CGWindowID((desc[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
                return title == axTitle && !excluding.contains(wid)
            }) {
                return CGWindowID((match[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
            }
        }
        
        // 2) Geometry match within tolerance
        if let p = axPos, let s = axSize, s != .zero {
            let tol: CGFloat = 2.0
            if let match = candidates.first(where: { desc in
                let wid = CGWindowID((desc[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
                if excluding.contains(wid) { return false }
                let bounds = desc[kCGWindowBounds as String] as? [String: AnyObject]
                let rx = CGFloat((bounds?["X"] as? NSNumber)?.doubleValue ?? .infinity)
                let ry = CGFloat((bounds?["Y"] as? NSNumber)?.doubleValue ?? .infinity)
                let rw = CGFloat((bounds?["Width"] as? NSNumber)?.doubleValue ?? .infinity)
                let rh = CGFloat((bounds?["Height"] as? NSNumber)?.doubleValue ?? .infinity)
                let r = CGRect(x: rx, y: ry, width: rw, height: rh)
                let posMatch = abs(r.origin.x - p.x) <= tol && abs(r.origin.y - p.y) <= tol
                let sizeMatch = abs(r.size.width - s.width) <= tol && abs(r.size.height - s.height) <= tol
                return posMatch && sizeMatch
            }) {
                return CGWindowID((match[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
            }
        }
        
        // 3) Fuzzy title contains
        if !axTitle.isEmpty {
            if let match = candidates.first(where: { desc in
                let title = ((desc[kCGWindowName as String] as? String) ?? "").lowercased()
                let wid = CGWindowID((desc[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
                return !excluding.contains(wid) && title.contains(axTitle.lowercased())
            }) {
                return CGWindowID((match[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
            }
        }
        
        return nil
    }

    
    func getCGWindowCandidates(for pid: pid_t) -> [[String: AnyObject]] {
        let cgAll = (CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID) as? [[String: AnyObject]]) ?? []
        return cgAll.filter { desc in
            let owner = (desc[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ?? 0
            let layer = (desc[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
            return owner == pid && layer == 0
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
@convention(c) (_ psn: UnsafeMutablePointer<ProcessSerialNumber>,
                _ windowID: UInt32,
                _ options: UInt32) -> CGError

public typealias SLPSPostEventRecordToFn =
@convention(c) (_ psn: UnsafeMutablePointer<ProcessSerialNumber>,
                _ bytes: UnsafeMutablePointer<UInt8>) -> CGError

public typealias GetProcessForPIDFn =
@convention(c) (_ pid: pid_t,
                _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

public typealias AXUIElementGetWindowFn =
@convention(c) (_ element: AXUIElement,
                _ outWindowID: UnsafeMutablePointer<CGWindowID>) -> AXError

public typealias AXUIElementCreateWithRemoteTokenFn =
@convention(c) (_ token: CFData) -> AXUIElement?

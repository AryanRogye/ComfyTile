//
//  SkylightHelpers.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/12/26.
//

import Cocoa

/**
 * `nm SkyLight | rg "Front"`
 * Brought me to a open source repo using it
 * https://github.com/obra/winby
 *
 * This had a example of using _SLPSSetFrontProcessWithOptions:
 *
 *      // Use private API to bring window to front without making it key
 *      // This raises the window visually but doesn't steal keyboard focus
 *      var psn = ProcessSerialNumber()
 *      GetProcessForPID(window.pid, &psn)
 *
 *      let targetWindowID = window.parentWindowID ?? windowID
 *      // Use allWindows mode - brings process to front with all its windows
 *      _SLPSSetFrontProcessWithOptions(&psn, targetWindowID, SLPSMode.allWindows.rawValue)
 */

struct SkylightHelpers {
    
    // Hold the dylib handle for the lifetime of the process.
    private static let skyLightHandle: UnsafeMutableRawPointer? = {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
        let h = dlopen(path, RTLD_NOW)
        if h == nil {
            if let e = dlerror() { print("dlopen error:", String(cString: e)) }
        }
        return h
    }()
    
    
    // C function pointer type
    typealias SLPSSetFrontProcessWithOptionsFn =
    @convention(c) (
        UnsafeMutablePointer<ProcessSerialNumber>,
        CGWindowID,
        UInt32
    ) -> CGError
    
    typealias SLPSPostEventRecordToFn =
    @convention(c) (
        UnsafeMutablePointer<ProcessSerialNumber>,
        UnsafeMutablePointer<UInt8>
    ) -> CGError
    
    
    
    /// Make a window the key window (from AltTab/Hammerspoon)
    /// This sends special events to the WindowServer to ensure proper focus
    public static func makeKeyWindow(_ psn: inout ProcessSerialNumber, _ windowID: CGWindowID) {
        
        guard let handle = skyLightHandle else {
            print("No Handle Found")
            return
        }
        
        /// sym can be _ or the regular one
        let sym = dlsym(handle, "SLPSPostEventRecordTo") ?? dlsym(handle, "_SLPSPostEventRecordTo")
        
        guard let sym else {
            if let e = dlerror() {
                print("dlsym error: ")
            }
            return
        }
        let fn = unsafeBitCast(sym, to: SLPSPostEventRecordToFn.self)
        
        var bytes = [UInt8](repeating: 0, count: 0xf8)
        bytes[0x04] = 0xf8
        bytes[0x08] = 0x01
        bytes[0x3a] = 0x10
        
        // Fill bytes 0x20-0x2f with 0xff
        for i in 0x20...0x2f {
            bytes[i] = 0xff
        }
        
        // Copy windowID into bytes at offset 0x3c
        var wid = windowID
        withUnsafeBytes(of: &wid) { widBytes in
            for i in 0..<4 {
                bytes[0x3c + i] = widBytes[i]
            }
        }
        
        _ = fn(&psn, &bytes)
        print("Done Once")
        //        SLPSPostEventRecordTo(&psn, &bytes)
        
        // Second call with 0x02
        bytes[0x08] = 0x02
        _ = fn(&psn, &bytes)
        print("Done Twice")
        //        SLPSPostEventRecordTo(&psn, &bytes)
    }

    static func setFrontProcess(_ pid: pid_t, _ window: CGWindowID, mode: SLPSMode) {
        
        guard let handle = skyLightHandle else {
            print("No Handle Found")
            return
        }
        
        // Grab PSN from PID (this one is in ApplicationServices)
        var psn = ProcessSerialNumber()
        let status = GetProcessForPID(pid, &psn)
        guard status == noErr else {
            print("GetProcessForPID failed:", status)
            return
        }
        
        // Try both symbol spellings (underscore vs none)
        let sym =
        dlsym(handle, "SLPSSetFrontProcessWithOptions") ??
        dlsym(handle, "_SLPSSetFrontProcessWithOptions")
        
        guard let sym else {
            if let e = dlerror() {
                print("dlsym error:", String(cString: e))
            }
            return
        }
        
        let fn = unsafeBitCast(sym, to: SLPSSetFrontProcessWithOptionsFn.self)
        _ = fn(&psn, window, mode.rawValue)
        print("Done Making Key Window")
        makeKeyWindow(&psn, window)
    }
}

enum SLPSMode: UInt32 {
    case allWindows = 0x100
    case userGenerated = 0x200
    case noWindows = 0x400
}

/// Get process serial number from PID
@_silgen_name("GetProcessForPID") @discardableResult
func GetProcessForPID(_ pid: pid_t, _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

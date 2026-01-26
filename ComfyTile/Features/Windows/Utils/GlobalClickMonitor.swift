//
//  GlobalClickMonitor.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/22/26.
//

import Cocoa

@MainActor
final class GlobalClickMonitor {
    
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    /// Flag to know if the modifier key is pressed locally or not
    private(set) var mouseDown: Bool = false
    
    /// Store the onClick closure as an instance variable
    private var onClick: (() -> Void)?
    
    init() {}
    
    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }
    
    public func start(onClick: @escaping () -> Void) {
        if tap != nil {
            print("⚠️ Mouse monitor already running")
            return
        }
        
        // Store the closure
        self.onClick = onClick
        
        // Create mask for mouse events
        let mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<GlobalClickMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            monitor.handleMouseEvent(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: selfPtr
        )
        
        guard let tap else {
            print("❌ Failed to create mouse event tap - check Accessibility permissions")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
    }
    
    public func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        runLoopSource = nil
        tap = nil
        
        // Clear the stored closure
        onClick = nil
    }
    
    private func handleMouseEvent(type: CGEventType, event: CGEvent) {
        // Handle tap re-enable
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        
        switch type {
        case .leftMouseDown:
            mouseDown = true
            onClick?() // Call the stored closure
        case .leftMouseUp:
            mouseDown = false
        default:
            break
        }
    }
}

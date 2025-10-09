//
//  HotKeyCoordinator.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let RightHalf = Self("RightHalf")
    static let LeftHalf = Self("LeftHalf")
    static let Center   = Self("Center")
    static let Maximize = Self("Maximize")
    static let NudgeBottomDown = Self("NudgeBottomDown")
    static let NudgeBottomUp = Self("NudgeBottomUp")
    static let NudgeTopUp = Self("NudgeTopUp")
    static let NudgeTopDown = Self("NudgeTopDown")
}

@MainActor
final class HotKeyCoordinator {
    
    private(set) var rightHalf : KeyboardShortcuts.Name
    private(set) var leftHalf  : KeyboardShortcuts.Name
    private(set) var center    : KeyboardShortcuts.Name
    private(set) var maximize  : KeyboardShortcuts.Name
    
    private(set) var nudgeBottomDown : KeyboardShortcuts.Name
    private(set) var nudgeBottomUp   : KeyboardShortcuts.Name
    private(set) var nudgeTopUp      : KeyboardShortcuts.Name
    private(set) var nudgeTopDown    : KeyboardShortcuts.Name
    
    private let modifierDetector = ModifierDoubleTapDetector()
    
    public func start(with group: ModifierGroup) {
        modifierDetector.start(with: group)
    }
    public func stop() {
        modifierDetector.stop()
    }
    
    init(
        /// On Down's and on Up's do the same thing
        onOptDoubleTapDown: @escaping () -> Void = {},
        onOptDoubleTapUp:   @escaping () -> Void = {},
        onCtrlDoubleTapDown: @escaping () -> Void = {},
        onCtrlDoubleTapUp:   @escaping () -> Void = {},
        
        onRightHalfDown: @escaping () -> Void,
        onRightHalfUp  : @escaping () -> Void,
        
        onLeftHalfDown: @escaping () -> Void,
        onLeftHalfUp  : @escaping () -> Void,
        
        onCenterDown: @escaping () -> Void = {},
        onCenterUp  : @escaping () -> Void = {},
        
        onMaximizeDown: @escaping () -> Void = {},
        onMaximizeUp  : @escaping () -> Void = {},
        
        onNudgeBottomDownDown: @escaping () -> Void = {},
        onNudgeBottomUpDown: @escaping () -> Void = {},
        onNudgeTopUpDown: @escaping () -> Void = {},
        onNudgeTopDownDown: @escaping () -> Void = {},
        
    ) {
        self.rightHalf  = .RightHalf
        self.leftHalf   = .LeftHalf
        self.center     = .Center
        self.maximize   = .Maximize
        
        self.nudgeBottomDown = .NudgeBottomDown
        self.nudgeBottomUp   = .NudgeBottomUp
        self.nudgeTopUp      = .NudgeTopUp
        self.nudgeTopDown    = .NudgeTopDown
        
        modifierDetector.onDoubleTapOption = onOptDoubleTapDown
        modifierDetector.onDoubleTapOptionRelease = onOptDoubleTapUp
        modifierDetector.onDoubleTapControl = onCtrlDoubleTapDown
        modifierDetector.onDoubleTapControlRelease = onCtrlDoubleTapUp
        
        // MARK: - Right Half
        KeyboardShortcuts.onKeyDown(for: self.rightHalf) {
            onRightHalfDown()
        }
        KeyboardShortcuts.onKeyUp(for: self.rightHalf) {
            onRightHalfUp()
        }
        
        

        // MARK: - Left Half
        KeyboardShortcuts.onKeyDown(for: self.leftHalf) {
            onLeftHalfDown()
        }
        KeyboardShortcuts.onKeyUp(for: self.leftHalf) {
            onLeftHalfUp()
        }
        
        // MARK: - Center
        KeyboardShortcuts.onKeyDown(for: self.center) {
            onCenterDown()
        }
        KeyboardShortcuts.onKeyUp(for: self.center) {
            onCenterUp()
        }
        
        // MARK: - Maximize
        KeyboardShortcuts.onKeyDown(for: self.maximize) {
            onMaximizeDown()
        }
        KeyboardShortcuts.onKeyUp(for: self.maximize) {
            onMaximizeUp()
        }
        
        
        
        
        // MARK: - Nudge Bottom Down
        KeyboardShortcuts.onKeyDown(for: self.nudgeBottomDown) {
            onNudgeBottomDownDown()
        }
        
        // MARK: - Nudge Bottom Up
        KeyboardShortcuts.onKeyDown(for: self.nudgeBottomUp) {
            onNudgeBottomUpDown()
        }
        
        // MARK: - Nudge Top Up
        KeyboardShortcuts.onKeyDown(for: self.nudgeTopUp) {
            onNudgeTopUpDown()
        }
        
        // MARK: - Nudge Top Down
        KeyboardShortcuts.onKeyDown(for: self.nudgeTopDown) {
            onNudgeTopDownDown()
        }
    }
}


extension HotKeyCoordinator {
    
    public final class ModifierDoubleTapDetector {
        // MARK: Public API
        var onDoubleTapOption: (() -> Void)?
        var onDoubleTapControl: (() -> Void)?
        var onDoubleTapOptionRelease: (() -> Void)?
        var onDoubleTapControlRelease: (() -> Void)?
        
        // Config
        private let tapLocation: CGEventTapLocation = .cgSessionEventTap
        private let tapPlacement: CGEventTapPlacement = .headInsertEventTap
        private let tapOptions: CGEventTapOptions = .listenOnly   // monitor globally, not intercept
        private let doubleTapWindow: CFTimeInterval = 0.35         // seconds; tweak to taste
        
        // State
        private var tap: CFMachPort?
        private var runLoopSource: CFRunLoopSource?
        private var lastDownTime: [ModifierGroup: CFTimeInterval] = [:]
        private var wasDown: [ModifierGroup: Bool] = [.option: false, .control: false]
        private var doubleTapActive: [ModifierGroup: Bool] = [.option: false, .control: false] // Track if we're in a double-tap state
        
        private var activeGroup: ModifierGroup?
        
        // MARK: Start/Stop
        public func start(with group: ModifierGroup) {
            /// No Need to start with the same group
            if activeGroup == group { return }
            
            stop()
            
            activeGroup = group
            lastDownTime.removeAll()
            wasDown = [.option:false, .control:false]
            doubleTapActive = [.option:false, .control:false]
            
            let mask = (1 << CGEventType.flagsChanged.rawValue)
            let callback: CGEventTapCallBack = { _, type, event, userInfo in
                guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
                let detector = Unmanaged<ModifierDoubleTapDetector>
                    .fromOpaque(userInfo).takeUnretainedValue()
                detector.handle(type: type, event: event)
                return Unmanaged.passUnretained(event)
            }
            
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            tap = CGEvent.tapCreate(
                tap: tapLocation,
                place: tapPlacement,
                options: tapOptions,
                eventsOfInterest: CGEventMask(mask),
                callback: callback,
                userInfo: selfPtr
            )
            
            guard let tap else {
                print("⚠️ Could not create event tap (need Accessibility permission).")
                return
            }
            
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        
        func stop() {
            if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
            if let runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            runLoopSource = nil
            tap = nil
            activeGroup = nil
        }
        
        // MARK: Core handler
        private func handle(type: CGEventType, event: CGEvent) {
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput,
               let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            guard type == .flagsChanged, let ns = NSEvent(cgEvent: event) else { return }
            guard let active = activeGroup else { return }
            
            // Which modifier changed?
            let group: ModifierGroup? = {
                switch ns.keyCode {
                case 58, 61: return .option
                case 59, 62: return .control
                default: return nil
                }
            }()
            
            // Ignore events for the other modifier
            guard let group, group == active else { return }
            
            let flags = ns.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isOptionDown = flags.contains(.option)
            let isControlDown = flags.contains(.control)
            let otherModsDown: Bool = {
                switch group {
                case .option: return flags.contains(.command) || flags.contains(.shift) || flags.contains(.function) || isControlDown
                case .control: return flags.contains(.command) || flags.contains(.shift) || flags.contains(.function) || isOptionDown
                }
            }()
            
            let nowDown = (group == .option ? isOptionDown : isControlDown)
            let previouslyDown = wasDown[group] ?? false
            wasDown[group] = nowDown
            
            // release
            if previouslyDown && !nowDown {
                if doubleTapActive[group] == true {
                    switch group {
                    case .option: onDoubleTapOptionRelease?()
                    case .control: onDoubleTapControlRelease?()
                    }
                    doubleTapActive[group] = false
                }
                return
            }
            
            if otherModsDown { return }
            
            // press
            guard nowDown && !previouslyDown else { return }
            let t = CACurrentMediaTime()
            if let last = lastDownTime[group], (t - last) <= doubleTapWindow {
                doubleTapActive[group] = true
                switch group {
                case .option: onDoubleTapOption?()
                case .control: onDoubleTapControl?()
                }
                lastDownTime[group] = 0
            } else {
                lastDownTime[group] = t
            }
        }
    }
}

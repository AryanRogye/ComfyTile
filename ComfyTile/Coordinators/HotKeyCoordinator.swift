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
    static let windowViewer = Self("WindowViewer")
    static let windowViewerEscapeEarly = Self("WindowViewerEscapeEarly", default: Shortcut(
        .escape,
        modifiers: .option
    ))
    static let primaryLeftStackedHorizontallyTile = Self("PrimaryLeftStackedHorizontallyTile", default: Shortcut(
        .leftBracket,
        modifiers: [.control, .shift]
    ))
    static let primaryRightStackedHorizontallyTile = Self("PrimaryRightStackedHorizontallyTile", default: Shortcut(
        .rightBracket,
        modifiers: [.control, .shift]
    ))
    static let primaryTile = Self("PrimaryTile", default: Shortcut(
        .space,
        modifiers: [.control, .shift]
    ))
}

@MainActor
final class HotKeyCoordinator {
    private let modifierDetector   = ModifierDoubleTapDetector()
    private let globalClickMonitor = GlobalClickMonitor()
    
    public func startModifier(with group: ModifierGroup) {
        modifierDetector.start(with: group)
    }
    public func stopModifier() {
        modifierDetector.stop()
    }
    
    init() {}
    
    func start(
        onPrimaryLeftStackedHorizontallyTile : @escaping() -> Void = {},
        onPrimaryRightStackedHorizontallyTile: @escaping() -> Void = {},
        onPrimaryTile                        : @escaping() -> Void = {},
        onWindowViewer      : @escaping () -> Void = {},
        onWindowViewerUp    : @escaping () -> Void = {},
        onWindowViewerEscapeEarly : @escaping () -> Void = {},
        
        onAutoTile          : @escaping () -> Void = {},
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
        
        modifierDetector.onDoubleTapOption = onOptDoubleTapDown
        modifierDetector.onDoubleTapOptionRelease = onOptDoubleTapUp
        modifierDetector.onDoubleTapControl = onCtrlDoubleTapDown
        modifierDetector.onDoubleTapControlRelease = onCtrlDoubleTapUp
        
        KeyboardShortcuts.onKeyDown(for: .primaryLeftStackedHorizontallyTile) {
            onPrimaryLeftStackedHorizontallyTile()
        }
        KeyboardShortcuts.onKeyDown(for: .primaryRightStackedHorizontallyTile) {
            onPrimaryRightStackedHorizontallyTile()
        }
        KeyboardShortcuts.onKeyDown(for: .primaryTile) {
            onPrimaryTile()
        }

        KeyboardShortcuts.onKeyDown(for: .windowViewer) {
            onWindowViewer()
        }
        KeyboardShortcuts.onKeyDown(for: .windowViewerEscapeEarly) {
            onWindowViewerEscapeEarly()
        }
        KeyboardShortcuts.onKeyUp(for: .windowViewer) {
            onWindowViewerUp()
        }
        
        // MARK: - Right Half
        KeyboardShortcuts.onKeyDown(for: .RightHalf) {
            onRightHalfDown()
        }
        KeyboardShortcuts.onKeyUp(for: .RightHalf) {
            onRightHalfUp()
        }
        
        // MARK: - Left Half
        KeyboardShortcuts.onKeyDown(for: .LeftHalf) {
            onLeftHalfDown()
        }
        KeyboardShortcuts.onKeyUp(for: .LeftHalf) {
            onLeftHalfUp()
        }
        
        // MARK: - Center
        KeyboardShortcuts.onKeyDown(for: .Center) {
            onCenterDown()
        }
        KeyboardShortcuts.onKeyUp(for: .Center) {
            onCenterUp()
        }
        
        // MARK: - Maximize
        KeyboardShortcuts.onKeyDown(for: .Maximize) {
            onMaximizeDown()
        }
        KeyboardShortcuts.onKeyUp(for: .Maximize) {
            onMaximizeUp()
        }
        
        // MARK: - Nudge Bottom Down
        KeyboardShortcuts.onKeyDown(for: .NudgeBottomDown) {
            onNudgeBottomDownDown()
        }
        
        // MARK: - Nudge Bottom Up
        KeyboardShortcuts.onKeyDown(for: .NudgeBottomUp) {
            onNudgeBottomUpDown()
        }
        
        // MARK: - Nudge Top Up
        KeyboardShortcuts.onKeyDown(for: .NudgeTopUp) {
            onNudgeTopUpDown()
        }
        
        // MARK: - Nudge Top Down
        KeyboardShortcuts.onKeyDown(for: .NudgeTopDown) {
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
            print("Started Modifier Double Tap Detector")
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
                case .none:
                    return false
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
                    case .none: break
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
                case .none: break
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

extension HotKeyCoordinator {
    @MainActor
    final class GlobalClickMonitor {
        
        private var tap: CFMachPort?
        private var runLoopSource: CFRunLoopSource?
        
        /// Flag to know if the modifier key is pressed locally or not
        private(set) var isLocallyPressingModifier: Bool = false
        
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
            
            print("🔄 Starting CGEventTap mouse monitor...")
            
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
            
            print("✅ CGEventTap mouse monitor started successfully")
        }
        
        public func stop() {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: false)
                print("🛑 Mouse monitor stopped")
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
//                print("🖱️ CGEventTap: Left Mouse Down")
                isLocallyPressingModifier = true
                onClick?() // Call the stored closure
            case .leftMouseUp:
//                print("🖱️ CGEventTap: Left Mouse Up")
                isLocallyPressingModifier = false
            default:
                break
            }
        }
    }
}

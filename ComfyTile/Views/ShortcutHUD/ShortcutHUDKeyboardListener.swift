//
//  ShortcutHUDKeyboardListener.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/10/25.
//

import SwiftUI
import Combine
import Carbon
import ApplicationServices

@MainActor
class KeyboardManager: ObservableObject {
    @Published var pressedKeys: [PressedKey] = []
    
    private var downKeyCodes: Set<UInt16> = []
    private var previousFlags: CGEventFlags = []
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {}
    
    func startMonitoring() {
        // Reset state
        previousFlags = CGEventFlags(rawValue: 0)
        downKeyCodes.removeAll()
        pressedKeys.removeAll()
        
        // Create event tap for key events
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
        (1 << CGEventType.keyUp.rawValue) |
        (1 << CGEventType.flagsChanged.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<KeyboardManager>.fromOpaque(refcon).takeUnretainedValue()
                
                Task { @MainActor in
                    manager.handleCGEvent(type: type, event: event)
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
    }
    
    func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
    }
    
    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        switch type {
        case .flagsChanged:
            handleFlagsChanged(flags: flags)
            
        case .keyDown:
            downKeyCodes.insert(keyCode)
            if let key = keyString(from: keyCode) {
                if !pressedKeys.contains(.character(key)) {
                    pressedKeys.append(.character(key))
                }
            }
            
        case .keyUp:
            downKeyCodes.remove(keyCode)
            if let key = keyString(from: keyCode) {
                pressedKeys.removeAll { $0 == .character(key) }
            }
            
        default:
            break
        }
    }
    
    private func handleFlagsChanged(flags: CGEventFlags) {
        // Check each modifier
        for mod in PressedKey.Modifier.allCases {
            let modFlag = mod.cgFlag
            let wasPressed = previousFlags.contains(modFlag)
            let isPressed = flags.contains(modFlag)
            
            if isPressed && !wasPressed {
                pressedKeys.append(.modifier(mod))
            } else if !isPressed && wasPressed {
                pressedKeys.removeAll { $0 == .modifier(mod) }
            }
        }
        
        previousFlags = flags
    }
    
    private func keyString(from keyCode: UInt16) -> String? {
        switch keyCode {
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 51: return "⌫"
        case 53: return "⎋"
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "␣"
        default:
            // Convert keycode to character
            let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
            
            guard let data = layoutData else { return nil }
            let keyLayout = unsafeBitCast(data, to: CFData.self)
            
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length = 0
            
            let status = UCKeyTranslate(
                unsafeBitCast(CFDataGetBytePtr(keyLayout), to: UnsafePointer<UCKeyboardLayout>.self),
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysMask),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
            
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: length).lowercased()
        }
    }
}

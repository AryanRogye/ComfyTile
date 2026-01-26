//
//  ModifierGroup.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/9/25.
//
import AppKit
/// Which modifier gesture to detect
enum ModifierGroup: String, CaseIterable {
    case none   = "None"
    case option = "Option"
    case control = "Control"
}

enum PressedKey: Hashable, CustomStringConvertible {
    case modifier(Modifier)
    case character(String)
    
    // The Modifier enum is now nested inside for organization
    enum Modifier: String, CaseIterable {
        case command = "⌘"
        case shift   = "⇧"
        case option = "⌥"
        case control = "⌃"
        
        var flag: NSEvent.ModifierFlags {
            switch self {
            case .command: return .command
            case .shift  : return .shift
            case .option:  return .option
            case .control: return .control
            }
        }
        
        var cgFlag: CGEventFlags {
            switch self {
            case .command: return .maskCommand
            case .shift: return .maskShift
            case .option: return .maskAlternate
            case .control: return .maskControl
            }
        }
    }
    
    // Helper to get a displayable string for the UI
    var description: String {
        switch self {
        case .modifier(let mod):
            return mod.rawValue
        case .character(let char):
            return char.uppercased()
        }
    }
}


//
//  Modifier.swift
//  LocalShortcuts
//
//  Created by Aryan Rogye on 12/4/25.
//

import AppKit

extension LocalShortcuts {
    public enum Modifier: String, Codable, CaseIterable, Hashable {
        case command = "⌘"
        case shift   = "⇧"
        case option = "⌥"
        case control = "⌃"
        
        
        var flag: NSEvent.ModifierFlags {
            switch self {
            case .command: return .command
            case .shift:   return .shift
            case .option:  return .option
            case .control: return .control
            }
        }
        
        @MainActor public static func activeModifiers(from event: NSEvent) -> [LocalShortcuts.Modifier] {
            return LocalShortcuts.Modifier.allCases.filter { modifier in
                event.modifierFlags.contains(modifier.flag)
            }
        }
    }
}

public extension Set where Element == LocalShortcuts.Modifier {
    func matches(event: NSEvent) -> Bool {
        let eventFlags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let neededFlags = self.reduce(into: NSEvent.ModifierFlags()) { $0.insert($1.flag) }
        return eventFlags == neededFlags
    }
}

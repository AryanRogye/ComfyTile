//
//  Key.swift
//  LocalShortcuts
//
//  Created by Aryan Rogye on 12/4/25.
//

import AppKit

extension LocalShortcuts {
    @MainActor
    public enum Key: String, Codable, CaseIterable, Hashable {
        // Letters
        case a, A,
             b, B,
             c, C,
             d, D,
             e, E,
             f, F,
             g, G,
             h, i, j, k, l, m,
             n, o, p, q, r, s, t, u,
             
             v, V,
             w, W,
             x, X,
             y, Y,
             z, Z
        
        // Numbers
        case zero = "0"
        case one  = "1"
        case two  = "2"
        case three = "3"
        case four  = "4"
        case five  = "5"
        case six   = "6"
        case seven = "7"
        case eight = "8"
        case nine  = "9"
            
        case semi_colon = ":"
        case period = "."
        case comma  = ","
        
        case dollar = "$"
        case underscore = "_"
        
        // Common specials
        case space
        case escape
        case returnOrEnter
        case tab
        case delete // backspace
        
        case equal
        case plus
        case minus
        
        case leftArrow
        case rightArrow
        case upArrow
        case downArrow
        
        public static func activeKeys(event: NSEvent) -> [Key] {
            // Attempt to create a Key from the event; if successful, wrap it in an array.
            if let key = Key(from: event) {
                return [key]
            }
            return []
        }
    }
}

extension LocalShortcuts.Key {
    /// Create a Key from an NSEvent (for local monitors)
    init?(from event: NSEvent) {
        var key: LocalShortcuts.Key? = nil
        
        // First try character-based keys
        if let chars = event.charactersIgnoringModifiers, let first = chars.first {
            switch first {
            case "a": key = .a
            case "A": key = .A
            case "b": key = .b
            case "B": key = .B
            case "c": key = .c
            case "C": key = .C
            case "d": key = .d
            case "D": key = .D
            case "e": key = .e
            case "E": key = .E
            case "f": key = .f
            case "F": key = .F
            case "g": key = .g
            case "G": key = .G
            case "h": key = .h
            case "i": key = .i
            case "j": key = .j
            case "k": key = .k
            case "l": key = .l
            case "m": key = .m
            case "n": key = .n
            case "o": key = .o
            case "p": key = .p
            case "q": key = .q
            case "r": key = .r
            case "s": key = .s
            case "t": key = .t
            case "u": key = .u
            case "v": key = .v
            case "V": key = .V
            case "w": key = .w
            case "x": key = .x
            case "X": key = .X
            case "y": key = .y
            case "Y": key = .Y
            case "z": key = .z
            case "Z": key = .Z
            case ";", ":": key = .semi_colon
            case ".": key = .period
            case ">": key = .period
            case ",": key = .comma
            case "<": key = .comma
                
            case "0": key = .zero
            case "1": key = .one
            case "2": key = .two
            case "3": key = .three
            case "4": key = .four
            case "5": key = .five
            case "6": key = .six
            case "7": key = .seven
            case "8": key = .eight
            case "9": key = .nine
                
            case "=": key = .equal
            case "-": key = .minus
            case "_": key = .underscore
            case "+": key = .plus
            case "$": key = .dollar
                
            case " ": key = .space
            case "\r": key = .returnOrEnter
            case "\t": key = .tab
            case "\u{8}": key = .delete
                
            default:
                break
            }
        }
        
        if let key { self = key; return }
        
        // Fallback to keyCode for non-character keys
        switch event.keyCode {
        case 53: self = .escape
        case 51: self = .delete
        case 36: self = .returnOrEnter
        case 48: self = .tab
        case 49: self = .space
        case 47: self = .period
        case 43: self = .comma
        case 41: self = .semi_colon
        case 123: self = .leftArrow
        case 124: self = .rightArrow
        case 125: self = .downArrow
        case 126: self = .upArrow
        default:
            return nil
        }
    }
    
    func matches(event: NSEvent) -> Bool {
        return LocalShortcuts.Key(from: event) == self
    }
}

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
    
    init(
        onRightHalfDown: @escaping () -> Void,
        onLeftHalfDown: @escaping () -> Void,
        onCenterDown: @escaping () -> Void = {},
        onMaximizeDown: @escaping () -> Void = {},
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
        
        // MARK: - Right Half
        KeyboardShortcuts.onKeyDown(for: self.rightHalf) {
            onRightHalfDown()
        }
        
        // MARK: - Left Half
        KeyboardShortcuts.onKeyDown(for: self.leftHalf) {
            onLeftHalfDown()
        }
        
        // MARK: - Center
        KeyboardShortcuts.onKeyDown(for: self.center) {
            onCenterDown()
        }
        
        // MARK: - Maximize
        KeyboardShortcuts.onKeyDown(for: self.maximize) {
            onMaximizeDown()
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

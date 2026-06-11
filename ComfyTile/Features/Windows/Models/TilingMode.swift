//
//  TilingMode.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import KeyboardShortcuts

enum TilingMode: String, CaseIterable {
    case rightHalf
    case leftHalf
    case bottomHalf
    case topHalf
    case center
    case fullscreen
    case nudgeBottomUp
    case nudgeBottomDown
    case nudgeTopDown
    case nudgeTopUp
    
    var hotkey: KeyboardShortcuts.Name {
        switch self {
        case .topHalf:
            KeyboardShortcuts.Name.TopHalf
        case .bottomHalf:
            KeyboardShortcuts.Name.BottomHalf
        case .rightHalf:
            KeyboardShortcuts.Name.RightHalf
        case .leftHalf:
            KeyboardShortcuts.Name.LeftHalf
        case .center:
            KeyboardShortcuts.Name.Center
        case .fullscreen:
            KeyboardShortcuts.Name.Maximize
        case .nudgeBottomUp:
            KeyboardShortcuts.Name.NudgeBottomUp
        case .nudgeBottomDown:
            KeyboardShortcuts.Name.NudgeBottomDown
        case .nudgeTopDown:
            KeyboardShortcuts.Name.NudgeTopDown
        case .nudgeTopUp:
            KeyboardShortcuts.Name.NudgeTopUp
        }
    }
    
    var tileShape: TileShape {
        switch self {
        case .bottomHalf:
                .bottomHalf
        case .topHalf:
                .topHalf
        case .rightHalf:
                .right
        case .leftHalf:
                .left
        case .center:
                .center
        case .fullscreen:
                .full
        case .nudgeBottomUp:
                .nudgeBottomUp
        case .nudgeBottomDown:
                .nudgeBottomDown
        case .nudgeTopDown:
                .nudgeTopDown
        case .nudgeTopUp:
                .nudgeTopUp
        }
    }
}

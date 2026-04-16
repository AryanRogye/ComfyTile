//
//  DefaultsKeys.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Defaults
import SwiftUI

extension Defaults.Keys {
    
    /// Nudge Step for "nudging" this isnt really used right now
    static let nudgeStep = Key<Int>("NudgeStep", default: 2)
    static let modiferKey = Key<String>("ModiferKey", default: "Control")
    
    /// If Animations while tiling is shown or not
    static let showTilingAnimations = Key<Bool>("ShowTilingAnimations", default: false)
    
    /// placement of where the tabs are in the menu bar
    static let comfyTileTabPlacement = Key<ComfyTileTabPlacement>("ComfyTileTabPlacement", default: .bottom)
    
    /// -------------------------------------------------------------------------------------------------
    /// HighlightWindow
    /// -------------------------------------------------------------------------------------------------
    /// This is a toggle but saved in the defaults
    /// this triggers showing a highlight ring around the window
    static let highlightFocusedWindow = Key<Bool>("HighlightFocusedWindow", default: false)
    
    /// Highlight ring color
    static let highlightFocusedWindowColor = Key<Color>("HighlightFocusedWindowColor", default: .yellow)
    
    /// Highlight ring width
    static let highlightedFocusedWindowWidth = Key<Double>("HighlightedFocusedWindowWidth", default: 1.5)
    
    /// -------------------------------------------------------------------------------------------------
    /// SUPER FOCUS
    /// -------------------------------------------------------------------------------------------------
    /// Super focusing a window, a window around black
    static let superFocusWindow = Key<Bool>("SuperFocusWindow", default: false)
    
    /// Color we use to super focus
    static let superFocusColor = Key<Color>("SuperFocusColor", default: .black)
    
    /// usually min of 10, and high of 100 is nice
    static let centerTilingPadding = Key<Double>("CenterTilingPadding", default: 40.0)
    
    /// This allows us to focus a apps window on the window switcher
    static let allowFocusAppWindowOnWindowSwitcher = Key<Bool>("AllowFocusAppWindowOnWindowSwitcher", default: true)
}

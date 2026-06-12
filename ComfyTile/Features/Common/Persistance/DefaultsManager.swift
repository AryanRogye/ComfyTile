//
//  DefaultsManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Defaults
import Foundation
import SwiftUI

@Observable @MainActor
class DefaultsManager {
    var nudgeStep: Int = Defaults[.nudgeStep]
    var modiferKey: ModifierGroup = ModifierGroup(rawValue: Defaults[.modiferKey]) ?? .control
    
    var useWindowInsteadOfMenuBar: Bool = Defaults[.useWindowInsteadOfMenuBar] {
        didSet {
            Defaults[.useWindowInsteadOfMenuBar] = useWindowInsteadOfMenuBar
        }
    }
    
    var enableTileRing: Bool = Defaults[.enableTileRing] {
        didSet {
            Defaults[.enableTileRing] = enableTileRing
        }
    }
    
    var tileRingActivationDiameter: Double = Defaults[.tileRingActivationDiameter] {
        didSet {
            Defaults[.tileRingActivationDiameter] = tileRingActivationDiameter
        }
    }
    
    var tileRingOuterPadding: Double = Defaults[.tileRingOuterPadding] {
        didSet {
            Defaults[.tileRingOuterPadding] = tileRingOuterPadding
        }
    }
    
    var enableSmartTiling: Bool = Defaults[.enableSmartTiling] {
        didSet {
            Defaults[.enableSmartTiling] = enableSmartTiling
        }
    }
    
    var enableLayoutCycling: Bool = Defaults[.enableLayoutCycling] {
        didSet {
            Defaults[.enableLayoutCycling] = enableLayoutCycling
            if !enableLayoutCycling {
                enableSmartTiling = false
            }
        }
    }
    
    var allowFocusAppWindowOnWindowSwitcher: Bool = Defaults[.allowFocusAppWindowOnWindowSwitcher] {
        didSet {
            Defaults[.allowFocusAppWindowOnWindowSwitcher] = allowFocusAppWindowOnWindowSwitcher
        }
    }
    
    var centerTilingPadding: Double = Defaults[.centerTilingPadding] {
        didSet {
            Defaults[.centerTilingPadding] = centerTilingPadding
        }
    }

    var advancedCenterTilingPadding: Bool = Defaults[.advancedCenterTilingPadding] {
        didSet {
            Defaults[.advancedCenterTilingPadding] = advancedCenterTilingPadding
        }
    }

    var highlightFocusedWindow: Bool = Defaults[.highlightFocusedWindow] {
        didSet {
            Defaults[.highlightFocusedWindow] = highlightFocusedWindow
        }
    }
    
    var highlightFocusedWindowColor: Color = Defaults[.highlightFocusedWindowColor] {
        didSet {
            Defaults[.highlightFocusedWindowColor] = highlightFocusedWindowColor
        }
    }
    
    var highlightedFocusedWindowWidth : Double = Defaults[.highlightedFocusedWindowWidth] {
        didSet {
           Defaults[.highlightedFocusedWindowWidth]  = highlightedFocusedWindowWidth
        }
    }
    
    var superFocusWindow: Bool = Defaults[.superFocusWindow] {
        didSet {
            Defaults[.superFocusWindow] = superFocusWindow
        }
    }
    var superFocusColor: Color = Defaults[.superFocusColor] {
        didSet {
            Defaults[.superFocusColor] = superFocusColor
        }
    }
    
    var showTilingAnimations: Bool = Defaults[.showTilingAnimations] {
        didSet {
            Defaults[.showTilingAnimations] = showTilingAnimations
        }
    }
    
    var comfyTileTabPlacement: ComfyTileTabPlacement = Defaults[.comfyTileTabPlacement] {
        didSet {
            Defaults[.comfyTileTabPlacement] = comfyTileTabPlacement
        }
    }
    
    public func saveModiferKey() {
        Defaults[.modiferKey] = modiferKey.rawValue
    }
    
    public func saveNudgeStep() {
        Defaults[.nudgeStep] = nudgeStep
    }
}

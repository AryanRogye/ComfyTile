//
//  DefaultsManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Defaults
import Foundation

@Observable @MainActor
class DefaultsManager {
    var nudgeStep: Int = Defaults[.nudgeStep]
    var modiferKey: ModifierGroup = ModifierGroup(rawValue: Defaults[.modiferKey]) ?? .control
    
    
    var highlightFocusedWindow: Bool = Defaults[.highlightFocusedWindow] {
        didSet {
            Defaults[.highlightFocusedWindow] = highlightFocusedWindow
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

//
//  Defaults.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/5/25.
//

import Defaults
import Combine
import Foundation

extension Defaults.Keys {
    static let nudgeStep = Key<Int>("NudgeStep", default: 2)
    static let modiferKey = Key<String>("ModiferKey", default: "Control")
    static let showTilingAnimations = Key<Bool>("ShowTilingAnimations", default: true)
}

@Observable @MainActor
class DefaultsManager {
    var nudgeStep: Int = Defaults[.nudgeStep]
    var modiferKey: ModifierGroup = ModifierGroup(rawValue: Defaults[.modiferKey]) ?? .control
    
    
    var showTilingAnimations: Bool = Defaults[.showTilingAnimations] {
        didSet {
            Defaults[.showTilingAnimations] = showTilingAnimations
        }
    }
    
    public func saveModiferKey() {
        Defaults[.modiferKey] = modiferKey.rawValue
    }
    
    public func saveNudgeStep() {
        Defaults[.nudgeStep] = nudgeStep
    }
}

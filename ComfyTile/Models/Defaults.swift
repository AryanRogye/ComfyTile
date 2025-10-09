//
//  Defaults.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/5/25.
//

import Defaults
import Combine

extension Defaults.Keys {
    static let nudgeStep = Key<Int>("NudgeStep", default: 2)
    static let modiferKey = Key<String>("ModiferKey", default: "Control")
}

class DefaultsManager : ObservableObject {
    @Published var nudgeStep: Int = Defaults[.nudgeStep]
    @Published var modiferKey: ModifierGroup = ModifierGroup(rawValue: Defaults[.modiferKey]) ?? .control
    
    public func saveModiferKey() {
        Defaults[.modiferKey] = modiferKey.rawValue
    }
    
    public func saveNudgeStep() {
        Defaults[.nudgeStep] = nudgeStep
    }
}

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
}

class DefaultsManager : ObservableObject {
    @Published var nudgeStep: Int = Defaults[.nudgeStep]
    
    public func saveNudgeStep() {
        Defaults[.nudgeStep] = nudgeStep
    }
}

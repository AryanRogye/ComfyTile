//
//  DefaultsKeys.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Defaults

extension Defaults.Keys {
    static let nudgeStep = Key<Int>("NudgeStep", default: 2)
    static let modiferKey = Key<String>("ModiferKey", default: "Control")
    static let showTilingAnimations = Key<Bool>("ShowTilingAnimations", default: false)
    static let comfyTileTabPlacement = Key<ComfyTileTabPlacement>("ComfyTileTabPlacement", default: .bottom)
    static let highlightFocusedWindow = Key<Bool>("HighlightFocusedWindow", default: false)
}

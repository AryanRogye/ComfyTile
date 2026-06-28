//
//  ComfyTileGlassStyle.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI
import Defaults

public enum ComfyTileGlassStyle: String, CaseIterable, Defaults.Serializable {
    case regular = "Regular"
    case glass = "Glass"
    
    var style: Glass {
        switch self {
        case .glass:
            return Glass.clear
        case .regular:
            return Glass.regular
        }
    }
}

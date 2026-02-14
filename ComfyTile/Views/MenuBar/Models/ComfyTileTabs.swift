//
//  ComfyTileTabs.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

enum ComfyTileTabs: String, CaseIterable {
    case tile = "Tile"
    case layout = "Layout"
    case setLayouts = "Set Layouts"
    case settings = "Settings"
    
    var icon: Image? {
        switch self {
        case .layout: return Image("ComfyTile_Layout_Icon")
        case .settings: return Image(systemName: "gear")
        case .setLayouts: return Image(systemName: "square.and.arrow.up")
        case .tile: return Image("ComfyTile_Tile_Icon")
        }
    }
}

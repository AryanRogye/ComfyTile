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
    case settings = "Settings"
#if DEBUG
    case debug = "debug"
#endif

    var icon: Image? {
        switch self {
        case .layout: return Image("ComfyTile_Layout_Icon")
        case .settings: return Image(systemName: "gear")
        case .tile: return Image("ComfyTile_Tile_Icon")
#if DEBUG
        case .debug: return Image(systemName: "hammer.fill")
#endif
        }
    }
}

//
//  ComfyTileMenuBarViewModel.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Foundation

@Observable
@MainActor
final class ComfyTileMenuBarViewModel {
    var width: CGFloat = 400
    var height: CGFloat = 300
    
    var tabPlacement : ComfyTileTabPlacement = .bottom
    var selectedTab: ComfyTileTabs = .tile
}

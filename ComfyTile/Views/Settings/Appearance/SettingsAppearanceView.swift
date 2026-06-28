//
//  SettingsAppearanceView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI

// MARK: - Settings Tab Position
struct SettingsTabPositionView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        Picker("Settings Tab Position", selection: $defaultsManager.comfyTileTabPlacement) {
            ForEach(ComfyTileTabPlacement.allCases, id: \.self) { tab in
                Text(tab.rawValue)
            }
        }
    }
}

struct SettingsGlassStyle: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        if !defaultsManager.useWindowInsteadOfMenuBar {
            Picker("Settings Glass Stlye", selection: $defaultsManager.comfyTileGlassStyle) {
                ForEach(ComfyTileGlassStyle.allCases, id: \.self) { glass in
                    Text(glass.rawValue)
                }
            }
        }
    }
}

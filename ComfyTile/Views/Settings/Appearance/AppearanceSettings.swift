//
//  AppearanceSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/22/26.
//

import SwiftUI

struct AppearanceSettings: View {
    
    @Bindable var defaultsManager : DefaultsManager
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Tab Bar Position", selection: $defaultsManager.comfyTileTabPlacement) {
                    ForEach(
                        ComfyTileTabPlacement.allCases,
                        id: \.self
                    ) { tab in
                        Text(tab.rawValue)
                    }
                }
                Toggle("Highlight focused window", isOn: $defaultsManager.highlightFocusedWindow)
            }
            Section("Animations") {
                Toggle("Tiling Animations", isOn: $defaultsManager.showTilingAnimations).toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

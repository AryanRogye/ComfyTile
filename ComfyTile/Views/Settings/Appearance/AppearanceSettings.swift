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
            Section("Tab Bar") {
                Picker("Position", selection: $defaultsManager.comfyTileTabPlacement) {
                    ForEach(ComfyTileTabPlacement.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                    }
                }
            }
            
            Section("Focused Window") {
                Toggle("Highlight focused window", isOn: $defaultsManager.highlightFocusedWindow)
                Toggle("Super Focus Window", isOn: $defaultsManager.superFocusWindow)
            }
            
            Section("Animations") {
                Toggle("Tiling animations", isOn: $defaultsManager.showTilingAnimations)
                    .toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

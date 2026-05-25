//
//  GeneralSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct GeneralSettings: View {
    
    @Bindable var defaultsManager : DefaultsManager
    
    var body: some View {
        Form {
            Section("Tiling") {
                CenterTilingGeneralView(defaultsManager: defaultsManager)
                CenterTilingAdvancedGeneralView(defaultsManager: defaultsManager)
                TilingSnapBehavior(defaultsManager: defaultsManager)
                SmartTilingBehavior(defaultsManager: defaultsManager)
            }

            Section("Window Switching") {
                WindowSwitcherGeneralView(defaultsManager: defaultsManager)
            }
            /// About Section
            Section("About") {
                UpdatesGeneralView()
                Button("Quit") {
                    NSApplication.shared.terminate(self)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

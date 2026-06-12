//
//  GeneralSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct GeneralSettings: View {
    
    @Bindable var defaultsManager : DefaultsManager
    @Environment(ComfyTileMenuBarViewModel.self) var menuBarVM

    var body: some View {
        Form {
            Section("Tiling") {
                CenterTilingGeneralView(defaultsManager: defaultsManager, menuBarVM: menuBarVM)
                CenterTilingAdvancedGeneralView(defaultsManager: defaultsManager, menuBarVM: menuBarVM)
                TilingSnapBehavior(defaultsManager: defaultsManager)
                SmartTilingBehavior(defaultsManager: defaultsManager)
                TileRingGeneralView(defaultsManager: defaultsManager)
                TileRingHotKey(defaultsManager: defaultsManager)
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

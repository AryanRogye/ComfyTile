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
                TileRingActivationDiameter(defaultsManager: defaultsManager, menuBarVM: menuBarVM)
            }

            Section("Window Switching") {
                WindowSwitcherGeneralView(defaultsManager: defaultsManager)
            }
            /// About Section
            Section("About") {
                UpdatesGeneralView()
                ConvertToWindow(defaultsManager: defaultsManager)
                Button("Quit") {
                    NSApplication.shared.terminate(self)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

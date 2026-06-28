//
//  AppearanceSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/22/26.
//

import SwiftUI
import KeyboardShortcuts

struct AppearanceSettings: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        Form {
            Section("Animations") {
                TilingAnimationsView(defaultsManager: defaultsManager)
            }
            
            Section("Settings") {
                SettingsGlassStyle(defaultsManager: defaultsManager)
                SettingsTabPositionView(defaultsManager: defaultsManager)
            }
            
            Section("Focused Window") {
                HighlightFocusedWindowView(defaultsManager: defaultsManager)
                HighlightFocusedWindowColorView(
                    defaultsManager: defaultsManager,
                )
                HighlightFocusedWindowWidthView(defaultsManager: defaultsManager)
                FocusedWindowHighlightWarningView()
                SuperFocusWindowView(defaultsManager: defaultsManager)
                SuperFocusHotKeyView()
                SuperFocusColorView(
                    defaultsManager: defaultsManager,
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

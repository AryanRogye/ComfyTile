//
//  SettingsView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/7/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct SettingsView: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    
    var body: some View {
        @Bindable var defaultsManager = defaultsManager
        Form {
            Section("Animations") {
                Toggle("Tiling Animations", isOn: $defaultsManager.showTilingAnimations).toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 500)
    }
}

#Preview {
    SettingsView()
}

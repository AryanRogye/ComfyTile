//
//  SettingsView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/7/25.
//

import SwiftUI
import ComfyLogger
import Sparkle

enum SettingsTab: String, CaseIterable {
    case general = "General"
}

struct SettingsView: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    @Environment(SettingsViewModel.self) var settingsVM
    
    private var borderColor: Color {
        Color.secondary
    }
    private var strokeColor: Color {
        borderColor.opacity(0.2)
    }
    
    var body: some View {
        @Bindable var settingsVM = settingsVM
        VStack(spacing: 0){
            if defaultsManager.comfyTileTabPlacement == .bottom {
                SettingsTopBar() {
                    settingsVM.isSidebarOpen.toggle()
                }
                .transition(.move(edge: .bottom).combined(with: .slide))
            }
            
            HStack(spacing: 0) {
                if settingsVM.isSidebarOpen {
                    SettingsSidebar(selected: $settingsVM.selectedTab)
                        .transition(.move(edge: .leading))
                }
                
                VStack{strokeColor}.frame(maxWidth: 0.5)
                
                VStack {
                    SettingsContent()
                }
            }
            .animation(.snappy, value: settingsVM.isSidebarOpen)
            
            
            if defaultsManager.comfyTileTabPlacement == .top {
                SettingsTopBar() {
                    settingsVM.isSidebarOpen.toggle()
                }
                .transition(.move(edge: .bottom).combined(with: .slide))
            }
        }
        .animation(.snappy(duration: 0.15, extraBounce: 0.1), value: defaultsManager.comfyTileTabPlacement)
    }
}

#Preview {
    SettingsView()
}

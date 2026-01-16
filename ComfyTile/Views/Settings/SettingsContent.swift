//
//  SettingsContent.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI
import ComfyLogger

struct SettingsContent: View {
    
    @Environment(SettingsViewModel.self) var settingsVM
    @Environment(DefaultsManager.self) var defaultsManager
    
    var body: some View {
        switch settingsVM.selectedTab {
        case .log:
            LogSettings()
        case .general:
            GeneralSettings(defaultsManager: defaultsManager)
        }
    }
}

struct LogSettings: View {
    
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search For Title", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .stroke(.secondary.opacity(0.2), style: .init(lineWidth: 0.5))
                    }
            }
            ComfyLogger.ComfyLoggerView(names: [
                ComfyLogger.Updater,
                ComfyLogger.WindowServerBridge,
                ComfyLogger.WindowSplitManager,
            ], filter: $searchText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

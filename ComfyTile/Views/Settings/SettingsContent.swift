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
    @Environment(ComfyTileMenuBarViewModel.self) var comfyTileMenuBarVM
    
    var body: some View {
        switch settingsVM.selectedTab {
        case .appereance:
            AppearanceSettings(defaultsManager: defaultsManager)
        case .log:
            LogSettings()
        case .general:
            GeneralSettings(defaultsManager: defaultsManager)
        case .layoutBuilder:
            if comfyTileMenuBarVM.deferLayoutBuilderRendering {
                LayoutBuilderLoadingView()
            } else {
                LayoutBuilderSettings(defaultsManager: defaultsManager)
            }
        }
    }
}

private struct LayoutBuilderLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Preparing Layout Builder...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

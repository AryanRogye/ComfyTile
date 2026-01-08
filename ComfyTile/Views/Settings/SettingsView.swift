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
    case logs = "Logs"
}

struct SettingsView: View {
    
    @State private var selectedTab: SettingsTab = .general
    @Environment(DefaultsManager.self) var defaultsManager
    
    var body: some View {
        @Bindable var defaultsManager = defaultsManager
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    // Use NavigationLink or Text with tag for selection
                    NavigationLink(value: tab) {
                        Text(tab.rawValue)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250) // Optional styling
            
        } detail: {
            // 2. The actual view content goes in detail
            switch selectedTab {
            case .general:
                GeneralSettings(defaultsManager: defaultsManager)
            case .logs:
                ComfyLogger.ComfyLoggerView(
                    names: [
                        ComfyLogger.WindowSplitManager
                    ]
                )
            }
        }
    }
}

struct GeneralSettings: View {
    
    @Environment(UpdateController.self) var updateController
    @Bindable var defaultsManager : DefaultsManager
    
    // MARK: - App Version Number
    private var appVersion: some View {
        Text("\(Bundle.main.versionNumber)")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
    }
    
    // MARK: - App Build Number
    private var appBuild: some View {
        Text("\(Bundle.main.buildNumber)")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
    }
    
    var body: some View {
        Form {
            Section("Animations") {
                Toggle("Tiling Animations", isOn: $defaultsManager.showTilingAnimations).toggleStyle(.switch)
            }
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    appVersion
                }
                HStack {
                    Text("Build")
                    Spacer()
                    appBuild
                }
                CheckForUpdatesView(updater: updateController.updateController().updater)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 500)
    }
}

#Preview {
    SettingsView()
}

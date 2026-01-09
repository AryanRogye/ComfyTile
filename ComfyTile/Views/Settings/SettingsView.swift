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
                        ComfyLogger.WindowSplitManager,
                        ComfyLogger.Updater,
                        ComfyLogger.WindowElement
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
                
                if let updateNotFoundError = updateController.updaterVM.updateNotFoundError,
                    updateController.updaterVM.showUpdateNotFoundError {
                    Text(updateNotFoundError)
                    Button {
                        updateController.updaterVM.updateNotFoundError = nil
                        updateController.updaterVM.showUpdateNotFoundError = false
                        updateController.updaterVM.showUserInitiatedUpdate = false
                    } label: {
                        Text("Ok")
                    }
                } else {
                    if updateController.updaterVM.showUserInitiatedUpdate {
                        HStack {
                            Button {
                                updateController.updaterVM.cancelUserInitiatedUpdate()
                            } label: {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                            }
                            
                            ProgressView()
                                .progressViewStyle(.linear)
                                .frame(maxWidth: .infinity)
                        }
                        
                    } else {
                        CheckForUpdatesView(updater: updateController.updater)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 500)
        .animation(.easeInOut, value: updateController.updaterVM.showUserInitiatedUpdate)
    }
}

#Preview {
    SettingsView()
}

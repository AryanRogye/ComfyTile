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

// MARK: - Center Tiling Settings
struct CenterTilingGeneralView: View {
    @Bindable var defaultsManager : DefaultsManager
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Center Tiling Padding")
                Spacer()
                Text("\(Int(defaultsManager.centerTilingPadding)) px")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: $defaultsManager.centerTilingPadding, in: 10...100, step: 1) {
                EmptyView()
            } minimumValueLabel: {
                Text("10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Updates General View
struct UpdatesGeneralView: View {
    @Environment(UpdateController.self) var updateController

    var body: some View {
        VStack {
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
        .animation(.easeInOut, value: updateController.updaterVM.showUserInitiatedUpdate)
    }
}

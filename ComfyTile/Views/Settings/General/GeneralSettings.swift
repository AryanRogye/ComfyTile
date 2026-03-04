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
                HStack(alignment: .center) {
                    Text("Center Tiling Padding \(Int(defaultsManager.centerTilingPadding))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        Slider(value: $defaultsManager.centerTilingPadding, in: 10...100, step: 1)
                            .frame(maxWidth: .infinity)
                        HStack {
                            Text("10")
                                .foregroundStyle(.secondary)
                                .font(Font.caption.bold())
                            Spacer()
                            Text("100")
                                .foregroundStyle(.secondary)
                                .font(Font.caption.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(alignment: .trailing)
                    .border(.red, width: 1)
                }
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


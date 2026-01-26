//
//  GeneralSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct GeneralSettings: View {
    
    @Environment(UpdateController.self) var updateController
    @Bindable var defaultsManager : DefaultsManager
    
    var body: some View {
        Form {
            Section("Layout") {
                HStack {
                    Text("Double Modifier On Drag Adjusts Window Layout")
                    Spacer()
                    Picker("", selection: $defaultsManager.modiferKey) {
                        ForEach(ModifierGroup.allCases, id: \.self) { group in
                            Text(group.rawValue)
                        }
                    }
                }
            }
            Section("About") {
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
                
                Button("Quit") {
                    NSApplication.shared.terminate(self)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: updateController.updaterVM.showUserInitiatedUpdate)
    }
}

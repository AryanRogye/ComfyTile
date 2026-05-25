//
//  AboutSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//

import SwiftUI

// MARK: - Updates View
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

//
//  SettingsContent.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct SettingsContent: View {
    
    @Environment(SettingsViewModel.self) var settingsVM
    @Environment(DefaultsManager.self) var defaultsManager
    
    var body: some View {
        switch settingsVM.selectedTab {
        case .general:
            GeneralSettings(defaultsManager: defaultsManager)
            //                case .logs:
            //                    ComfyLogger.ComfyLoggerView(
            //                        names: [
            //                            ComfyLogger.WindowSplitManager,
            //                            ComfyLogger.Updater,
            //                            ComfyLogger.WindowElement
            //                        ]
            //                    )
        }
    }
}

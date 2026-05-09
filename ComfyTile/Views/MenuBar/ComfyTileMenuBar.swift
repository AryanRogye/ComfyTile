//
//  ComfyTileMenuBar.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI

public struct ComfyTileMenuBarRootView: View {
    @Bindable var settingsVM        : SettingsViewModel
    @Bindable var comfyTileMenuBarVM: ComfyTileMenuBarViewModel
    @Bindable var defaultsManager: DefaultsManager
    @Bindable var windowCore: WindowCore
    @Bindable var displayManager: DisplayManager
    @Bindable var updateController: UpdateController
    
    public var body: some View {
        VStack(spacing: 0) {
            if comfyTileMenuBarVM.permissionService.isAccessibilityEnabled {
                NewComfyTileMenuBarContent()
                    .environment(defaultsManager)
                    .environment(windowCore)
                    .environment(displayManager)
                    .environment(comfyTileMenuBarVM)
                    .environment(updateController)
                    .environment(settingsVM)
            } else {
                PermissionView(
                    vm: comfyTileMenuBarVM
                )
            }
        }
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - New Copy
struct NewComfyTileMenuBarContent: View {
    @Environment(ComfyTileMenuBarViewModel.self) var comfyTileMenuBarVM
    @Environment(UpdateController.self) var updateController
    @Environment(DefaultsManager.self) var defaultsManager
    
    var body: some View {
        @Bindable var vm = comfyTileMenuBarVM
        ComfyTileMenuBarTabContainer {
            VStack {
                switch vm.selectedTab {
                case .layout: LayoutModeView()
                case .settings: SettingsView()
                case .tile: TileModeView()
#if DEBUG
                case .debug: ComfyTileDebugView()
#endif
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            ComfyTileUpdateView(updateController: updateController)
        }
    }
}

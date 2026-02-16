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
    @Bindable var updateController: UpdateController
    
    
    public var body: some View {
        VStack(spacing: 0) {
            if comfyTileMenuBarVM.permissionService.isAccessibilityEnabled {
                NewComfyTileMenuBarContent()
                    .environment(defaultsManager)
                    .environment(windowCore)
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

struct PermissionView: View {
    
    @Bindable var vm : ComfyTileMenuBarViewModel
    @State private var clickedPermissions: Bool = false

    var body: some View {
        VStack {
            Text("👀 ComfyTile can’t see your windows yet.\nTurn on Accessibility so it can actually do its job.")

            Spacer()
            Button(action: {
                clickedPermissions = true
                vm.permissionService.requestPermission()
                vm.closePanel()
            }) {
                if clickedPermissions {
                    Text("😐 macOS still pretending we don’t exist?")
                } else {
                    Text("Request Accessibility")
                }
            }
            if clickedPermissions {
                Text("Sometimes macOS is just being stubborn. 😅")
                Button(action: {
                    try? vm.permissionService.resetAccessibility()
                }) {
                    Text("Reset Accessibility For ComfyTile")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - New Copy
struct NewComfyTileMenuBarContent: View {
    @Environment(ComfyTileMenuBarViewModel.self) var comfyTileMenuBarVM
    @Environment(UpdateController.self) var updateController
    @Environment(DefaultsManager.self) var defaultsManager
    
    var body: some View {
        @Bindable var defaultsManager = defaultsManager
        @Bindable var vm = comfyTileMenuBarVM
        VStack(spacing: 0) {
            if defaultsManager.comfyTileTabPlacement == .top {
                ComfyTileTabBar(tabPlacement: $defaultsManager.comfyTileTabPlacement)
                    .transition(.move(edge: .top))
            }
            VStack {
                switch vm.selectedTab {
                case .layout: LayoutModeView()
                case .settings: SettingsView()
                case .tile: TileModeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            ComfyTileUpdateView(updateController: updateController)
            if defaultsManager.comfyTileTabPlacement == .bottom {
                ComfyTileTabBar(tabPlacement: $defaultsManager.comfyTileTabPlacement)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.snappy(duration: 0.25, extraBounce: 0.1), value: defaultsManager.comfyTileTabPlacement)
    }
}

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



// MARK: - Old Copy
struct ComfyTileMenuBarContent: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    @Environment(WindowCore.self) var windowCore
    
    
    var body: some View {
        @Bindable var defaultsManager = defaultsManager
        @Bindable var windowCore = windowCore
        
        Button(action: {
            Task {
                await windowCore.loadWindows()
            }
        }) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        
        ShortcutRecorder(label: "Window Viewer", type: .windowViewer)
        
        /// Have User Select Modifier Key
        Picker("Select Modifier Key", selection: $defaultsManager.modiferKey) {
            ForEach(ModifierGroup.allCases, id: \.self) { group in
                Text(group.rawValue).tag(group)
                    .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: defaultsManager.modiferKey) { _, value in
            defaultsManager.saveModiferKey()
        }
        
        Text("Basic")
            .font(.caption).foregroundStyle(.secondary)
            .padding(.leading, 8)
        
        Section {
            ShortcutRecorder(label: "Auto Tile", type: .AutoTile)
            ShortcutRecorder(label: "Right Half", type: .RightHalf, tileShape: .right)
            ShortcutRecorder(label: "Left Half",  type: .LeftHalf, tileShape: .left)
            ShortcutRecorder(label: "Center",     type: .Center, tileShape: .center)
            ShortcutRecorder(label: "Maximize",   type: .Maximize, tileShape: .full)
        }
        .sectionBackground()
        
        HStack(alignment: .center) {
            Text("Nudging")
                .font(.caption).foregroundStyle(.secondary)
                .padding([.leading, .top], 8)
            Spacer()
            
            TextField("Nudge Amount", value: $defaultsManager.nudgeStep, format: .number)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
                .padding([.trailing, .top], 8)
                .onChange(of: defaultsManager.nudgeStep) { _, value in
                    if value < 2 {
                        defaultsManager.nudgeStep = 2
                    }
                    defaultsManager.saveNudgeStep()
                }
        }
        
        Section {
            ShortcutRecorder(label: "Nudge Bottom Down", type: .NudgeBottomDown, tileShape: .nudgeBottomDown)
            ShortcutRecorder(label: "Nudge Bottom Up",   type: .NudgeBottomUp, tileShape: .nudgeBottomUp)
            ShortcutRecorder(label: "Nudge Top Up",      type: .NudgeTopUp, tileShape: .nudgeTopUp)
            ShortcutRecorder(label: "Nudge Top Down",    type: .NudgeTopDown, tileShape: .nudgeTopDown)
        }
        .sectionBackground()
        
        Button(action: {
//            settingsCoordinator.openSettings()
        }) {
            Label("Settings", systemImage: "gear")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(4)
        }
        
        Button(action: {
            NSApplication.shared.terminate(self)
        }) {
            Text("Quit Comfy Tile")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(4)
        }
    }
}


//#Preview {
//    
//    @Previewable @State var defaultsManager = DefaultsManager()
//    @Previewable @State var fetchedWindowManager = FetchedWindowManager()
//    @Previewable @State var updateController = UpdateController()
//    
//    ComfyTileMenuBarRootView(
//        settingsVM: SettingsViewModel(),
//        comfyTileMenuBarVM: ComfyTileMenuBarViewModel(),
//        defaultsManager: defaultsManager,
//        fetchedWindowManager: fetchedWindowManager,
//        updateController: updateController,
//    )
//}


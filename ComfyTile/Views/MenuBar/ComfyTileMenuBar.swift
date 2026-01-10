//
//  ComfyTileMenuBar.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI

#Preview {
    
    @Previewable @State var defaultsManager = DefaultsManager()
    @Previewable @State var fetchedWindowManager = FetchedWindowManager()
    @Previewable @State var updateController = UpdateController()
    
    lazy var settingsCoordinator = SettingsCoordinator(
        settingsVM: SettingsViewModel(),
        windowCoordinator: WindowCoordinator(),
        updateController: updateController,
        defaultsManager: defaultsManager
    )
    
    ComfyTileMenuBarRootView(
        defaultsManager: defaultsManager,
        fetchedWindowManager: fetchedWindowManager,
        settingsCoordinator: settingsCoordinator,
        updateController: updateController,
    )
}

struct ComfyTileMenuBar: Scene {
    @Bindable var defaultsManager: DefaultsManager
    @Bindable var fetchedWindowManager: FetchedWindowManager
    @Bindable var settingsCoordinator: SettingsCoordinator
    @Bindable var updateController: UpdateController
    
    var body: some Scene {
        MenuBarExtra {
            ComfyTileMenuBarRootView(
                defaultsManager: defaultsManager,
                fetchedWindowManager: fetchedWindowManager,
                settingsCoordinator: settingsCoordinator,
                updateController: updateController
            )
        } label: {
            Image("ComfyTileMenuBar").renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}

struct ComfyTileMenuBarRootView: View {
    @Bindable var defaultsManager: DefaultsManager
    @Bindable var fetchedWindowManager: FetchedWindowManager
    @Bindable var settingsCoordinator: SettingsCoordinator
    @Bindable var updateController: UpdateController
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    ComfyTileMenuBarContent()
                        .environment(defaultsManager)
                        .environment(fetchedWindowManager)
                        .environment(settingsCoordinator)
                }
                .padding()
                .environment(\.controlSize, .small)
            }
            ComfyTileUpdateView(updateController: updateController)
        }
        .frame(minWidth: 400, minHeight: 300)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }
}


struct ComfyTileMenuBarContent: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    @Environment(FetchedWindowManager.self) var fetchedWindowManager
    @Environment(SettingsCoordinator.self) var settingsCoordinator
    
    
    var body: some View {
        @Bindable var defaultsManager = defaultsManager
        @Bindable var fetchedWindowManager = fetchedWindowManager
        
        Button(action: {
            Task {
                await fetchedWindowManager.loadWindows()
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
            settingsCoordinator.openSettings()
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

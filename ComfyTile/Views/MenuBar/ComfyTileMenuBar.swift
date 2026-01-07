//
//  ComfyTileMenuBar.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI

struct ComfyTileMenuBar: Scene {
    
    @Bindable var defaultsManager: DefaultsManager
    @Bindable var fetchedWindowManager : FetchedWindowManager
    
    var body: some Scene {
        MenuBarExtra {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    ComfyTileMenuBarContent()
                        .environment(defaultsManager)
                        .environment(fetchedWindowManager)
                }
                .padding()
                .environment(\.controlSize, .small)
            }
            .frame(minWidth: 400, minHeight: 300)
        } label: {
            Image("ComfyTileMenuBar")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
        
    }
}

struct ComfyTileMenuBarContent: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    @Environment(FetchedWindowManager.self) var fetchedWindowManager
    @Environment(\.openWindow) var openWindow
    
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
            openWindow(id: "Settings")
//            openSettings()
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

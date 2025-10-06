//
//  ComfyTileMenuBar.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI

struct ComfyTileMenuBar: Scene {
    var body: some Scene {
        
        MenuBarExtra("Menu", systemImage: "menubar.dock.rectangle") {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    ComfyTileMenuBarContent()
                }
                .padding()
                .environment(\.controlSize, .small)
            }
            .frame(minWidth: 400, minHeight: 300)
        }
        .menuBarExtraStyle(.window)
        
    }
}

struct ComfyTileMenuBarContent: View {
    var body: some View {
        Text("Basic")
            .font(.caption).foregroundStyle(.secondary)
            .padding(.leading, 8)
        
        Section {
            ShortcutRecorder(label: "Right Half", type: .RightHalf)
            ShortcutRecorder(label: "Left Half",  type: .LeftHalf)
            ShortcutRecorder(label: "Center",     type: .Center)
            ShortcutRecorder(label: "Maximize",   type: .Maximize)
        }
        .sectionBackground()
        
        Text("Nudging")
            .font(.caption).foregroundStyle(.secondary)
            .padding([.leading, .top], 8)
        
        Section {
            ShortcutRecorder(label: "Nudge Bottom Down", type: .NudgeBottomDown)
            ShortcutRecorder(label: "Nudge Bottom Up",   type: .NudgeBottomUp)
            ShortcutRecorder(label: "Nudge Top Up",      type: .NudgeTopUp)
            ShortcutRecorder(label: "Nudge Top Down",    type: .NudgeTopDown)
        }
        .sectionBackground()
    }
}

//
//  ComfyTileDebugView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/12/26.
//

#if DEBUG
import SwiftUI
import KeyboardShortcuts

struct ComfyTileDebugView: View {
    var body: some View {
        MenuBarContainer {
            ShortcutEditableRow(
                onClick: {
                    /// Do Nothing
                },
                roundTop: true,
                title: "DEBUG",
                editLabel: "Edit",
                hotkey: .debug_press,
                idPrefix: "debug-1-\(UUID())",
                icon: { Image(systemName: "bolt.fill") },
                helpText: "used to run things fast")
        }
    }
}
#endif

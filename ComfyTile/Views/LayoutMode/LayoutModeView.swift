//
//  LayoutModeView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI
import KeyboardShortcuts

struct LayoutModeView: View {
    
    @Environment(ComfyTileMenuBarViewModel.self) var vm
    
    var body: some View {
        MenuBarContainer {
            ForEach(LayoutMode.allCases, id: \.self) { layout in
                ShortcutEditableRow(
                    onClick: {
                        vm.onTap(for: layout)
                    },
                    roundTop: layout == LayoutMode.allCases.first!,
                    title: layout.rawValue,
                    editLabel: "Shortcut for \(layout.rawValue)",
                    hotkey: layout.hotkey,
                    idPrefix: "layout-\(layout.rawValue)",
                    icon: { EmptyView() },
                    helpText: "Edit Shortcut"
                )
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }
        }
    }
}

//
//  TileModeView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI
import KeyboardShortcuts

struct TileModeView: View {
    var body: some View {
        MenuBarContainer {
            ForEach(TilingMode.allCases, id: \.self) { tile in
                ShortcutEditableRow(
                    roundTop: tile == TilingMode.allCases.first!,
                    title: tile.rawValue,
                    editLabel: "Shortcut for \(tile.rawValue)",
                    hotkey: tile.hotkey,
                    idPrefix: "tile-\(tile.rawValue)",
                    icon: {
                        tile.tileShape.view(color: .accentColor)
                            .frame(width: 15, height: 15)
                    },
                    helpText: "Edit Shortcut"
                )
                .listRowInsets(.init())
            }
        }
    }
}

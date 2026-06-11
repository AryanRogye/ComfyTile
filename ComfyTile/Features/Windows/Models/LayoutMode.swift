//
//  LayoutMode.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import KeyboardShortcuts

enum LayoutMode: String, CaseIterable {
    case primaryOnly
    case primaryLeftStackedHorizontally
    case primaryRightStackedHorizontally
    
    var hotkey: KeyboardShortcuts.Name {
        switch self {
        case .primaryOnly:
            KeyboardShortcuts.Name.primaryTile
        case .primaryLeftStackedHorizontally:
            KeyboardShortcuts.Name.primaryLeftStackedHorizontallyTile
        case .primaryRightStackedHorizontally:
            KeyboardShortcuts.Name.primaryRightStackedHorizontallyTile
        }
    }
}

//
//  HotKeyOrClose.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI
import KeyboardShortcuts

/**
 A compact, animated capsule view that toggles between displaying a keyboard shortcut
 and a “Close” action.
 
 `HotKeyOrClose` is designed for menu-style rows where space is constrained and
 state changes should feel fluid and intentional. It uses a shared
 `matchedGeometryEffect` namespace to smoothly morph the capsule’s size and layout
 when entering or exiting edit mode.
 
 ## States
 - **Normal mode (`allowEditHotkey == false`)**
 - If a shortcut exists, shows the shortcut’s textual description inside a filled capsule.
 - If no shortcut exists, shows a dashed capsule with a plus icon to indicate
 an unset or addable shortcut.
 - **Edit mode (`allowEditHotkey == true`)**
 - Expands into a wider capsule labeled “Close”, signaling that the user can
 exit shortcut-editing mode.
 
 ## Animation
 All visual states share the same `matchedGeometryEffect` `id`, allowing the capsule
 to morph smoothly between:
 - fixed-width shortcut display
 - dashed “add” affordance
 - full-width “Close” control
 
 The `.frame` property is explicitly animated to avoid positional warping and to
 keep transitions feeling grounded within the row.
 
 ## Accessibility & Interaction
 - Uses a `Capsule` content shape to ensure the full visual area is interactive.
 - Intended to be wrapped in a `Button` by the parent view for click handling.
 
 ## Parameters
 - `shortcut`: Optional keyboard shortcut to display when not editing.
 - `allowEditHotkey`: Binding that controls whether the view is in edit mode.
 - `nm`: Shared `Namespace.ID` used for matched geometry animations.
 - `id`: Stable identifier for the matched geometry effect; must be consistent
 across all visual states.
 
 ## Usage
 This view is typically embedded at the trailing edge of a menu row and driven by
 a parent’s edit-state toggle, providing a clear and polished affordance for
 viewing or editing keyboard shortcuts.
 */

struct HotKeyOrClose: View {
    
    let shortcut: KeyboardShortcuts.Shortcut?
    @Binding var allowEditHotkey: Bool
    let nm: Namespace.ID
    let id: String
    
    var body: some View {
        Group {
            if allowEditHotkey {
                Capsule()
                    .fill(Color.accentColor.opacity(0.3))
                    .matchedGeometryEffect(
                        id: id,
                        in: nm,
                        properties: .frame
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .overlay {
                        Label("Close", systemImage: "xmark")
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
            } else {
                if let shortcut = shortcut {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.3))
                        .matchedGeometryEffect(
                            id: id,
                            in: nm,
                            properties: .frame
                        )
                        .frame(width: 70, height: 15)
                        .overlay {
                            Text(shortcut.description)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                } else {
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .matchedGeometryEffect(
                            id: id,
                            in: nm,
                            properties: .frame
                        )
                        .frame(width: 70, height: 15)
                        .foregroundStyle(.secondary)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .semibold))
                        }
                }
            }
        }
        .contentShape(Capsule())
    }
    
}

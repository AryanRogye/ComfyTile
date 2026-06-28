//
//  FocusedWindowAppearance.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI

// MARK: - Highlight Focused Window
struct HighlightFocusedWindowView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        Toggle("Highlight focused window", isOn: $defaultsManager.highlightFocusedWindow)
    }
}

// MARK: - Highlight Focused Window Color
struct HighlightFocusedWindowColorView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        ColorPicker(
            "Highlight Color",
            selection: $defaultsManager.highlightFocusedWindowColor
        )
    }
}

// MARK: - Highlight Focused Window Width
struct HighlightFocusedWindowWidthView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        HStack {
            Text("Highlight Line Width")
            
            Slider(
                value: $defaultsManager.highlightedFocusedWindowWidth,
                in: 1...2,
                step: 0.1
            )
        }
    }
}

// MARK: - Focused Window Highlight Warning
struct FocusedWindowHighlightWarningView: View {
    
    var body: some View {
        Text("⚠️ Note: Highlighting focused window only works if we're not super focusing")
    }
}

// MARK: - Super Focus Window
struct SuperFocusWindowView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        Toggle("Super Focus Window", isOn: $defaultsManager.superFocusWindow)
    }
}

// MARK: - Super Focus HotKey
struct SuperFocusHotKeyView: View {
    
    var body: some View {
        ShortcutRecorder(label: "Toggle Super Focus", type: .toggleSuperFocus)
            .padding(.horizontal, -16)
    }
}

// MARK: - Super Focus Color
struct SuperFocusColorView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        ColorPicker(
            "Super Focus Color",
            selection: $defaultsManager.superFocusColor
        )
    }
}

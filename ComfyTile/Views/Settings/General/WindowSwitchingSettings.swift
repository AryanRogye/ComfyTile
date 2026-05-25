//
//  WindowSwitchingSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//

import SwiftUI

// MARK: - Window Switcher Settings
struct WindowSwitcherGeneralView: View {

    @Bindable var defaultsManager : DefaultsManager

    var body: some View {
        Toggle("Use F to show all windows for an app", isOn: $defaultsManager.allowFocusAppWindowOnWindowSwitcher)
    }
}

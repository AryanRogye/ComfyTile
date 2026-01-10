//
//  SettingsViewModel.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    var openMenuBar: () -> Void = {}
    
    var selectedTab: SettingsTab = .general
    var isSidebarOpen = true
}

//
//  CheckForUpdatesView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/8/26.
//

import Sparkle
import SwiftUI
import Combine

/// ViewModel for CheckForUpdateView
final class Updater: ObservableObject {
    @Published var canCheckForUpdates = false
    
    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    
    @Environment(SettingsViewModel.self) var settingsVM
    @ObservedObject private var checkForUpdatesViewModel: Updater
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = Updater(updater: updater)
    }
    
    var body: some View {
        Button("Check for Updates…", action: {
//            settingsVM.openMenuBar()
            updater.checkForUpdates()
        })
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

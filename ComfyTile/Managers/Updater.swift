//
//  Updater.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/8/26.
//

import SwiftUI
import Sparkle
import Combine

@Observable
final class UpdateController {
    
    @ObservationIgnored
    private let updaterController: SPUStandardUpdaterController
    
    public func updateController() -> SPUStandardUpdaterController {
        return updaterController
    }
    
    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
}

final class Updater: ObservableObject {
    @Published var canCheckForUpdates = false
    
    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: Updater
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = Updater(updater: updater)
    }
    
    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

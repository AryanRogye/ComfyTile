//
//  ComfyTileApp.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import KeyboardShortcuts
import Sparkle
import SwiftUI

@main
struct ComfyTileApp: App {

    init() {
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {

        WindowGroup { EmptyView().destroyViewWindow() }

        // MARK: - AppKit MenuBar is now used via MenuBarCoordinator (initialized in AppCoordinator)
        // ComfyTileMenuBar(
        //     defaultsManager: appDelegate.appCoordinator.defaultsManager,
        //     fetchedWindowManager: appDelegate.appCoordinator.fetchedWindowManager,
        //     settingsCoordinator : appDelegate.appCoordinator.settingsCoordinator,
        //     updateController: appDelegate.appCoordinator.updateController
        // )
    }
}

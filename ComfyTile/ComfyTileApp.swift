//
//  ComfyTileApp.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI
import KeyboardShortcuts
import Sparkle

@main
struct ComfyTileApp: App {
    
    init() {
    }
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        WindowGroup{EmptyView().destroyViewWindow()}
        
        ComfyTileMenuBar(
            defaultsManager: appDelegate.appCoordinator.defaultsManager,
            fetchedWindowManager: appDelegate.appCoordinator.fetchedWindowManager,
            settingsCoordinator : appDelegate.appCoordinator.settingsCoordinator,
            updateController: appDelegate.appCoordinator.updateController
        )
    }
}

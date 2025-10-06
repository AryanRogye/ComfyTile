//
//  ComfyTileApp.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI
import KeyboardShortcuts

@main
struct ComfyTileApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        ComfyTileMenuBar()
    }
}

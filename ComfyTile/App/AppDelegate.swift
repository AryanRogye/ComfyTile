//
//  AppDelegate.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import AppKit

class AppEnv {
    var windowLayoutService: any WindowLayoutProviding = WindowLayoutService()
    var permissionService: PermissionService = PermissionService()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var appCoordinator : AppCoordinator
    
    @MainActor
    override init() {
        NSApp.setActivationPolicy(.accessory)
        appCoordinator = AppCoordinator(appEnv: AppEnv())
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

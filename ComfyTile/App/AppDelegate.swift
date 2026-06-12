//
//  AppDelegate.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import AppKit

class AppEnv {

    lazy var appServices = AppServices()

    var windowCore = WindowCore()

    lazy var windowTilingService: any WindowTilingProviding = WindowTilingService(
        windowCore: windowCore) {
            (
                self.windowCore.getFocusedWindow(),
                WindowCore.screenUnderMouse()
            )
        }
    lazy var windowLayoutService: any WindowLayoutProviding = WindowLayoutService(
        windowCore: windowCore
    )
    
    var permissionService: PermissionService = PermissionService()
}

class AppDelegate: NSObject, NSApplicationDelegate {

    private var appCoordinator: AppCoordinator?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        guard !ProcessInfo.isSwiftUIPreview else { return }

        NSApp.setActivationPolicy(.accessory)
        appCoordinator = AppCoordinator(appEnv: AppEnv())
    }

    public func applicationWillTerminate(_ notification: Notification) {
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

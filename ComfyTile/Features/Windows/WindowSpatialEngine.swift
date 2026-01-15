//
//  WindowSpatialEngine.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/7/26.
//

import KeyboardShortcuts


enum TilingMode: String, CaseIterable {
    case rightHalf
    case leftHalf
    case center
    case fullscreen
    case nudgeBottomUp
    case nudgeBottomDown
    case nudgeTopDown
    case nudgeTopUp
    
    var hotkey: KeyboardShortcuts.Name {
        switch self {
        case .rightHalf:
            KeyboardShortcuts.Name.RightHalf
        case .leftHalf:
            KeyboardShortcuts.Name.LeftHalf
        case .center:
            KeyboardShortcuts.Name.Center
        case .fullscreen:
            KeyboardShortcuts.Name.Maximize
        case .nudgeBottomUp:
            KeyboardShortcuts.Name.NudgeBottomUp
        case .nudgeBottomDown:
            KeyboardShortcuts.Name.NudgeBottomDown
        case .nudgeTopDown:
            KeyboardShortcuts.Name.NudgeTopDown
        case .nudgeTopUp:
            KeyboardShortcuts.Name.NudgeTopUp
        }
    }
    
    var tileShape: TileShape {
        switch self {
        case .rightHalf:
                .right
        case .leftHalf:
                .left
        case .center:
                .center
        case .fullscreen:
                .full
        case .nudgeBottomUp:
                .nudgeBottomUp
        case .nudgeBottomDown:
                .nudgeBottomDown
        case .nudgeTopDown:
                .nudgeTopDown
        case .nudgeTopUp:
                .nudgeTopUp
        }
    }
}

enum LayoutMode: String, CaseIterable {
    case primaryOnly
    case primaryLeftStackedHorizontally
    case primaryRightStackedHorizontally
    
    var hotkey: KeyboardShortcuts.Name {
        switch self {
        case .primaryOnly:
            KeyboardShortcuts.Name.primaryTile
        case .primaryLeftStackedHorizontally:
            KeyboardShortcuts.Name.primaryLeftStackedHorizontallyTile
        case .primaryRightStackedHorizontally:
            KeyboardShortcuts.Name.primaryRightStackedHorizontallyTile
        }
    }
}

final class WindowSpatialEngine {
    
    let windowCore : WindowCore
    let windowTilingService  : WindowTilingProviding
    let windowLayoutService  : WindowLayoutProviding
    let defaultsManager      : DefaultsManager
    
    init(
        windowCore          : WindowCore,
        windowLayoutService : WindowLayoutProviding,
        windowTilingService : WindowTilingProviding,
        defaultsManager     : DefaultsManager
    ) {
        self.windowCore = windowCore
        self.windowLayoutService = windowLayoutService
        self.windowTilingService  = windowTilingService
        self.defaultsManager      = defaultsManager
    }
    
    public func action(for layout: LayoutMode) {
        switch layout {
        case .primaryOnly:                    primaryTile()
        case .primaryLeftStackedHorizontally: primaryLeftStackedHorizontallyTile()
        case .primaryRightStackedHorizontally: primaryRightStackedHorizontallyTile()
        }
    }
    
    public func action(for tile: TilingMode) {
        switch tile {
        case .rightHalf:       tileRight()
        case .leftHalf:        tileLeft()
        case .center:          tileCenter()
        case .fullscreen:      tileFullScreen()
        case .nudgeBottomUp:   nudgeBottomUp()
        case .nudgeBottomDown: nudgeBottomDown()
        case .nudgeTopDown:    nudgeTopDown()
        case .nudgeTopUp:      nudgeTopUp()
        }
    }
    public func primaryTile() {
        Task {
            await self.windowCore.loadWindows()
            let inSpace = self.windowCore.windows.filter(\.isInSpace)
            await self.windowLayoutService.primaryLayout(
                window: inSpace
            )
        }
    }
    
    public func primaryLeftStackedHorizontallyTile() {
        Task {
            await self.windowCore.loadWindows()
            let inSpace = self.windowCore.windows.filter(\.isInSpace)
            await self.windowLayoutService.primaryLeftStackedHorizontally(
                window: inSpace
            )
        }
    }
    
    public func primaryRightStackedHorizontallyTile() {
        Task {
            await self.windowCore.loadWindows()
            let inSpace = self.windowCore.windows.filter(\.isInSpace)
            await self.windowLayoutService.primaryRightStackedHorizontally(
                window: inSpace
            )
        }
    }
    
    public func tileRight() {
        self.windowTilingService.moveRight()
    }
    
    public func tileLeft() {
        self.windowTilingService.moveLeft()
    }
    
    public func tileCenter() {
        self.windowTilingService.center()
    }
    
    public func tileFullScreen() {
        self.windowTilingService.fullScreen()
    }
    
    public func nudgeBottomDown() {
        self.windowTilingService.nudgeBottomDown(
            with: self.defaultsManager.nudgeStep
        )
    }
    public func nudgeBottomUp() {
        self.windowTilingService.nudgeBottomUp(
            with: self.defaultsManager.nudgeStep
        )
    }
    public func nudgeTopUp() {
        self.windowTilingService.nudgeTopUp(
            with: self.defaultsManager.nudgeStep
        )
    }
    public func nudgeTopDown() {
        self.windowTilingService.nudgeTopDown(
            with: self.defaultsManager.nudgeStep
        )
    }
}

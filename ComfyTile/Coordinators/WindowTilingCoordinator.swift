//
//  WindowTilingCoordinator.swift
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

final class WindowTilingCoordinator {
    
    let fetchedWindowManager : FetchedWindowManager
    let windowSplitManager   : WindowSplitManager
    let windowLayoutService  : WindowLayoutProviding
    let defaultsManager      : DefaultsManager
    
    init(
        fetchedWindowManager: FetchedWindowManager,
        windowSplitManager  : WindowSplitManager,
        windowLayoutService : WindowLayoutProviding,
        defaultsManager     : DefaultsManager
    ) {
        self.fetchedWindowManager = fetchedWindowManager
        self.windowSplitManager   = windowSplitManager
        self.windowLayoutService  = windowLayoutService
        self.defaultsManager      = defaultsManager
    }
    
    public func primaryTile() {
        Task {
            await self.fetchedWindowManager.loadWindows()
            let inSpace = self.fetchedWindowManager.fetchedWindows.filter(\.isInSpace)
            await self.windowSplitManager.splitWindows(
                window: inSpace,
                style: .primaryOnly
            )
        }
    }
    
    public func primaryLeftStackedHorizontallyTile() {
        Task {
            await self.fetchedWindowManager.loadWindows()
            let inSpace = self.fetchedWindowManager.fetchedWindows.filter(\.isInSpace)
            await self.windowSplitManager.splitWindows(
                window: inSpace,
                style: .primaryLeftStackedHorizontally
            )
        }
    }
    
    public func primaryRightStackedHorizontallyTile() {
        Task {
            await self.fetchedWindowManager.loadWindows()
            let inSpace = self.fetchedWindowManager.fetchedWindows.filter(\.isInSpace)
            await self.windowSplitManager.splitWindows(
                window: inSpace,
                style: .primaryRightStackedHorizontally
            )
        }
    }
    
    public func tileRight() {
        self.windowLayoutService.moveRight()
    }
    
    public func tileLeft() {
        self.windowLayoutService.moveLeft()
    }
    
    public func tileCenter() {
        self.windowLayoutService.center()
    }
    
    public func tileFullScreen() {
        self.windowLayoutService.fullScreen()
    }
    
    public func nudgeBottomDown() {
        self.windowLayoutService.nudgeBottomDown(
            with: self.defaultsManager.nudgeStep
        )
    }
    public func nudgeBottomUp() {
        self.windowLayoutService.nudgeBottomUp(
            with: self.defaultsManager.nudgeStep
        )
    }
    public func nudgeTopUp() {
        self.windowLayoutService.nudgeTopUp(
            with: self.defaultsManager.nudgeStep
        )
    }
    public func nudgeTopDown() {
        self.windowLayoutService.nudgeTopDown(
            with: self.defaultsManager.nudgeStep
        )
    }
}

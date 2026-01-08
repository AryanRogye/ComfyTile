//
//  WindowTilingCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/7/26.
//

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

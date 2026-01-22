//
//  WindowSpatialEngine.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/7/26.
//

import KeyboardShortcuts
import Cocoa


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
    let tilingCoverCoordinator: TilingCoverCoordinator
    
    init(
        windowCore          : WindowCore,
        windowLayoutService : WindowLayoutProviding,
        windowTilingService : WindowTilingProviding,
        defaultsManager     : DefaultsManager,
        tilingCoverCoordinator : TilingCoverCoordinator
    ) {
        self.windowCore = windowCore
        self.windowLayoutService = windowLayoutService
        self.windowTilingService  = windowTilingService
        self.defaultsManager      = defaultsManager
        self.tilingCoverCoordinator = tilingCoverCoordinator
    }
    
    var numKeysHeld = 0
    
    /// Actions UI Can Call
    public func action(for layout: LayoutMode) {
        switch layout {
        case .primaryOnly:                    primaryTile()
        case .primaryLeftStackedHorizontally: primaryLeftStackedHorizontallyTile()
        case .primaryRightStackedHorizontally: primaryRightStackedHorizontallyTile()
        }
    }
    
    public func action(for tile: TilingMode) {
        switch tile {
        case .rightHalf:       self.windowTilingService.moveRight(
                                    withAnimation: self.defaultsManager.showTilingAnimations
                                )
        case .leftHalf:        self.windowTilingService.moveLeft(
                                    withAnimation: self.defaultsManager.showTilingAnimations
                                )
        case .center:          self.windowTilingService.center(
                                    withAnimation: self.defaultsManager.showTilingAnimations
                                )
        case .fullscreen:      self.windowTilingService.fullScreen(
                                    withAnimation: self.defaultsManager.showTilingAnimations
                                )
        case .nudgeBottomUp:   nudgeBottomUp()
        case .nudgeBottomDown: nudgeBottomDown()
        case .nudgeTopDown:    nudgeTopDown()
        case .nudgeTopUp:      nudgeTopUp()
        }
    }
    
    /// Function Checks if we should tile with animation
    internal func tileWithAnimation(
        _ completion: @escaping () -> Void
    ) {
        self.shouldCloseWith {
            completion()
        }
    }
    
    /// Function Checks if we should tile with animation
    internal func tileDownWithAnimation(
        _ completion: @escaping () -> CGRect?
    ) {
        if self.defaultsManager.showTilingAnimations {
            if let rect = completion() {
                self.showWith(rect: rect)
            }
            self.numKeysHeld += 1
        }
    }

    /// Helper Functions
    internal func shouldCloseWith(completion: @escaping () -> Void) {
        if self.defaultsManager.showTilingAnimations {
            self.numKeysHeld -= 1
            if self.numKeysHeld == 0 {
                self.tilingCoverCoordinator.hide()
                completion()
            }
        } else {
            self.numKeysHeld = 0
        }
    }
    internal func showWith(rect: CGRect) {
        self.tilingCoverCoordinator.show(with: rect)
    }
}

// MARK: - Layout
extension WindowSpatialEngine {
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
}



// MARK: - Tile Right
extension WindowSpatialEngine {
    public func tileRight() {
        tileWithAnimation {
            self.windowTilingService.moveRight(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
        }
    }
    public func tileRightPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.moveRight(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getRightDimensions()
        }
    }
}
    
// MARK: - Tile Left
extension WindowSpatialEngine {
    public func tileLeft() {
        tileWithAnimation {
            self.windowTilingService.moveLeft(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
        }
    }
    public func tileLeftPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.moveLeft(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getLeftDimensions()
        }
    }
}
    
// MARK: - Tile Center
extension WindowSpatialEngine {
    public func tileCenter() {
        tileWithAnimation {
            self.windowTilingService.center(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
        }
    }
    public func tileCenterPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.center(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getCenterDimensions()
        }
    }
}

// MARK: - Tile Full Screen
extension WindowSpatialEngine {
    public func tileFullScreen() {
        tileWithAnimation {
            self.windowTilingService.fullScreen(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
        }
    }
    public func tileFullScreenPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.fullScreen(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getFullScreenDimensions()
        }
    }
}


// MARK: - Nudging
extension WindowSpatialEngine {
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

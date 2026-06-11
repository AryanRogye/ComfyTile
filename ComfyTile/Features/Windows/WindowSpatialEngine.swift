//
//  WindowSpatialEngine.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/7/26.
//

import KeyboardShortcuts
import Cocoa

final class WindowSpatialEngine {
    
    let windowCore : WindowCore
    let windowTilingService  : WindowTilingProviding
    let windowLayoutService  : WindowLayoutProviding
    let defaultsManager      : DefaultsManager
    let displayManager       : DisplayManager
    let tilingCoverCoordinator: TilingCoverCoordinator
    
    init(
        windowCore          : WindowCore,
        windowLayoutService : WindowLayoutProviding,
        windowTilingService : WindowTilingProviding,
        defaultsManager     : DefaultsManager,
        displayManager       : DisplayManager,
        tilingCoverCoordinator : TilingCoverCoordinator
    ) {
        self.windowCore = windowCore
        self.windowLayoutService = windowLayoutService
        self.windowTilingService  = windowTilingService
        self.defaultsManager      = defaultsManager
        self.displayManager = displayManager
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
                                    withAnimation: self.defaultsManager.showTilingAnimations,
                                    isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                                    enableSmartTiling: self.defaultsManager.enableSmartTiling
                                )
        case .leftHalf:        self.windowTilingService.moveLeft(
                                    withAnimation: self.defaultsManager.showTilingAnimations,
                                    isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                                    enableSmartTiling: self.defaultsManager.enableSmartTiling
                                )
        case .bottomHalf:       self.windowTilingService.moveBottomHalf(
                                    withAnimation: self.defaultsManager.showTilingAnimations
                                )
        case .topHalf:          self.windowTilingService.moveTopHalf(
                                    withAnimation: self.defaultsManager.showTilingAnimations
                                )
        case .center:          self.windowTilingService.center(
                                    withAnimation: self.defaultsManager.showTilingAnimations,
                                    padding: self.defaultsManager.centerTilingPadding,
                                    isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                                    isUsingAdvancedPadding: self.defaultsManager.advancedCenterTilingPadding
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

// MARK: - Tile Top Half
extension WindowSpatialEngine {
    public func tileTopHalf() {
        tileWithAnimation {
            self.windowTilingService.moveTopHalf(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
        }
    }
    
    public func tileTopHalfPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.moveTopHalf(
                withAnimation: self.defaultsManager.showTilingAnimations,
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getTopHalfDimensions()
        }
    }
}

// MARK: - Tile Bottom Half
extension WindowSpatialEngine {
    public func tileBottomHalf() {
        tileWithAnimation {
            self.windowTilingService.moveBottomHalf(
                withAnimation: self.defaultsManager.showTilingAnimations
            )
        }
    }
    
    public func tileBottomHalfPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.moveBottomHalf(
                withAnimation: self.defaultsManager.showTilingAnimations,
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getBottomHalfDimensions()
        }
    }
}


// MARK: - Tile Right
extension WindowSpatialEngine {
    public func tileRight() {
        tileWithAnimation {
            self.windowTilingService.moveRight(
                withAnimation: self.defaultsManager.showTilingAnimations,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                enableSmartTiling: self.defaultsManager.enableSmartTiling
            )
        }
    }
    public func tileRightPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.moveRight(
                withAnimation: self.defaultsManager.showTilingAnimations,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                enableSmartTiling: self.defaultsManager.enableSmartTiling
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getRightDimensions(
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                enableSmartTiling: self.defaultsManager.enableSmartTiling
            )
        }
    }
}
    
// MARK: - Tile Left
extension WindowSpatialEngine {
    public func tileLeft() {
        tileWithAnimation {
            self.windowTilingService.moveLeft(
                withAnimation: self.defaultsManager.showTilingAnimations,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                enableSmartTiling: self.defaultsManager.enableSmartTiling
            )
        }
    }
    public func tileLeftPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.moveLeft(
                withAnimation: self.defaultsManager.showTilingAnimations,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                enableSmartTiling: self.defaultsManager.enableSmartTiling
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getLeftDimensions(
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                enableSmartTiling: self.defaultsManager.enableSmartTiling
            )
        }
    }
}
    
// MARK: - Tile Center
extension WindowSpatialEngine {
    public func tileCenter() {
        tileWithAnimation {
            self.windowTilingService.center(
                withAnimation: self.defaultsManager.showTilingAnimations,
                padding: self.defaultsManager.centerTilingPadding,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                isUsingAdvancedPadding: self.defaultsManager.advancedCenterTilingPadding
            )
        }
    }
    public func tileCenterPressed() {
        if !defaultsManager.showTilingAnimations {
            self.windowTilingService.center(
                withAnimation: self.defaultsManager.showTilingAnimations,
                padding: self.defaultsManager.centerTilingPadding,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                isUsingAdvancedPadding: self.defaultsManager.advancedCenterTilingPadding
            )
            return
        }
        tileDownWithAnimation {
            self.windowTilingService.getCenterDimensions(
                padding: self.defaultsManager.centerTilingPadding,
                isLayoutCycling: self.defaultsManager.enableLayoutCycling,
                isUsingAdvancedPadding: self.defaultsManager.advancedCenterTilingPadding
            )
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

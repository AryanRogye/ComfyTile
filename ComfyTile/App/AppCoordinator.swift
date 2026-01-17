//
//  AppCoordinator.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import CoreGraphics

@MainActor
class AppCoordinator {
    
    /// ==============================================================================
    /// SERVICES
    /// ==============================================================================
    /// Handles Tiling
    let windowTilingService: WindowTilingProviding
    /// Handles Layout
    let windowLayoutService: WindowLayoutProviding
    
    /// ==============================================================================
    /// Coordinators
    /// ==============================================================================
    let menuBarCoordinator      = MenuBarCoordinator()
    let hotKeyCoordinator       : HotKeyCoordinator
    let tilingCoverCoordinator  : TilingCoverCoordinator
    let windowViewerCoordinator : WindowViewerCoordinator
    
    /// ==============================================================================
    /// View Models
    /// ==============================================================================
    let comfyTileMenuBarVM : ComfyTileMenuBarViewModel
    let settingsVM         = SettingsViewModel()
    let tilingCoverVM      = TilingCoverViewModel()
    let windowViewerVM     = WindowViewerViewModel()
    
    /// ==============================================================================
    /// Controllers
    /// ==============================================================================
    let updateController = UpdateController()
    
    /// Core Windowing
    private let windowCore          : WindowCore
    private let defaultsManager     = DefaultsManager()
    private let windowSpatialEngine : WindowSpatialEngine
    private var permissionService : PermissionService

    var numKeysHeld = 0
    var isHoldingModifier = false
    
    init(appEnv: AppEnv) {
        
        self.permissionService = PermissionService()
        self.windowCore = appEnv.windowCore
        self.windowTilingService = appEnv.windowTilingService
        self.windowLayoutService = appEnv.windowLayoutService
        
        
        self.windowSpatialEngine = WindowSpatialEngine(
            windowCore: appEnv.windowCore,
            windowLayoutService: windowLayoutService,
            windowTilingService: windowTilingService,
            defaultsManager: defaultsManager
        )
        
        self.comfyTileMenuBarVM = ComfyTileMenuBarViewModel(
            permissionService: permissionService,
            windowSpatialEngine: windowSpatialEngine,
            windowCore: appEnv.windowCore
        )
        
        menuBarCoordinator.start(
            comfyTileMenuBarVM: comfyTileMenuBarVM,
            settingsVM: settingsVM,
            defaultsManager: defaultsManager,
            windowCore: appEnv.windowCore,
            updateController: updateController
        )
        
        tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
        )
        windowViewerCoordinator = WindowViewerCoordinator(
            windowViewerVM: windowViewerVM,
            windowCore: appEnv.windowCore
        )
        
        hotKeyCoordinator = HotKeyCoordinator()
        startHotKey()
    }
    
    private func showWith(rect: CGRect) {
        self.tilingCoverCoordinator.show(with: rect)
    }
    
    private func shouldCloseWith(completion: @escaping () -> Void) {
        if !self.defaultsManager.showTilingAnimations {
            completion()
        } else {
            self.numKeysHeld -= 1
            if self.numKeysHeld == 0 {
                self.tilingCoverCoordinator.hide()
                completion()
            }
        }
    }
    
    private func startHotKey() {
        hotKeyCoordinator.start(
            // MARK: - Layout Hotkey
            onPrimaryLeftStackedHorizontallyTile: {
                self.windowSpatialEngine.primaryLeftStackedHorizontallyTile()
            },
            onPrimaryRightStackedHorizontallyTile: {
                self.windowSpatialEngine.primaryRightStackedHorizontallyTile()
            },
            onPrimaryTile: {
                self.windowSpatialEngine.primaryTile()
            },
            
            // MARK: - Window Switcher
            onWindowViewer: {
                if self.windowViewerVM.isShown {
                    let nextIndex = self.windowViewerVM.selected + 1
                    guard self.windowCore.windows.indices.contains(nextIndex)
                    else {
                        /// If Next Index Doesnt Exist Start at 0 and return
                        self.windowViewerVM.selected = 0
                        return
                    }
                    self.windowViewerVM.selected = nextIndex
                } else {
                    Task {
                        self.windowViewerCoordinator.show()
                        self.windowViewerVM.selected = 0
                        await self.windowCore.loadWindows()
                    }
                }
            },
            onWindowViewerEscapeEarly: {
                if self.windowViewerVM.isShown {
                    self.windowViewerCoordinator.hide()
                    print("Called onWindowViewerEscapeEarly")
                }
            },
            
            // MARK: - Modifier Key
            //                        onOptDoubleTapDown: {
            //                            self.isHoldingModifier = true
            //                            self.shortcutHUDCoordinator.show()
            //                        },
            //                        onOptDoubleTapUp: {
            //                            self.isHoldingModifier = false
            ////                            self.shortcutHUDCoordinator.hide()
            //                        },
            //                        onCtrlDoubleTapDown: {
            //                            self.isHoldingModifier = true
            //                            self.shortcutHUDCoordinator.show()
            //                        },
            //                        onCtrlDoubleTapUp: {
            //                            self.isHoldingModifier = false
            ////                            self.shortcutHUDCoordinator.hide()
            //                        },
            
            // MARK: - Right Half
            onRightHalfDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.windowTilingService.getRightDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
            },
            onRightHalfUp: {
                self.shouldCloseWith {
                    self.windowSpatialEngine.tileRight()
                }
            },
            // MARK: - Left Half
            onLeftHalfDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.windowTilingService.getLeftDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
            },
            onLeftHalfUp: {
                self.shouldCloseWith {
                    self.windowSpatialEngine.tileLeft()
                }
            },
            
            // MARK: - Center
            onCenterDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.windowTilingService.getCenterDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
            },
            onCenterUp: {
                self.shouldCloseWith {
                    self.windowSpatialEngine.tileCenter()
                }
            },
            
            // MARK: - Full Screen
            onMaximizeDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.windowTilingService.getFullScreenDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
                
            },
            onMaximizeUp: {
                self.shouldCloseWith {
                    self.windowSpatialEngine.tileFullScreen()
                }
            },
            
            // MARK: - Nudge From Bottom
            onNudgeBottomDownDown: {
                self.windowSpatialEngine.nudgeBottomDown()
            },
            onNudgeBottomUpDown: {
                self.windowSpatialEngine.nudgeBottomUp()
            },
            
            // MARK: - Nudge From Top
            onNudgeTopUpDown: {
                self.windowSpatialEngine.nudgeTopUp()
            },
            onNudgeTopDownDown: {
                self.windowSpatialEngine.nudgeTopDown()
            }
        )
    }
}

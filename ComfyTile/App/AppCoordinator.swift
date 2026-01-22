//
//  AppCoordinator.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import CoreGraphics
import Foundation

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
        self.tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
        )
        self.windowSpatialEngine = WindowSpatialEngine(
            windowCore: appEnv.windowCore,
            windowLayoutService: windowLayoutService,
            windowTilingService: windowTilingService,
            defaultsManager: defaultsManager,
            tilingCoverCoordinator: tilingCoverCoordinator
        )
        
        self.comfyTileMenuBarVM = ComfyTileMenuBarViewModel(
            permissionService: permissionService,
            windowSpatialEngine: windowSpatialEngine,
            windowCore: appEnv.windowCore
        )
        
        self.menuBarCoordinator.start(
            comfyTileMenuBarVM: comfyTileMenuBarVM,
            settingsVM: settingsVM,
            defaultsManager: defaultsManager,
            windowCore: appEnv.windowCore,
            updateController: updateController
        )
        
        self.windowViewerCoordinator = WindowViewerCoordinator(
            windowViewerVM: windowViewerVM,
            windowCore: appEnv.windowCore
        )
        
        self.hotKeyCoordinator = HotKeyCoordinator()
        self.startHotKey()
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
            onOptDoubleTapDown: {
                self.isHoldingModifier = true
                print("HOLDING OPTION")
            },
            onOptDoubleTapUp: {
                self.isHoldingModifier = false
                print("RELEASED OPTION")
            },
            onCtrlDoubleTapDown: {
                self.isHoldingModifier = true
                print("HOLDING CONTROL")
            },
            onCtrlDoubleTapUp: {
                self.isHoldingModifier = false
                print("RELEASED CONTROL")
            },
            
            // MARK: - Right Half
            onRightHalfDown: {
                self.windowSpatialEngine.tileRightPressed()
            },
            onRightHalfUp: {
                self.windowSpatialEngine.tileRight()
            },
            // MARK: - Left Half
            onLeftHalfDown: {
                self.windowSpatialEngine.tileLeftPressed()
            },
            onLeftHalfUp: {
                self.windowSpatialEngine.tileLeft()
            },
            // MARK: - Center
            onCenterDown: {
                self.windowSpatialEngine.tileCenterPressed()
            },
            onCenterUp: {
                self.windowSpatialEngine.tileCenter()
            },
            
            // MARK: - Full Screen
            onMaximizeDown: {
                self.windowSpatialEngine.tileFullScreenPressed()
            },
            onMaximizeUp: {
                self.windowSpatialEngine.tileFullScreen()
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
        
        let key = defaultsManager.modiferKey
        
        self.shouldStartDoubleModifier()
        observeModifierKey()
    }
    
    internal func observeModifierKey() {
        withObservationTracking {
            _ = defaultsManager.modiferKey
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.shouldStartDoubleModifier()
                self.observeModifierKey()
            }
        }
    }
    
    /// Function handles what happens with the modifier key
    internal func shouldStartDoubleModifier() {
        let key = defaultsManager.modiferKey
        
        if key == .none {
            hotKeyCoordinator.stopModifier()
        } else {
            hotKeyCoordinator.startModifier(with: key)
        }
    }
}

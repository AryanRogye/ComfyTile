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
    let menuBarCoordinator          = MenuBarCoordinator()
    let hotKeyCoordinator           : HotKeyCoordinator
    let tilingCoverCoordinator      : TilingCoverCoordinator
    let windowViewerCoordinator     : WindowViewerCoordinator
    let highLightFocusedCoordinator : HighlightFocusedCoordinator
    
    /// ==============================================================================
    /// View Models
    /// ==============================================================================
    let comfyTileMenuBarVM : ComfyTileMenuBarViewModel
    let settingsVM         = SettingsViewModel()
    let tilingCoverVM      = TilingCoverViewModel()
    let windowViewerVM     = WindowViewerViewModel()
    let highlightVM        = HighlightFocusedViewModel()
    
    /// ==============================================================================
    /// Controllers
    /// ==============================================================================
    let updateController = UpdateController()
    
    /// Core Windowing
    private let windowCore          : WindowCore
    private let defaultsManager     = DefaultsManager()
    private let windowSpatialEngine : WindowSpatialEngine
    private var permissionService : PermissionService

    init(appEnv: AppEnv) {
        self.permissionService = PermissionService()
        self.windowCore = appEnv.windowCore
        self.windowTilingService = appEnv.windowTilingService
        self.windowLayoutService = appEnv.windowLayoutService
        self.tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
        )
        self.highLightFocusedCoordinator = HighlightFocusedCoordinator(
            windowCore: windowCore,
            highlightVM: highlightVM
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
    
    private func startHotKey() {
        hotKeyCoordinator.start(
            onToggleSuperFocus: {
                self.defaultsManager.superFocusWindow.toggle()
            },
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
//            onOptDoubleTapDown: {
//                self.windowCore.isHoldingModifier = true
//            },
//            onOptDoubleTapUp: {
//                self.windowCore.isHoldingModifier = false
//            },
//            onCtrlDoubleTapDown: {
//                self.windowCore.isHoldingModifier = true
//            },
//            onCtrlDoubleTapUp: {
//                self.windowCore.isHoldingModifier = false
//            },
            
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
        
        self.windowCore.highlightFocusedWindow = defaultsManager.highlightFocusedWindow
        self.windowCore.superFocusWindow = defaultsManager.superFocusWindow
        self.observeFocusedWindow()
    }
    
    internal func observeFocusedWindow() {
        withObservationTracking {
            _ = defaultsManager.highlightFocusedWindow;
            _ = defaultsManager.superFocusWindow
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let newHighlight = defaultsManager.highlightFocusedWindow
                let newSuperFocus = defaultsManager.superFocusWindow
                
                if self.windowCore.highlightFocusedWindow != newHighlight {
                    self.windowCore.highlightFocusedWindow = newHighlight
                }
                
                if self.windowCore.superFocusWindow != newSuperFocus {
                    self.windowCore.superFocusWindow = newSuperFocus
                }
                
                self.observeFocusedWindow()
            }
        }
    }
}

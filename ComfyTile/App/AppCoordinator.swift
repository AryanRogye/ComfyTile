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
    private let displayManager      : DisplayManager
    private let windowSpatialEngine : WindowSpatialEngine
    private var permissionService : PermissionService

    init(appEnv: AppEnv) {
        self.permissionService = PermissionService()
        self.displayManager = DisplayManager(ctx: appEnv.appServices.context)
        self.windowCore = appEnv.windowCore
        self.windowTilingService = appEnv.windowTilingService
        self.windowLayoutService = appEnv.windowLayoutService
        self.tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
        )
        self.highLightFocusedCoordinator = HighlightFocusedCoordinator(
            windowCore: windowCore,
            highlightVM: highlightVM,
            defaultsManager: defaultsManager
        )
        self.windowSpatialEngine = WindowSpatialEngine(
            windowCore: appEnv.windowCore,
            windowLayoutService: windowLayoutService,
            windowTilingService: windowTilingService,
            defaultsManager: defaultsManager,
            displayManager: displayManager,
            tilingCoverCoordinator: tilingCoverCoordinator
        )
        
        self.comfyTileMenuBarVM = ComfyTileMenuBarViewModel(
            permissionService: permissionService,
            windowSpatialEngine: windowSpatialEngine,
            windowCore: appEnv.windowCore
        )

        self.displayManager.start()

        self.menuBarCoordinator.start(
            comfyTileMenuBarVM: comfyTileMenuBarVM,
            settingsVM: settingsVM,
            defaultsManager: defaultsManager,
            windowCore: appEnv.windowCore,
            updateController: updateController,
            displayManager: displayManager
        )
        
        self.windowViewerCoordinator = WindowViewerCoordinator(
            windowViewerVM: windowViewerVM,
            windowCore: appEnv.windowCore
        )
        self.hotKeyCoordinator = HotKeyCoordinator()

        self.windowTilingService.setPaddingForScreen { screen in
            guard let id = screen.displayID else { return nil }
            guard let displayInfp = self.displayManager.displayInfo(for: id) else { return nil }
            if let padding = displayInfp.padding {
                return CGFloat(padding)
            }
            return nil
        }
        self.startHotKey()
        
        ScreenshotHelper.startCacheCleanupLoop()
    }
    
    deinit {
        ScreenshotHelper.clearAllCache()
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
            onWindowViewerBack: {
                /// cycle back only if is shown
                if self.windowViewerVM.isShown {
                    self.windowViewerVM.selectPrevious()
                }
            },
            onWindowViewer: {
                if self.windowViewerVM.isShown {
                    self.windowViewerVM.selectNext()
                } else {
                    Task {
                        self.windowViewerVM.beginCycle(with: self.windowCore.windows)
                        self.windowViewerCoordinator.show()

                        let windows = await self.windowCore.loadWindows()
                        guard self.windowViewerVM.isShown else { return }
                        self.windowViewerVM.refreshWindows(windows)
                    }
                }
            },
            onWindowViewerQuitWindow: {
                if self.windowViewerVM.isShown,
                   let window = self.windowViewerVM.selectedWindow {
                    self.windowCore.quit(window)
                    self.windowViewerVM.removeWindow(withID: window.id)

                    if self.windowViewerVM.windows.isEmpty {
                        self.windowViewerVM.onEscape()
                    }
                }
            },
            onWindowViewerFocusApp: {
                if self.windowViewerVM.isShown,
                   self.defaultsManager.allowFocusAppWindowOnWindowSwitcher {
                    self.windowViewerVM.toggleFocusedAppFilter()
                }
            },
            onWindowViewerEscapeEarly: {
                if self.windowViewerVM.isShown {
                    self.windowViewerCoordinator.hide()
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
            
            // MARK: - Top Half
            onTopHalfDown:  {
                self.windowSpatialEngine.tileTopHalfPressed()
            },
            onTopHalfUp:  {
                self.windowSpatialEngine.tileTopHalf()
            },
            // MARK: - Bottom Half
            onBottomHalfDown:  {
                self.windowSpatialEngine.tileBottomHalfPressed()
            },
            onBottomHalfUp:  {
                self.windowSpatialEngine.tileBottomHalf()
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
            // MARK: - Corners
            onTopLeftDown: {
                self.windowSpatialEngine.tileTopLeftPressed()
            },
            onTopLeftUp: {
                self.windowSpatialEngine.tileTopLeft()
            },
            onTopRightDown: {
                self.windowSpatialEngine.tileTopRightPressed()
            },
            onTopRightUp: {
                self.windowSpatialEngine.tileTopRight()
            },
            onBottomLeftDown: {
                self.windowSpatialEngine.tileBottomLeftPressed()
            },
            onBottomLeftUp: {
                self.windowSpatialEngine.tileBottomLeft()
            },
            onBottomRightDown: {
                self.windowSpatialEngine.tileBottomRightPressed()
            },
            onBottomRightUp: {
                self.windowSpatialEngine.tileBottomRight()
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
        
#if DEBUG
        self.hotKeyCoordinator.setDebugCompletion {
            self.windowCore.debugPress()
        }
#endif
    }
    
    internal func observeFocusedWindow() {
        withObservationTracking {
            _ = defaultsManager.highlightFocusedWindow;
            _ = defaultsManager.superFocusWindow
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                let newHighlight = self.defaultsManager.highlightFocusedWindow
                let newSuperFocus = self.defaultsManager.superFocusWindow
                
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

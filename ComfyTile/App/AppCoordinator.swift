//
//  AppCoordinator.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import Combine
import Observation
import Cocoa

@MainActor
class AppCoordinator {

    /// Coordinators

    var updateController                = UpdateController()
    private var windowTilingCoordinator : WindowTilingCoordinator?
    private var hotKeyCoordinator       : HotKeyCoordinator?
    private var tilingCoverCoordinator  : TilingCoverCoordinator
    private var shortcutHUDCoordinator  : ShortcutHUDCoordinator
    private var windowViewerCoordinator : WindowViewerCoordinator
    private var windowCoordinator       = WindowCoordinator()
    private var menuBarCoordinator      = MenuBarCoordinator()

    /// View Models
    private var comfyTileMenuBarVM     : ComfyTileMenuBarViewModel?
    private var tilingCoverVM          : TilingCoverViewModel
    private var shortcutHUDVM          : ShortcutHUDViewModel
    private var windowViewerVM         : WindowViewerViewModel
    private var settingsVM             = SettingsViewModel()

    let windowSplitManager = WindowSplitManager()

    private var permissionManager : PermissionService
    var defaultsManager           : DefaultsManager
    var fetchedWindowManager      : FetchedWindowManager

    let appEnv : AppEnv

    var cancellables: Set<AnyCancellable> = []

    var numKeysHeld = 0
    var isHoldingModifier = false

    deinit {
    }

    init(appEnv: AppEnv) {
        permissionManager = PermissionService()
        self.appEnv = appEnv
        self.defaultsManager = DefaultsManager()
        self.fetchedWindowManager = FetchedWindowManager()

        self.tilingCoverVM = TilingCoverViewModel()
        self.shortcutHUDVM = ShortcutHUDViewModel()
        self.windowViewerVM = WindowViewerViewModel()

        self.tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
        )

        self.shortcutHUDCoordinator = ShortcutHUDCoordinator(
            shortcutHUDVM: shortcutHUDVM
        )
        self.windowViewerCoordinator = WindowViewerCoordinator(
            windowViewerVM: windowViewerVM,
            fetchedWindowManager: fetchedWindowManager
        )

        windowTilingCoordinator = WindowTilingCoordinator(
            fetchedWindowManager: fetchedWindowManager,
            windowSplitManager: windowSplitManager,
            windowLayoutService: appEnv.windowLayoutService,
            defaultsManager: defaultsManager
        )
        guard let windowTilingCoordinator else { return }
        
        self.comfyTileMenuBarVM = ComfyTileMenuBarViewModel(
            windowTilingCoordinator: windowTilingCoordinator,
            fetchedWindowManager: fetchedWindowManager
        )
        guard let comfyTileMenuBarVM else { return }

        // Start the AppKit-based menu bar
        menuBarCoordinator.start(
            comfyTileMenuBarVM: comfyTileMenuBarVM,
            settingsVM: settingsVM,
            defaultsManager: defaultsManager,
            fetchedWindowManager: fetchedWindowManager,
            updateController: updateController
        )

        withObservationTracking { [weak self] in
            guard let self = self else { return }
            _ = self.defaultsManager.modiferKey
        } onChange: { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.hotKeyCoordinator?.startModifier(with: self.defaultsManager.modiferKey)
            }
        }

        hotKeyCoordinator = HotKeyCoordinator(
            onPrimaryLeftStackedHorizontallyTile: {
                self.windowTilingCoordinator?.primaryLeftStackedHorizontallyTile()
            },
            onPrimaryRightStackedHorizontallyTile: {
                self.windowTilingCoordinator?.primaryRightStackedHorizontallyTile()
            },
            onPrimaryTile: {
                self.windowTilingCoordinator?.primaryTile()
            },
            onWindowViewer: {
                if self.windowViewerVM.isShown {
                    let nextIndex = self.windowViewerVM.selected + 1
                    guard self.fetchedWindowManager.fetchedWindows.indices.contains(nextIndex)
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
                        await self.fetchedWindowManager.loadWindows()
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
                    if let rect = self.appEnv.windowLayoutService.getRightDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
            },
            onRightHalfUp: {
                self.shouldCloseWith {
                    self.windowTilingCoordinator?.tileRight()
                }
            },
            // MARK: - Left Half
            onLeftHalfDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.appEnv.windowLayoutService.getLeftDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
            },
            onLeftHalfUp: {
                self.shouldCloseWith {
                    self.windowTilingCoordinator?.tileLeft()
                }
            },

            // MARK: - Center
            onCenterDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.appEnv.windowLayoutService.getCenterDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }
            },
            onCenterUp: {
                self.shouldCloseWith {
                    self.windowTilingCoordinator?.tileCenter()
                }
            },

            // MARK: - Full Screen
            onMaximizeDown: {
                if self.defaultsManager.showTilingAnimations {
                    if let rect = self.appEnv.windowLayoutService.getFullScreenDimensions() {
                        self.showWith(rect: rect)
                    }
                    self.numKeysHeld += 1
                }

            },
            onMaximizeUp: {
                self.shouldCloseWith {
                    self.windowTilingCoordinator?.tileFullScreen()
                }
            },

            // MARK: - Nudge From Bottom
            onNudgeBottomDownDown: {
                self.windowTilingCoordinator?.nudgeBottomDown()
            },
            onNudgeBottomUpDown: {
                self.windowTilingCoordinator?.nudgeBottomUp()
            },

            // MARK: - Nudge From Top
            onNudgeTopUpDown: {
                self.windowTilingCoordinator?.nudgeTopUp()
            },
            onNudgeTopDownDown: {
                self.windowTilingCoordinator?.nudgeTopDown()
            }
        )

        self.hotKeyCoordinator?.startModifier(with: defaultsManager.modiferKey)
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
}

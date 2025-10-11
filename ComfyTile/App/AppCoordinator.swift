//
//  AppCoordinator.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import Combine


@MainActor
class AppCoordinator {
    
    /// Coordinators
    private var hotKeyCoordinator: HotKeyCoordinator?
    private var tilingCoverCoordinator : TilingCoverCoordinator
    private var shortcutHUDCoordinator : ShortcutHUDCoordinator
    
    /// View Models
    private var tilingCoverVM          : TilingCoverViewModel
    private var shortcutHUDVM          : ShortcutHUDViewModel
    
    private var permissionManager: PermissionService
    var defaultsManager  : DefaultsManager
    
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
        
        self.tilingCoverVM = TilingCoverViewModel()
        self.shortcutHUDVM = ShortcutHUDViewModel()
        
        self.tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
        )
        
        self.shortcutHUDCoordinator = ShortcutHUDCoordinator(
            shortcutHUDVM: shortcutHUDVM
        )
        
        defaultsManager.$modiferKey
            .removeDuplicates()
            .sink { [weak self] key in
                guard let self = self else { return }
                guard let hC = hotKeyCoordinator else { return }
                hC.startModifier(with: key)
            }
            .store(in: &cancellables)
            
        
        permissionManager.$isAccessibilityEnabled
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.permissionManager.isAccessibilityEnabled {
                    hotKeyCoordinator = HotKeyCoordinator(
                        
                        // MARK: - Modifier Key
                        onOptDoubleTapDown: {
                            self.isHoldingModifier = true
                            self.shortcutHUDCoordinator.show()
                        },
                        onOptDoubleTapUp: {
                            self.isHoldingModifier = false
//                            self.shortcutHUDCoordinator.hide()
                        },
                        onCtrlDoubleTapDown: {
                            self.isHoldingModifier = true
                            self.shortcutHUDCoordinator.show()
                        },
                        onCtrlDoubleTapUp: {
                            self.isHoldingModifier = false
//                            self.shortcutHUDCoordinator.hide()
                        },
                        
                        
                        // MARK: - Right Half
                        onRightHalfDown: {
                            if let rect = self.appEnv.windowLayoutService.getRightDimensions() {
                                self.tilingCoverCoordinator.show(with: rect)
                            }
                            self.numKeysHeld += 1
                        },
                        onRightHalfUp: {
                            self.shouldCloseWith {
                                self.appEnv.windowLayoutService.moveRight()
                            }
                        },
                        // MARK: - Left Half
                        onLeftHalfDown: {
                            if let rect = self.appEnv.windowLayoutService.getLeftDimensions() {
                                self.tilingCoverCoordinator.show(with: rect)
                            }
                            self.numKeysHeld += 1
                        },
                        onLeftHalfUp: {
                            self.shouldCloseWith {
                                self.appEnv.windowLayoutService.moveLeft()
                            }
                        },
                        
                        // MARK: - Center
                        onCenterDown: {
                            if let rect = self.appEnv.windowLayoutService.getCenterDimensions() {
                                self.tilingCoverCoordinator.show(with: rect)
                            }
                            self.numKeysHeld += 1
                        },
                        onCenterUp: {
                            self.shouldCloseWith {
                                self.appEnv.windowLayoutService.center()
                            }
                        },
                        
                        // MARK: - Full Screen
                        onMaximizeDown: {
                            if let rect = self.appEnv.windowLayoutService.getFullScreenDimensions() {
                                self.tilingCoverCoordinator.show(with: rect)
                            }
                            self.numKeysHeld += 1

                        },
                        onMaximizeUp: {
                            self.shouldCloseWith {
                                self.appEnv.windowLayoutService.fullScreen()
                            }
                        },
                        
                        
                        // MARK: - Nudge From Bottom
                        onNudgeBottomDownDown: {
                            self.appEnv.windowLayoutService.nudgeBottomDown(
                                with: self.defaultsManager.nudgeStep
                            )
                        },
                        onNudgeBottomUpDown: {
                            self.appEnv.windowLayoutService.nudgeBottomUp(
                                with: self.defaultsManager.nudgeStep
                            )
                        },
                        
                        
                        // MARK: - Nudge From Top
                        onNudgeTopUpDown: {
                            self.appEnv.windowLayoutService.nudgeTopUp(
                                with: self.defaultsManager.nudgeStep
                            )
                        },
                        onNudgeTopDownDown: {
                            self.appEnv.windowLayoutService.nudgeTopDown(
                                with: self.defaultsManager.nudgeStep
                            )
                        }
                    )
                    
                    self.hotKeyCoordinator?.startModifier(with: defaultsManager.modiferKey)
//                    self.hotKeyCoordinator?.startGlobalClickMonitor {
//                        if self.isHoldingModifier {
//                            print("IS HOLDING MODIFIER")
//                        }
//                    }
                    
                } else {
                    hotKeyCoordinator = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func shouldCloseWith(completion: @escaping () -> Void) {
        self.numKeysHeld -= 1
        if self.numKeysHeld == 0 {
            self.tilingCoverCoordinator.hide()
            completion()
        }
    }
}

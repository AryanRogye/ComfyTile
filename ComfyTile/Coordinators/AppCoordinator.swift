//
//  AppCoordinator.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import Combine


@MainActor
class AppCoordinator {
    
    private var hotKeyCoordinator: HotKeyCoordinator?
    private var tilingCoverCoordinator : TilingCoverCoordinator
    private var tilingCoverVM          : TilingCoverViewModel
    
    private var permissionManager: PermissionService
    var defaultsManager  : DefaultsManager
    
    let appEnv : AppEnv
    
    var cancellables: Set<AnyCancellable> = []
    
    var numKeysHeld = 0
    
    deinit {
    }
    
    init(appEnv: AppEnv) {
        permissionManager = PermissionService()
        self.appEnv = appEnv
        self.defaultsManager = DefaultsManager()
        self.tilingCoverVM = TilingCoverViewModel()
        self.tilingCoverCoordinator = TilingCoverCoordinator(
            tilingCoverVM: tilingCoverVM
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
                        onOptDoubleTapDown: {
                            print("Double Tap Option Down")
                        },
                        onOptDoubleTapUp: {
                            
                        },
                        onCtrlDoubleTapDown: {
                            print("Double Control Option Down")
                        },
                        onCtrlDoubleTapUp: {
                            
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
//                        print("Clicked")
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

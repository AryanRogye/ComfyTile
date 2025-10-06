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
    private var permissionManager: PermissionService
    var defaultsManager  : DefaultsManager
    
    let appEnv : AppEnv
    
    var cancellables: Set<AnyCancellable> = []
    
    init(appEnv: AppEnv) {
        permissionManager = PermissionService()
        self.appEnv = appEnv
        self.defaultsManager = DefaultsManager()
        
        permissionManager.$isAccessibilityEnabled
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.permissionManager.isAccessibilityEnabled {
                    hotKeyCoordinator = HotKeyCoordinator(
                        onRightHalfDown: {
                            self.appEnv.windowLayoutService.moveRight()
                        },
                        onLeftHalfDown: {
                            self.appEnv.windowLayoutService.moveLeft()
                        },
                        onCenterDown: {
                            self.appEnv.windowLayoutService.center()
                        },
                        onMaximizeDown: {
                            self.appEnv.windowLayoutService.fullScreen()
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
                } else {
                    print("DISABELD")
                    hotKeyCoordinator = nil
                }
            }
            .store(in: &cancellables)
    }
}

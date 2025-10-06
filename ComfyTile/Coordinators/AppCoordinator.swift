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
    
    let appEnv : AppEnv
    
    var cancellables: Set<AnyCancellable> = []
    
    init(appEnv: AppEnv) {
        permissionManager = PermissionService()
        self.appEnv = appEnv
        
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
                            self.appEnv.windowLayoutService.nudgeBottomDown()
                        },
                        onNudgeBottomUpDown: {
                            self.appEnv.windowLayoutService.nudgeBottomUp()
                        },
                        onNudgeTopUpDown: {
                            self.appEnv.windowLayoutService.nudgeTopUp()
                        },
                        onNudgeTopDownDown: {
                            self.appEnv.windowLayoutService.nudgeTopDown()
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

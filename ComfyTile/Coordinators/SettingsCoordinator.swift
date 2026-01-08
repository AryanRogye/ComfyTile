//
//  SettingsCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/8/26.
//

import SwiftUI

@Observable
@MainActor
class SettingsCoordinator {
    
    @ObservationIgnored
    let windowCoordinator: WindowCoordinator
    
    let updateController : UpdateController
    let defaultsManager  : DefaultsManager
    
    var isOpen = false
    
    init(
        windowCoordinator: WindowCoordinator,
        updateController: UpdateController,
        defaultsManager: DefaultsManager
    ) {
        self.windowCoordinator = windowCoordinator
        self.updateController = updateController
        self.defaultsManager = defaultsManager
    }
    
    func openSettings() {
        if isOpen { return }
        windowCoordinator.showWindow(
            id: UUID().uuidString,
            title: "Settings",
            content: SettingsView()
                .environment(defaultsManager)
                .environment(updateController),
            onOpen: { [ weak self] in
                guard let self else { return }
                self.isOpen = true
            },
            onClose: { [weak self] in
                guard let self else { return }
                self.isOpen = false
            }
        )
    }
}

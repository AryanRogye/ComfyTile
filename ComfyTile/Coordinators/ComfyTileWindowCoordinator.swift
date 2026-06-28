//
//  ComfyTileWindowCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI
import AppKit

class ComfyTileWindowCoordinator {
    
    typealias MenubarView = ComfyTileMenuBarRootView
    
    let windowCoordinator: WindowCoordinator
    weak var comfyTileMenuBarVM: ComfyTileMenuBarViewModel?
    
    init(windowCoordinator: WindowCoordinator) {
        self.windowCoordinator = windowCoordinator
    }
    
    let windowID = UUID().uuidString
    
    public func start(
        comfyTileMenuBarVM      : ComfyTileMenuBarViewModel,
        settingsVM              : SettingsViewModel,
        defaultsManager         : DefaultsManager,
        windowCore              : WindowCore,
        updateController        : UpdateController,
        displayManager          : DisplayManager
    ) {
        self.comfyTileMenuBarVM = comfyTileMenuBarVM
        
        let window = windowCoordinator.showWindow(
            id: windowID,
            title: "ComfyTile",
            content: MenubarView(
                settingsVM: settingsVM,
                comfyTileMenuBarVM: comfyTileMenuBarVM,
                defaultsManager: defaultsManager,
                windowCore: windowCore,
                updateController: updateController,
                displayManager: displayManager
            ),
            size: NSSize(
                width: comfyTileMenuBarVM.width,
                height: comfyTileMenuBarVM.height
            ),
            makeGlass: true,
            onResize: { resizing in
                comfyTileMenuBarVM.isResizing = resizing
            }
        )
        comfyTileMenuBarVM.panel = window
    }
    
    public func stop() {
        comfyTileMenuBarVM?.panel = nil
        windowCoordinator.closeWindow(id: windowID)
    }
}

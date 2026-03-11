//
//  ComfyTileMenuBarViewModel.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class ComfyTileMenuBarViewModel {
    
    let windowSpatialEngine: WindowSpatialEngine
    let windowCore   : WindowCore
    let permissionService : PermissionService
    
    var lastFocusedWindow : ComfyWindow? = nil
    
    var width: CGFloat = 350
    var height: CGFloat = 300
    
    /// trigger
    var showSettings = false
    private var showSettingsRevealWorkItem: DispatchWorkItem?
    
    var selectedTab: ComfyTileTabs = .tile
    
    var panel: NSPanel?
    
    var closePanel: () -> Void = { }
    
    @MainActor
    deinit {
        showSettingsRevealWorkItem?.cancel()
        showSettingsRevealWorkItem = nil
    }
    
    public func getLastFocusedWindow() {
        self.lastFocusedWindow = windowCore.getFocusedWindow()
    }
    
    init(
        permissionService : PermissionService,
        windowSpatialEngine: WindowSpatialEngine,
        windowCore: WindowCore
    ) {
        self.windowSpatialEngine = windowSpatialEngine
        self.windowCore = windowCore
        self.permissionService = permissionService
        observeTabs()
    }
    
    public func onTap(for tile: TilingMode) async {
        var fetchedWindow: ComfyWindow?
        
        if let lastFocusedWindow {
            print("Found Window")
            await windowCore.loadWindows()
            let fetchedWindows = windowCore.windows
            /// Check if Window in Here
            fetchedWindow = fetchedWindows.first(where: { $0.pid == lastFocusedWindow.pid })
            if let fetchedWindow {
                fetchedWindow.focusWindow()
            }
        }
        
        windowSpatialEngine.action(for: tile)
    }
    public func onTap(for layout: LayoutMode) {
        windowSpatialEngine.action(for: layout)
    }
}

extension ComfyTileMenuBarViewModel {
    func observeTabs() {
        withObservationTracking {
            _ = selectedTab
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard let panel else { return }
                self.showSettingsRevealWorkItem?.cancel()
                if selectedTab == .settings {
                    withAnimation(.snappy) {
                        self.width = 600
                        self.height = 400
                    }
                    
                    let revealWorkItem = DispatchWorkItem { [weak self] in
                        guard let self else { return }
                        guard self.selectedTab == .settings else { return }
                        withAnimation(.snappy(duration: 0.16, extraBounce: 0.0)) {
                            self.showSettings = true
                        }
                    }
                    self.showSettingsRevealWorkItem = revealWorkItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: revealWorkItem)
                } else {
                    withAnimation(.snappy) {
                        self.width = 350
                        self.height = 300
                        self.showSettings = false
                    }
                }
                
                let old = panel.frame
                let newFrame = NSRect(
                    x: old.midX - self.width / 2,     // keep center X
                    y: old.maxY - self.height,        // keep top Y fixed
                    width: self.width,
                    height: self.height
                )
                
                panel.setFrame(newFrame, display: true, animate: true)
                
                self.observeTabs()
            }
        }
    }
}

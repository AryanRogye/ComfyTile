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
    weak var settingsVM: SettingsViewModel?
    
    var lastFocusedWindow : ComfyWindow? = nil
    
    private let compactSize = CGSize(width: 350, height: 300)
    private let settingsDefaultSize = CGSize(width: 600, height: 400)
    private let layoutBuilderSize = CGSize(width: 920, height: 680)
    private let panelResizeAnimationDuration: TimeInterval = 0.24

    var width: CGFloat = 350
    var height: CGFloat = 300
    var deferLayoutBuilderRendering: Bool = false
    
    var selectedTab: ComfyTileTabs = .tile
    
    var panel: NSPanel?
    
    var closePanel: () -> Void = { }
    private var layoutBuilderRevealWorkItem: DispatchWorkItem?
    
    public func getLastFocusedWindow() {
        self.lastFocusedWindow = windowCore.getFocusedWindow()
    }
    
    init(
        permissionService : PermissionService,
        windowSpatialEngine: WindowSpatialEngine,
        windowCore: WindowCore,
        settingsVM: SettingsViewModel
    ) {
        self.windowSpatialEngine = windowSpatialEngine
        self.windowCore = windowCore
        self.permissionService = permissionService
        self.settingsVM = settingsVM
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
            _ = settingsVM?.selectedTab
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard let panel else { return }

                let targetSize = self.targetPanelSize()
                let old = panel.frame

                let screen = panel.screen
                    ?? NSScreen.main
                    ?? NSScreen.screens.first(where: { $0.frame.intersects(old) })
                let visible = (screen?.visibleFrame ?? old).insetBy(dx: 8, dy: 8)

                let clampedWidth = min(targetSize.width, visible.width)
                let clampedHeight = min(targetSize.height, visible.height)
                let willResize = abs(old.width - clampedWidth) > 1 || abs(old.height - clampedHeight) > 1
                let targetingLayoutBuilder = self.selectedTab == .settings && self.settingsVM?.selectedTab == .layoutBuilder

                self.updateLayoutBuilderDeferral(
                    shouldDefer: targetingLayoutBuilder && willResize
                )

                var x = old.midX - (clampedWidth / 2)    // keep center X
                var y = old.maxY - clampedHeight         // keep top Y

                x = min(max(x, visible.minX), visible.maxX - clampedWidth)
                y = min(max(y, visible.minY), visible.maxY - clampedHeight)

                withAnimation(.snappy) {
                    self.width = clampedWidth
                    self.height = clampedHeight
                }

                panel.setFrame(
                    NSRect(x: x, y: y, width: clampedWidth, height: clampedHeight),
                    display: true,
                    animate: true
                )
                
                self.observeTabs()
            }
        }
    }
    
    private func targetPanelSize() -> CGSize {
        guard selectedTab == .settings else {
            return compactSize
        }
        
        if settingsVM?.selectedTab == .layoutBuilder {
            return layoutBuilderSize
        }
        
        return settingsDefaultSize
    }
    
    private func updateLayoutBuilderDeferral(shouldDefer: Bool) {
        layoutBuilderRevealWorkItem?.cancel()
        
        guard shouldDefer else {
            deferLayoutBuilderRendering = false
            return
        }
        
        deferLayoutBuilderRendering = true
        let reveal = DispatchWorkItem { [weak self] in
            self?.deferLayoutBuilderRendering = false
        }
        layoutBuilderRevealWorkItem = reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + panelResizeAnimationDuration, execute: reveal)
    }
}

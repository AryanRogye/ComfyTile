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
    
    var lastFocusedWindow : ComfyWindow? = nil {
        didSet {
            print("Did Set: \(lastFocusedWindow)")
        }
    }
    
    var width: CGFloat = 350
    var height: CGFloat = 300
    
    var selectedTab: ComfyTileTabs = .tile
    
    var panel: NSPanel?
    
    public func getLastFocusedWindow() {
        self.lastFocusedWindow = windowCore.getFocusedWindow()
    }
    
    init(
        windowSpatialEngine: WindowSpatialEngine,
        windowCore: WindowCore
    ) {
        self.windowSpatialEngine = windowSpatialEngine
        self.windowCore = windowCore
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
                if selectedTab == .settings {
                    withAnimation(.snappy) {
                        self.width = 600
                        self.height = 400
                    }
                } else {
                    withAnimation(.snappy) {
                        self.width = 350
                        self.height = 300
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


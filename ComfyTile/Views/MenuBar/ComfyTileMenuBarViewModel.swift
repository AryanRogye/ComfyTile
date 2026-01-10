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
    var width: CGFloat = 400
    var height: CGFloat = 300
    
    var selectedTab: ComfyTileTabs = .tile
    
    var panel: NSPanel?
    
    init() {
        observeTabs()
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
                        self.width = 400
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


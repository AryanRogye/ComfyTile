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
    
    var tabPlacement : ComfyTileTabPlacement = .bottom
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
                if selectedTab == .settings {
                    withAnimation(.snappy) {
                        self.width = 600
                        self.height = 400
                    }
                    self.panel?.setFrame(NSRect(x: 0, y: 0, width: self.width, height: self.height), display: true)
                } else {
                    withAnimation(.snappy) {
                        self.width = 400
                        self.height = 300
                    }
                    self.panel?.setFrame(NSRect(x: 0, y: 0, width: self.width, height: self.height), display: true)
                }
                self.observeTabs()
            }
        }
    }
}


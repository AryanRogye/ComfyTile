//
//  ComfyTileMenuBarTabContainer.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/5/26.
//

import SwiftUI

struct ComfyTileMenuBarTabContainer<Content: View>: View {
    @Environment(DefaultsManager.self) var defaultsManager
    @ViewBuilder var content: Content
    
    var body: some View {
        @Bindable var defaultsManager = defaultsManager
        VStack(spacing: 0) {
            if defaultsManager.comfyTileTabPlacement == .top {
                ComfyTileTabBar(tabPlacement: $defaultsManager.comfyTileTabPlacement)
                    .transition(.move(edge: .top))
            }
            
            content
            
            if defaultsManager.comfyTileTabPlacement == .bottom {
                ComfyTileTabBar(tabPlacement: $defaultsManager.comfyTileTabPlacement)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.snappy(duration: 0.25, extraBounce: 0.1), value: defaultsManager.comfyTileTabPlacement)
    }
}

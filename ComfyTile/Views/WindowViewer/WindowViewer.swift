//
//  WindowViewer.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/3/25.
//

import SwiftUI

struct WindowViewer: View {
    
    @Bindable var windowViewerVM : WindowViewerViewModel
    @Bindable var fetchedWindowManager : FetchedWindowManager
    
    var body: some View {
        VStack {
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(fetchedWindowManager.favoriteWindows, id: \.self) { window in
                    Button(action: {
                        window.focusWindow()
                    }) {
                        VStack {
                            if let sc = window.screenshot {
                                Image(decorative: sc, scale: 1.0)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 150)
                            }
                            Text(window.windowTitle)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
        }
        .padding()
        .background(.ultraThinMaterial)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onExitCommand {
            windowViewerVM.onEscape?()
            print("Escape Called")
        }
    }
}

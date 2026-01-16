//
//  WindowViewer.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/3/25.
//

import SwiftUI
import LocalShortcuts

struct WindowViewer: View {
    
    @Bindable var windowViewerVM : WindowViewerViewModel
    @Bindable var windowCore : WindowCore
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(windowCore.windows, id: \.windowID) { window in
                    Button(action: {
                        let index = windowViewerVM.selected
                        windowCore.windows[index].focusWindow()
                        
                        let focused = windowCore.windows.remove(at: index)
                        windowCore.windows.insert(focused, at: 0)
                        
                        windowViewerVM.onEscape()
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
                        .padding()
                        .background {
                            if window.id == windowCore.windows[windowViewerVM.selected].id {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 300)
    }
}

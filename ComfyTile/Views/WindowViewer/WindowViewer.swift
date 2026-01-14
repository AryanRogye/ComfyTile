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
    @Bindable var fetchedWindowManager : FetchedWindowManager
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(fetchedWindowManager.fetchedWindows, id: \.windowID) { window in
                    Button(action: {
                        let index = windowViewerVM.selected
                        fetchedWindowManager.fetchedWindows[index].focusWindow()
                        
                        let focused = fetchedWindowManager.fetchedWindows.remove(at: index)
                        fetchedWindowManager.fetchedWindows.insert(focused, at: 0)
                        
                        windowViewerVM.onEscape()
                    }) {
                        VStack {
                            if let sc = window.screenshot {
                                Image(decorative: sc, scale: 1.0)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 150)
                            }
                            if let title = window.windowTitle {
                                Text(title)
                            }
                        }
                        .padding()
                        .background {
                            if window.id == fetchedWindowManager.fetchedWindows[windowViewerVM.selected].id {
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

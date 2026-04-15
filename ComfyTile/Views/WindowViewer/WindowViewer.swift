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
    
    var spacingAround : CGFloat {
        6
    }
    
    var spacing: CGFloat {
        6
    }
    
    var cardWidth: CGFloat {
        230
    }
    
    var cardHeight: CGFloat {
        200
    }
    
    var body: some View {
        VStack {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: cardWidth),
                        spacing: spacing
                    )
                ],
                spacing: spacing
            ) {
                ForEach(windowCore.windows, id: \.windowID) { window in
                    let selected = window.id == windowCore.windows[windowViewerVM.selected].id

                    WindowCard(
                        appName: window.app.localizedName ?? "Unknown",
                        appIcon: window.app.icon,
                        appScreenshot: window.screenshot,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        onClose: window.element.quit,
                        onMinimize: window.element.toggleMinimize,
                        onMaximize: window.maximize,
                        selected: selected,
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let index = windowViewerVM.selected
                        windowCore.windows[index].focusWindow()
                        
                        let focused = windowCore.windows.remove(at: index)
                        windowCore.windows.insert(focused, at: 0)
                        
                        windowViewerVM.onEscape()
                    }
                }
            }
        }
        .padding()
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 300)
    }
}

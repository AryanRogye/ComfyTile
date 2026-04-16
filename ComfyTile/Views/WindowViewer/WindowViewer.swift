//
//  WindowViewer.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/3/25.
//

import SwiftUI
import LocalShortcuts

struct WindowViewer: View {
    
    @Environment(\.colorScheme) private var scheme
    @Bindable var windowViewerVM : WindowViewerViewModel
    @Bindable var windowCore : WindowCore
    
    /// Spacing Around All Windows
    var spacingAround : CGFloat { 6 }
    
    /// Spacing Windows Vertically and Horizontally
    var spacing   : CGFloat { 6 }
    
    /// Card WxH
    var cardWidth : CGFloat { 230 }
    var cardHeight: CGFloat { 220 }
    
    var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 32)
    }
    
    var columns : [GridItem] {
        [GridItem(
            .adaptive(minimum: cardWidth),
            spacing: spacing
        )]
    }
    
    @Namespace private var selectionAnimation
    
    var body: some View {
        windows
            .padding(spacingAround)
            .animation(.spring, value: windowCore.windows)
            .glassEffect(
                .regular,
                in: backgroundShape
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 300)
    }
    
    private var windows: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(windowCore.windows, id: \.windowID) { window in
                
                let selected = isSelected(window)
                
                WindowCard(
                    appName: window.app.localizedName ?? "Unknown",
                    windowTitle: window.windowTitle,
                    appIcon: window.app.icon,
                    appScreenshot: window.screenshot,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    onClose: {
                        windowCore.quit(window)
                    },
                    onMinimize: window.element.toggleMinimize,
                    onMaximize: window.maximize,
                    selected: selected,
                    selectionNamespace: selectionAnimation,
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if let index = windowCore.windows.firstIndex(where: { $0.id == window.id }) {
                        windowCore.focusWindow(at: index)
                        windowViewerVM.onEscape()
                    }
                }
            }
        }
    }
    
    /// We're basically checking if the window is selected or not
    /// we have to check if it exists before we set a selected cuz
    /// this avoids a index out of range crash if we're selected while
    /// we press the quit button
    private func isSelected(_ window: ComfyWindow) -> Bool {
        guard windowCore.windows.indices.contains(windowViewerVM.selected) else { return false }
        return windowCore.windows[windowViewerVM.selected].id == window.id
    }
}

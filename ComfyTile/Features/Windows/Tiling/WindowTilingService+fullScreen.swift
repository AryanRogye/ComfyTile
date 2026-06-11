//
//  WindowTilingService+fullScreen.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import Cocoa

extension WindowTilingService {
    // MARK: - Tile
    func fullScreen(withAnimation: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse() else { return }
        
        let frame = screen.visibleFrame
        
        let pos = frame.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: frame.width,
                height: frame.height
            )
        }
        
        resetSmartTiling()
        
        if withAnimation {
            animator.animate(focusedWindow: focusedWindow, to: pos, duration: 0.13) {
                move()
            }
        } else {
            focusedWindow.element.setPosition(x: pos.x, y: pos.y)
            move()
        }
    }
    
    // MARK: - Dimensions
    func getFullScreenDimensions() -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }
        
        let frame = screen.visibleFrame
        
        return CGRect(
            x : frame.minX,
            y : frame.minY,
            width : frame.width,
            height : frame.height
        )
    }

}

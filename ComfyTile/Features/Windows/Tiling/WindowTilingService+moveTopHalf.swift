//
//  WindowTilingService+moveTopHalf.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import Cocoa

extension WindowTilingService {
    
    func moveTopHalf(withAnimation: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse() else { return }
        
        /// Screen
        let frame = screen.visibleFrame
        
        let width = frame.width
        let height = frame.height / 2
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y + frame.height / 2,
            width: width,
            height: height
        )
        
        let pos = rect.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: rect.width,
                height: rect.height
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
    
    func getTopHalfDimensions() -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }
        
        /// Screen
        let frame = screen.visibleFrame
        
        let width = frame.width
        let height = frame.height / 2
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y + frame.height / 2,
            width: width,
            height: height
        )
        
        return rect
    }
}

//
//  WindowTilingService+moveLeft.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import Cocoa

extension WindowTilingService {
    // MARK: - Tile
    func moveLeft(withAnimation: Bool, isLayoutCycling: Bool, enableSmartTiling: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse() else { return }
        
        /// Screen
        let frame = screen.visibleFrame
        
        let width: CGFloat
        
        /// LayoutCycling + SmartTiling + Never Just Tiled Left
        /// "Prediction"
        if isLayoutCycling && enableSmartTiling && self.hasJustTiledLeft == 0 && self.hasJustTiledRight > 0 {
            /// Other sides "last" layout
            let predictedLayout = self.rightLayout.last().complementary()
            
            width = frame.width * predictedLayout.widthMultiplier
            
            /// set current with predicted and cycle next
            self.leftLayout = predictedLayout
            self.leftLayout.nextLayout()
        }
        /// We're Just Layout Cycling
        else if isLayoutCycling {
            width = frame.width * self.leftLayout.widthMultiplier
            self.leftLayout.nextLayout()
        }
        /// Neither
        else {
            width = frame.width * 0.5
        }
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: width,
            height: frame.height
        )
        
        let pos = rect.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: rect.width,
                height: rect.height
            )
        }
        
        hasJustTiledRight = 0
        hasJustTiledCenter = 0
        if self.hasJustTiledLeft == 0 {
            hasJustTiledLeft += 1
        }
        
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
    func getLeftDimensions(isLayoutCycling: Bool, enableSmartTiling: Bool) -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }
        
        let frame = screen.visibleFrame
        let width: CGFloat
        
        if isLayoutCycling && enableSmartTiling && self.hasJustTiledLeft == 0 && self.hasJustTiledRight > 0 {
            width = frame.width * self.rightLayout.last().complementary().widthMultiplier
        } else if isLayoutCycling {
            width = frame.width * self.leftLayout.widthMultiplier
        } else {
            width = frame.width * 0.5
        }
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: width,
            height: frame.height
        )
        
        return rect
        
    }
}

//
//  WindowTilingService+moveRight.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import Cocoa

extension WindowTilingService {
    // MARK: - Tile
    public func moveRight(withAnimation: Bool, isLayoutCycling: Bool, enableSmartTiling: Bool) {
        
        let (focusedWindow, screen) = getFocusedAndScreen()
        guard let focusedWindow, let screen else { return }

        let frame = screen.visibleFrame
        
        let width: CGFloat
        /// LayoutCycling + SmartTiling + Never Just Tiled Left
        /// "Prediction"
        if isLayoutCycling && enableSmartTiling && self.hasJustTiledRight == 0 && self.hasJustTiledLeft > 0 {
            /// Other sides "last" layout
            let predictedLayout = self.leftLayout.last().complementary()
            
            width = frame.width * predictedLayout.widthMultiplier
            
            /// set current with predicted and cycle next
            self.rightLayout = predictedLayout
            self.rightLayout.nextLayout()
            
        }
        /// We're Just Layout Cycling
        else if isLayoutCycling {
            width = frame.width * self.rightLayout.widthMultiplier
            self.rightLayout.nextLayout()
        }
        /// Neither
        else {
            width = frame.width * 0.5
        }
        
        let rect = NSRect(
            x: frame.maxX - width,
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
            
            /// Fixing With Over Correction
            Task {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                
                let applied = focusedWindow.element.frame
                let appliedWidth = applied.width
                
                let targetRect = CGRect(
                    x: frame.maxX - appliedWidth,   // anchor to right edge
                    y: frame.origin.y,
                    width: appliedWidth,
                    height: frame.height
                )
                
                let targetPos = targetRect.axPosition(on: screen)
                
                focusedWindow.element.setPosition(x: targetPos.x, y: targetPos.y)
                focusedWindow.element.setSize(width: targetRect.width, height: targetRect.height)
            }
        }
        
        hasJustTiledLeft = 0
        hasJustTiledCenter = 0
        if self.hasJustTiledRight == 0 {
            hasJustTiledRight += 1
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
    public func getRightDimensions(isLayoutCycling: Bool, enableSmartTiling: Bool) -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }
        
        let frame = screen.visibleFrame
        let width: CGFloat
        
        if isLayoutCycling && enableSmartTiling && self.hasJustTiledRight == 0 && self.hasJustTiledLeft > 0  {
            width = frame.width * self.leftLayout.last().complementary().widthMultiplier
        } else if isLayoutCycling {
            width = frame.width * self.rightLayout.widthMultiplier
        } else {
            width = frame.width * 0.5
        }
        
        let rect = NSRect(
            x: frame.maxX - width,
            y: frame.origin.y,
            width: width,
            height: frame.height
        )
        
        return rect
    }
}

//
//  WindowTilingService+center.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/9/26.
//

import Cocoa

extension WindowTilingService {
    // MARK: - Tile
    func center(withAnimation: Bool, padding: Double, isLayoutCycling: Bool, isUsingAdvancedPadding: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse() else { return }
        
        let frame = screen.visibleFrame
        
        let layout = isLayoutCycling ? centerLayout : .center
        
        let centeredSize: CGSize
        let centeredOrigin: CGPoint
        
        /// Padding Config
        let centerPadding: CGFloat
        
        if isUsingAdvancedPadding {
            centerPadding = paddingForScreen?(screen) ?? CGFloat(padding)
        } else {
            centerPadding = CGFloat(padding)
        }
        
        
        switch layout {
        case .center:
            
            centeredSize = CGSize(
                width: frame.width - (centerPadding * 2),
                height: frame.height - (centerPadding * 2)
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + centerPadding,
                y: frame.origin.y + centerPadding
            )
            
        case .centerExpanded:
            centeredSize = CGSize(
                width: frame.width - (centerPadding * 2),
                height: frame.height
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + centerPadding,
                y: frame.origin.y
            )
        }
        
        if isLayoutCycling {
            centerLayout.nextLayout()
        }
        
        
        /// Creating Target Rect
        let rect = NSRect(x: centeredOrigin.x, y: centeredOrigin.y, width: centeredSize.width, height: centeredSize.height)
        let pos = rect.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: centeredSize.width,
                height: centeredSize.height
            )
        }
        
        hasJustTiledLeft = 0
        hasJustTiledRight = 0
        
        if hasJustTiledCenter == 0 {
            hasJustTiledCenter += 1
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
    func getCenterDimensions(padding: Double, isLayoutCycling: Bool, isUsingAdvancedPadding: Bool) -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }
        
        let frame = screen.visibleFrame
        
        let layout = isLayoutCycling ? centerLayout : .center
        
        let centeredSize: CGSize
        let centeredOrigin: CGPoint
        
        
        /// Padding Config
        let centerPadding: CGFloat
        
        if isUsingAdvancedPadding {
            centerPadding = paddingForScreen?(screen) ?? CGFloat(padding)
        } else {
            centerPadding = CGFloat(padding)
        }
        
        
        switch layout {
        case .center:
            
            centeredSize = CGSize(
                width: frame.width - (centerPadding * 2),
                height: frame.height - (centerPadding * 2)
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + centerPadding,
                y: frame.origin.y + centerPadding
            )
            
        case .centerExpanded:
            centeredSize = CGSize(
                width: frame.width - (centerPadding * 2),
                height: frame.height
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + centerPadding,
                y: frame.origin.y
            )
        }
        
        /// Creating Target Rect
        let rect = NSRect(
            x: centeredOrigin.x,
            y: centeredOrigin.y,
            width: centeredSize.width,
            height: centeredSize.height
        )
        
        return rect
    }
}

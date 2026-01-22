//
//  WindowTilingService.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import Cocoa
//import ComfyWindowingCore

class WindowTilingService: WindowTilingProviding {
    
    let windowCore: WindowCore
    let animator = WindowAnimator()
    
    init(windowCore: WindowCore) {
        self.windowCore = windowCore
    }
    
    /// Keep Window Where it is, but its top point is moved up
    func nudgeTopUp(with step: Int) {
        guard let f = windowCore.getFocusedWindow(),
              var frame = f.element.windowFrame else { return }

        let delta: CGFloat = CGFloat(step)
        frame.origin.y -= delta
        frame.size.height += delta
        
        f.element.setPosition(x: frame.origin.x, y: frame.origin.y)
        f.element.setSize(width: frame.width, height: frame.height)
    }
    
    func nudgeTopDown(with step: Int) {
        guard let f = windowCore.getFocusedWindow(),
              var frame = f.element.windowFrame else { return }

        let delta: CGFloat = CGFloat(step)
        frame.origin.y += delta
        frame.size.height -= delta
        
        f.element.setPosition(x: frame.origin.x, y: frame.origin.y)
        f.element.setSize(width: frame.width, height: frame.height)
    }
    
    
    func nudgeBottomDown(with step: Int) {
        guard let f = windowCore.getFocusedWindow() else { return }
        
        // current frame
        guard var frame = f.element.windowFrame else { return }

        let delta: CGFloat = CGFloat(step)
        frame.size.height += delta
        
        // apply
        f.element.setSize(width: frame.width, height: frame.height)
    }
    
    func nudgeBottomUp(with step: Int) {
        guard let f = windowCore.getFocusedWindow() else { return }
        
        // current frame
        guard var frame = f.element.windowFrame else { return }
        
        let delta: CGFloat = CGFloat(step)
        frame.size.height -= delta
        
        // apply
        f.element.setSize(width: frame.width, height: frame.height)
    }
    
    func fullScreen(withAnimation: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
        let screen = focusedWindow.screen else { return }
        
        let frame = screen.visibleFrame
        
        let pos = frame.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: frame.width,
                height: frame.height
            )
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
    
    // MARK: - Center
    func center(withAnimation: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = focusedWindow.screen else { return }
        
        /// This is padding around all sides of the window
        let padding : CGFloat = 40
        
        let frame = screen.visibleFrame
        
        let centeredSize = CGSize(
            width: frame.width - (padding * 2),
            height: frame.height - (padding * 2)
        )
        
        let centeredOrigin = CGPoint(
            x: frame.origin.x + padding,
            y: frame.origin.y + (padding)
        )
        
        /// Creating Target Rect
        let rect = NSRect(x: centeredOrigin.x, y: centeredOrigin.y, width: centeredSize.width, height: centeredSize.height)
        let pos = rect.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: centeredSize.width,
                height: centeredSize.height
            )
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
    
    // MARK: - Move Left
    func moveLeft(withAnimation: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
        let screen = focusedWindow.screen else { return }
        
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        let pos = rect.axPosition(on: screen)
        
        let move = {
            focusedWindow.element.setSize(
                width: rect.width,
                height: rect.height
            )
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
    
    // MARK: - Move Right
    func moveRight(withAnimation: Bool) {
        
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = focusedWindow.screen else { return }

        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x + halfWidth,
            y: frame.origin.y,
            width: halfWidth,
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
        
        if withAnimation {
            animator.animate(focusedWindow: focusedWindow, to: pos, duration: 0.13) {
                move()
            }
        } else {
            focusedWindow.element.setPosition(x: pos.x, y: pos.y)
            move()
        }
    }
    
    func getFullScreenDimensions() -> CGRect? {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = focusedWindow.screen else { return nil }

        let frame = screen.visibleFrame
        
        return CGRect(
            x : frame.minX,
            y : frame.minY,
            width : frame.width,
            height : frame.height
        )
    }
    func getLeftDimensions() -> CGRect? {
        guard let focusedWindow = windowCore.getFocusedWindow(),
            let screen = focusedWindow.screen else { return nil }
        
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        return rect
        
    }
    func getRightDimensions() -> CGRect? {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = focusedWindow.screen else { return nil }

        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x + halfWidth,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        return rect
    }
    
    func getCenterDimensions() -> CGRect? {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = focusedWindow.screen else { return nil }

        /// This is padding around all sides of the window
        let padding : CGFloat = 40
        
        let frame = screen.visibleFrame
        
        let centeredSize = CGSize(
            width: frame.width - (padding * 2),
            height: frame.height - (padding * 2)
        )
        
        let centeredOrigin = CGPoint(
            x: frame.origin.x + padding,
            y: frame.origin.y + (padding)
        )
        
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

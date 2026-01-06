//
//  WindowLayoutService.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import Cocoa

class WindowLayoutService: WindowLayoutProviding {
    
    let animator = WindowAnimator()
    
    /// Keep Window Where it is, but its top point is moved up
    func nudgeTopUp(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow(),
              var frame = f.windowFrame else { return }

        let delta: CGFloat = CGFloat(step)
        frame.origin.y -= delta
        frame.size.height += delta
        
        
        f.setPosition(x: frame.origin.x, y: frame.origin.y)
        f.setSize(width: frame.width, height: frame.height)
    }
    
    func nudgeTopDown(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow(),
              var frame = f.windowFrame else { return }

        let delta: CGFloat = CGFloat(step)
        frame.origin.y += delta
        frame.size.height -= delta
        
        f.setPosition(x: frame.origin.x, y: frame.origin.y)
        f.setSize(width: frame.width, height: frame.height)
    }
    
    
    func nudgeBottomDown(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow() else { return }
        
        // current frame
        guard var frame = f.windowFrame else { return }

        let delta: CGFloat = CGFloat(step)
        frame.size.height += delta
        
        // apply
        f.setSize(width: frame.width, height: frame.height)
    }
    
    func nudgeBottomUp(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow() else { return }
        
        // current frame
        guard var frame = f.windowFrame else { return }
        
        let delta: CGFloat = CGFloat(step)
        frame.size.height -= delta
        
        // apply
        f.setSize(width: frame.width, height: frame.height)
    }
    
    func fullScreen() {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        let frame = screen.visibleFrame
        
        let pos = WindowManagerHelpers.axPosition(for: frame, on: screen)
        
        animator.animate(focusedWindow: focusedWindow, to: pos, duration: 0.13) {
            focusedWindow.setSize(
                width: frame.width,
                height: frame.height
            )
        }
    }
    
    func center() {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        
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
        let pos =  WindowManagerHelpers.axPosition(for: rect, on: screen)
        
        animator.animate(focusedWindow: focusedWindow, to: pos, duration: 0.13) {
            focusedWindow.setSize(
                width: centeredSize.width,
                height: centeredSize.height
            )
        }
    }
    
    // MARK: - Move Left
    func moveLeft() {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        let pos = WindowManagerHelpers.axPosition(for: rect, on: screen)
        
        animator.animate(focusedWindow: focusedWindow, to: pos, duration: 0.13) {
            focusedWindow.setSize(
                width: rect.width,
                height: rect.height
            )
        }
    }
    
    // MARK: - Move Right
    func moveRight() {
        
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x + halfWidth,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        let pos = WindowManagerHelpers.axPosition(for: rect, on: screen)
        
        animator.animate(focusedWindow: focusedWindow, to: pos, duration: 0.13) {
            focusedWindow.setSize(
                width: rect.width,
                height: rect.height
            )
        }
    }
    
    func getFullScreenDimensions() -> CGRect? {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return nil }
        
        let screen = focusedWindow.screen
        
        let frame = screen.visibleFrame
        
        return CGRect(
            x : frame.minX,
            y : frame.minY,
            width : frame.width,
            height : frame.height
        )
    }
    func getLeftDimensions() -> CGRect? {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return nil }
        
        let screen = focusedWindow.screen
        
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
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return nil }
        
        let screen = focusedWindow.screen
        
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
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return nil }
        
        let screen = focusedWindow.screen
        
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

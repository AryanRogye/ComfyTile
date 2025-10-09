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
              var frame = WindowManagerHelpers.windowFrame(f.element) else { return }
        
        let delta: CGFloat = CGFloat(step)
        frame.origin.y -= delta
        frame.size.height += delta
        
        
        WindowManagerHelpers.setWindowPosition(f.element, position: frame.origin)
        WindowManagerHelpers.setWindowSize(f.element, size: frame.size)
    }
    
    func nudgeTopDown(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow(),
              var frame = WindowManagerHelpers.windowFrame(f.element) else { return }
        
        let delta: CGFloat = CGFloat(step)
        frame.origin.y += delta
        frame.size.height -= delta
        
        WindowManagerHelpers.setWindowPosition(f.element, position: frame.origin)
        WindowManagerHelpers.setWindowSize(f.element, size: frame.size)
    }
    
    
    func nudgeBottomDown(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow() else { return }
        let el = f.element
        
        // current frame
        guard var frame = WindowManagerHelpers.windowFrame(el) else { return }
        
        let delta: CGFloat = CGFloat(step)
        frame.size.height += delta
        
        // apply
        WindowManagerHelpers.setWindowSize(el, size: frame.size)
    }
    
    func nudgeBottomUp(with step: Int) {
        guard let f = WindowManagerHelpers.getFocusedWindow() else { return }
        let el = f.element
        
        // current frame
        guard var frame = WindowManagerHelpers.windowFrame(el) else { return }
        
        let delta: CGFloat = CGFloat(step)
        frame.size.height -= delta
        
        // apply
        WindowManagerHelpers.setWindowSize(el, size: frame.size)
    }
    
    func fullScreen() {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        let window = focusedWindow.element
        
        let frame = screen.visibleFrame
        
        let pos = WindowManagerHelpers.axPosition(for: frame, on: screen)
        
        animator.animate(el: window, to: pos, duration: 0.13) {
            WindowManagerHelpers.setWindowSize(
                window,
                size: CGSize(
                    width: frame.width,
                    height: frame.height
                )
            )
        }
    }
    
    func center() {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        let window = focusedWindow.element
        
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
        
        animator.animate(el: window, to: pos, duration: 0.13) {
            WindowManagerHelpers.setWindowSize(
                window,
                size: centeredSize
            )
        }
    }
    
    // MARK: - Move Left
    func moveLeft() {
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        let window = focusedWindow.element
        
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        let pos = WindowManagerHelpers.axPosition(for: rect, on: screen)
        
        animator.animate(el: window, to: pos, duration: 0.13) {
            WindowManagerHelpers.setWindowSize(
                window,
                size: rect.size
            )
        }
    }
    
    // MARK: - Move Right
    func moveRight() {
        
        guard let focusedWindow = WindowManagerHelpers.getFocusedWindow() else { return }
        
        let screen = focusedWindow.screen
        let window = focusedWindow.element
        
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        
        let rect = NSRect(
            x: frame.origin.x + halfWidth,
            y: frame.origin.y,
            width: halfWidth,
            height: frame.height
        )
        
        let pos = WindowManagerHelpers.axPosition(for: rect, on: screen)
        
        animator.animate(el: window, to: pos, duration: 0.13) {
            WindowManagerHelpers.setWindowSize(
                window,
                size: rect.size
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

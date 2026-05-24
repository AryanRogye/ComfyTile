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
    
    var leftLayout: HorizontalTileLayout = .half
    var rightLayout: HorizontalTileLayout = .half
    var centerLayout: CenterTileLayout = .center

    var hasJustTiledLeft = 0
    var hasJustTiledRight = 0
    var hasJustTiledCenter = 0

    init(windowCore: WindowCore) {
        self.windowCore = windowCore
    }
}

// MARK: - Tiling
extension WindowTilingService {
    // MARK: - Full Screen
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
        
        hasJustTiledLeft = 0
        hasJustTiledRight = 0
        hasJustTiledCenter = 0

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
    func center(withAnimation: Bool, padding: Double, isLayoutCycling: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse() else { return }

        let frame = screen.visibleFrame

        let layout = isLayoutCycling ? centerLayout : .center

        let centeredSize: CGSize
        let centeredOrigin: CGPoint

        let padding: CGFloat = CGFloat(padding)

        switch layout {
        case .center:

            centeredSize = CGSize(
                width: frame.width - (padding * 2),
                height: frame.height - (padding * 2)
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + padding,
                y: frame.origin.y + padding
            )

        case .centerExpanded:
            centeredSize = CGSize(
                width: frame.width - (padding * 2),
                height: frame.height
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + padding,
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
    
    // MARK: - Tile Left
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
    
    // MARK: - Tile Right
    func moveRight(withAnimation: Bool, isLayoutCycling: Bool, enableSmartTiling: Bool) {
        
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse() else { return }
        
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

}

// MARK: - Nudging
extension WindowTilingService {
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
}

// MARK: - Helpers
extension WindowTilingService {
    
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
    
    func getRightDimensions(isLayoutCycling: Bool, enableSmartTiling: Bool) -> CGRect? {
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

    
    func getCenterDimensions(padding: Double, isLayoutCycling: Bool) -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }

        let frame = screen.visibleFrame

        let layout = isLayoutCycling ? centerLayout : .center

        let centeredSize: CGSize
        let centeredOrigin: CGPoint


        let padding: CGFloat = CGFloat(padding)

        switch layout {
        case .center:

            centeredSize = CGSize(
                width: frame.width - (padding * 2),
                height: frame.height - (padding * 2)
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + padding,
                y: frame.origin.y + padding
            )

        case .centerExpanded:
            centeredSize = CGSize(
                width: frame.width - (padding * 2),
                height: frame.height
            )
            centeredOrigin = CGPoint(
                x: frame.origin.x + padding,
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

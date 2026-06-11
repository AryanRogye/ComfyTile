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

    var paddingForScreen: ((NSScreen) -> CGFloat?)?

    init(
        windowCore: WindowCore,
    ) {
        self.windowCore = windowCore
    }

    public func setPaddingForScreen(_ padding: @escaping (NSScreen) -> CGFloat?) {
        self.paddingForScreen = padding
    }
    
    public func resetSmartTiling() {
        hasJustTiledLeft = 0
        hasJustTiledRight = 0
        hasJustTiledCenter = 0
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

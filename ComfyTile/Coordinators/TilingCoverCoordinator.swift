//
//  TilingCoverCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/8/25.
//

import AppKit
import SwiftUI

class TilingCoverCoordinator : NSObject {
    
    var panel : NSPanel!
    var isShown: Bool = false
    
    override init() {
        super.init()
    }
    
    /// We Will Setup A fullscreen display
    func setupPanel(with rect: CGRect) {
        panel = FocusablePanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.setFrame(rect, display: true)
        /// Allow content to draw outside panel bounds
        panel.contentView?.wantsLayer = true
        
        panel.registerForDraggedTypes([.fileURL])
        panel.title = "ComfyNotch"
        panel.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        panel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        
        let view: NSView = NSHostingView(
            rootView: TilingCover()
        )
        
        /// Allow hosting view to overflow
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)
    }
    
    public func show(with rect: CGRect) {
        if self.panel == nil {
            setupPanel(with: rect)
            panel?.layoutIfNeeded()
        }
        guard let panel = self.panel else {
            print("Cant Show, Overlay is nil")
            return
        }
        panel.setFrame(rect, display: true, animate: true)
        isShown = true
        panel.orderFrontRegardless()
    }
    
    public func hide() {
        guard let panel = panel else {
            print("Cant Hide, Overlay is nil")
            return
        }
        
        if panel.isVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                self.panel?.orderOut(nil)
                isShown = false
            }
        }
    }

}

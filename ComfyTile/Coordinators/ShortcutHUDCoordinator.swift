//
//  ShortcutHUDCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/10/25.
//

import AppKit
import Combine
import SwiftUI

class ShortcutHUDViewModel: ObservableObject {
    @Published var isShown = false
    
    var onEscape: (() -> Void)?
    
}

@MainActor
class ShortcutHUDCoordinator: NSObject {
    
    var panel : NSPanel!
    var shortcutHUDVM: ShortcutHUDViewModel!
    
    init(shortcutHUDVM : ShortcutHUDViewModel) {
        self.shortcutHUDVM = shortcutHUDVM
        super.init()
        
        /// Set Escape
        self.shortcutHUDVM.onEscape = { [weak self] in
            guard let self = self else { return }
            hide()
        }
    }
    
    public func setupPanel() {
        guard let screen = WindowManagerHelpers.screenUnderMouse() else { return }
        panel = FocusablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.setFrame(screen.frame, display: true)
        /// Allow content to draw outside panel bounds
        panel.contentView?.wantsLayer = true
        
        panel.registerForDraggedTypes([.fileURL])
        panel.title = "SS"
        panel.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        panel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .fullScreenDisallowsTiling,
            .ignoresCycle,
            .transient
        ]

        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        
        let view: NSView = NSHostingView(
            rootView: ShortcutHUD()
                .environmentObject(shortcutHUDVM)
        )
        
        /// Allow hosting view to overflow
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)

    }
    
    public func show() {
        if self.panel == nil {
            setupPanel()
            panel?.layoutIfNeeded()
        }
        guard let panel = self.panel else {
            print("Cant Show, Overlay is nil")
            return
        }
        shortcutHUDVM.isShown = true
        panel.makeKeyAndOrderFront(nil)
    }
    
    public func hide() {
        guard let _ = panel else {
            print("Cant Hide, Overlay is nil")
            return
        }
        
        shortcutHUDVM.isShown = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.panel?.orderOut(nil)
        }
    }
}

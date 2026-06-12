//
//  TileRingCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/11/26.
//

import SwiftUI

@Observable
@MainActor
final class TileRingViewModel {
    var isShown: Bool = false
}

final class TileRingCoordinator: NSObject {
    
    var panel: NSPanel!
    let vm: TileRingViewModel
    
    /// Main in-app key monitor.
    /// Handles Escape and modifier state while our app is active.
    ///
    /// ⚠️ Important:
    /// This ONLY fires while events are routed through our app.
    /// If the user clicks another app while holding the modifier,
    /// we will NOT receive the release event here.
    private var localKeyMonitor: Any?
    
    /// Global fallback for modifier tracking.
    ///
    /// Used specifically to detect modifier key release even when
    /// our app is no longer active like when the user clicks another
    /// window while holding Option
    private var globalFlagsMonitor: Any?
    
    /// Observes when the app loses focus (click-away / app switch).
    ///
    /// This is somewhat unreliable with nonactivating panels:
    /// - Sometimes fires exactly when we want (great for cleanup)
    /// - Sometimes does nothing (macOS being macOS)
    ///
    /// We treat this as a *best-effort hint*, not a source of truth.
    /// Core logic should NOT depend on this firing.
    private var resignActiveObserver: Any?
    
    /// Screen used on the panel last
    private var lastScreen: NSScreen?
    
    init(vm: TileRingViewModel) {
        self.vm = vm
        
        super.init()
    }
    
    public func setupPanel() {
        guard let screen = WindowCore.screenUnderMouse() else { return }
        lastScreen = screen
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
        panel.title = "TR"
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
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        
        let view: NSView = NSHostingView(
            rootView: TileRingView()
        )
        
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)
    }
    
    public func show() {
        if panel == nil { setupPanel() }
        
        guard let screen = WindowCore.screenUnderMouse() else { return }
        /// move if not the same screen to avoid redrawing
        if lastScreen != screen {
            panel.setFrame(screen.frame, display: true)
            lastScreen = screen
        }
        
        vm.isShown = true
        panel.makeKeyAndOrderFront(nil)
    }
    
    public func hide() {
        vm.isShown = false
        panel?.orderOut(nil)
    }
}

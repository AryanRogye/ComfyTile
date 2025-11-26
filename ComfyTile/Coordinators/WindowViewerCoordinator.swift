//
//  WindowViewerCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/3/25.
//

import AppKit
import Combine
import SwiftUI

@Observable @MainActor
class WindowViewerViewModel {
    var isShown = false
    
    var onEscape: (() -> Void)?
}

@MainActor
class WindowViewerCoordinator: NSObject {
    
    var panel : NSPanel!
    var windowViewerVM: WindowViewerViewModel
    var fetchedWindowManager : FetchedWindowManager
    
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    
    init(windowViewerVM : WindowViewerViewModel, fetchedWindowManager : FetchedWindowManager) {
        self.windowViewerVM = windowViewerVM
        self.fetchedWindowManager = fetchedWindowManager
        super.init()
        
        /// Set Escape
        self.windowViewerVM.onEscape = { [weak self] in
            guard let self = self else { return }
            print("Calling Hide")
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
            rootView: WindowViewer(
                windowViewerVM: windowViewerVM,
                fetchedWindowManager: fetchedWindowManager
            )
        )
        
        /// Allow hosting view to overflow
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)
        
    }
    
    public func show() {
        if panel == nil { setupPanel() }
        windowViewerVM.isShown = true
        panel.makeKeyAndOrderFront(nil) // ok even if nonactivating
        installKeyMonitors()
    }
    
    private func installKeyMonitors() {
        // Fires when app is active; can consume the event
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            if e.keyCode == 53 { // ESC
                self?.windowViewerVM.onEscape?()
                return nil // swallow
            }
            return e
        }
        // Fires even if app isn’t active; can’t swallow but good backup
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] e in
            if e.keyCode == 53 {
                self?.windowViewerVM.onEscape?()
            }
        }
    }

    public func hide() {
        windowViewerVM.isShown = false
        removeKeyMonitors()
        panel?.orderOut(nil)
    }
    
    private func removeKeyMonitors() {
        if let m = localKeyMonitor { NSEvent.removeMonitor(m); localKeyMonitor = nil }
        if let m = globalKeyMonitor { NSEvent.removeMonitor(m); globalKeyMonitor = nil }
    }
}

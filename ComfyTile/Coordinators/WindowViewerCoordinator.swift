//
//  WindowViewerCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/3/25.
//

import AppKit
import Combine
import SwiftUI
import LocalShortcuts

@Observable @MainActor
class WindowViewerViewModel {
    var isShown = false
    
    var onEscape: (() -> Void)?
    
    var selected: Int = 0
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
    
    static let escape = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.escape]
    )
    static let option = LocalShortcuts.Shortcut(
        modifier: [.option],
        keys: []
    )
    
    public func installKeyMonitors() {
        // Fires when app is active; can consume the event
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] e in
            guard let self else { return e }
            
            if e.type == .flagsChanged && windowViewerVM.isShown {
                print("Event: \(e)")
                let modifier = LocalShortcuts.Modifier.activeModifiers(from: e)
                /// No Modifier Held
                if modifier == [] {
                    print("Modifier Exit")
                    let window = fetchedWindowManager.fetchedWindows[windowViewerVM.selected]
                    window.focusWindow()
                    self.windowViewerVM.onEscape?()
                }
            } else {
                let key = LocalShortcuts.Key.activeKeys(event: e)
                if key == [.escape] {
                    print("Escape Hide")
                    self.windowViewerVM.onEscape?()
                    return nil // swallow
                }
            }
            
            return e
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

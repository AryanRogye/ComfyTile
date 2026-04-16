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
    
    var onEscape: (() -> Void) = { }
    
    var selected: Int = 1
    
    public func reset() {
        self.selected = 1
    }
}

@MainActor
class WindowViewerCoordinator: NSObject {
    
    var panel : NSPanel!
    var windowViewerVM: WindowViewerViewModel
    var windowCore    : WindowCore
    
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
    
    init(windowViewerVM : WindowViewerViewModel, windowCore : WindowCore) {
        self.windowViewerVM = windowViewerVM
        self.windowCore = windowCore
        super.init()
        
        /// Set Escape
        self.windowViewerVM.onEscape = { [weak self] in
            guard let self = self else { return }
            windowViewerVM.reset()
            hide()
        }
    }
    
    @MainActor
    deinit {
        removeKeyMonitors()
    }
    
    public func setupPanel() {
        guard let screen = WindowCore.screenUnderMouse() else { return }
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
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        
        let view: NSView = NSHostingView(
            rootView: WindowViewer(
                windowViewerVM: windowViewerVM,
                windowCore: windowCore
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
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitors()
    }
    
    public func hide() {
        windowViewerVM.isShown = false
        removeKeyMonitors()
        panel?.orderOut(nil)
    }

    @discardableResult
    /**
     * Function Returns True if event was escape
     */
    private func handleEvent(
        e : NSEvent,
    ) -> Bool {
        if e.type == .flagsChanged && windowViewerVM.isShown {
            let modifier = LocalShortcuts.Modifier.activeModifiers(from: e)
            
            /// No Modifier Held
            if modifier == [] {
                let index = windowViewerVM.selected
                
                windowCore.focusWindow(at: index)
                
                self.windowViewerVM.onEscape()
            }
        } else {
            let key = LocalShortcuts.Key.activeKeys(event: e)
            if key == [.escape] {
                self.windowViewerVM.onEscape()
                return true
            }
        }
        return false
    }
    
    public func installKeyMonitors() {
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] e in
            guard let self else { return }
            handleEvent(e: e)
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] e in
            guard let self else { return e }
            
            if handleEvent(e: e) {
                return nil
            }
            
            return e
        }
        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.windowViewerVM.isShown {
                    self.hide()
                }
            }
        }
    }

    private func removeKeyMonitors() {
        if let m = localKeyMonitor {
            NSEvent.removeMonitor(m)
            localKeyMonitor = nil
        }	
        if let g = globalFlagsMonitor {
            NSEvent.removeMonitor(g)
            globalFlagsMonitor = nil
        }
        if let resignActiveObserver {
            NotificationCenter.default.removeObserver(resignActiveObserver)
            self.resignActiveObserver = nil
        }
    }
}

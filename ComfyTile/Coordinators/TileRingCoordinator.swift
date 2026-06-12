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
    var currentTile: TileRingSide = .none
    
    var diameter: CGFloat = 10
    var debugBox: CGRect?
    var debugMousePoint: CGPoint?
}

@MainActor
final class TileRingCoordinator: NSObject {
    
    var panel: NSPanel!
    let vm: TileRingViewModel
    let defaultsManager: DefaultsManager
    
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
    
    init(vm: TileRingViewModel, defaultsManager: DefaultsManager) {
        self.vm = vm
        self.defaultsManager = defaultsManager
        
        super.init()
    }
    
    @MainActor
    deinit {
        removeKeyMonitors()
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
            rootView: TileRingView(vm: vm)
        )
        
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Toggles
extension TileRingCoordinator {
    public func show() {
        if panel == nil { setupPanel() }
        
        guard let screen = WindowCore.screenUnderMouse() else { return }
        /// move if not the same screen to avoid redrawing
        if lastScreen != screen {
            panel.setFrame(screen.frame, display: true)
            lastScreen = screen
        }
        
        vm.diameter = defaultsManager.tileRingActivationDiameter
        vm.isShown = true
        panel.makeKeyAndOrderFront(nil)
        centerMousePosition()
        installKeyMonitors()
    }
    
    public func centerMousePosition() {
        guard let screen = lastScreen,
              let displayID = screen.displayID
        else { return }
        
        let point = CGPoint(
            x: screen.frame.width / 2,
            y: screen.frame.height / 2
        )
        
        CGDisplayMoveCursorToPoint(displayID, point)
    }
    
    public func hide() -> TileRingSide {
        vm.isShown = false
        panel?.orderOut(nil)
        removeKeyMonitors()
        let tile = vm.currentTile
        vm.currentTile = .none
        return tile
    }
}

// MARK: - Key Monitors
extension TileRingCoordinator {
    public func installKeyMonitors() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved]
        ) { [weak self] e in
            guard let self else { return e }
            handleEvent(e)
            return e
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved]
        ) { [weak self] e in
            guard let self else { return }
            handleEvent(e)
        }
    }
    
    private func removeKeyMonitors() {
        if let g = globalFlagsMonitor {
            NSEvent.removeMonitor(g)
            globalFlagsMonitor = nil
        }
        if let l = globalFlagsMonitor {
            NSEvent.removeMonitor(l)
            localKeyMonitor = nil
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        
        guard let screen = lastScreen else { return }
        
        let diameter = defaultsManager.tileRingActivationDiameter
        let mouse: NSPoint = NSEvent.mouseLocation
        
        let localMouse = CGPoint(
            x: mouse.x - screen.frame.minX,
            y: screen.frame.maxY - mouse.y
        )
        
        let screenCenter = CGPoint(
            x: screen.frame.width / 2,
            y: screen.frame.height / 2
        )
        
        let center = NSRect(
            x: screenCenter.x - diameter / 2,
            y: screenCenter.y - diameter / 2,
            width: diameter,
            height: diameter
        )
        
        let cx = screenCenter.x
        let cy = screenCenter.y
        let dx = localMouse.x - cx
        let dy = localMouse.y - cy
        let distance = sqrt(dx * dx + dy * dy)
        let radius = diameter / 2
        
        vm.debugBox = center
        vm.debugMousePoint = localMouse
        
        if distance < radius {
            vm.currentTile = .none
            return
        }
        
        let angle = atan2(dy, dx) * (180 / .pi)
        let normalized = (angle + 360).truncatingRemainder(dividingBy: 360)
        
        vm.currentTile = TileRingSide.tileSide(for: normalized)
    }

}

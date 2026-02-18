//
//  HighlightFocusedCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 2/16/26.
//

import SwiftUI
import AppKit


enum HighlightConfiguration {
    case superFocus
    case border
}

@Observable
@MainActor
final class HighlightFocusedViewModel {
    var isShown = false
    
    var currentFocused: ComfyWindow?
    var highlightConfig: [HighlightConfiguration] = []
    var isFullScreen: Bool = false
    
    var onShow: ((ComfyWindow?) -> Void)?
    var onHide: (() -> Void)?
    
    @ObservationIgnored @MainActor
    var highLightTask: Task<Void, Never>?
    
    var cornerRadius: CGFloat {
        
        /// Standard regular windows without a toolbar
        let titlebarRadius : CGFloat = 16
        
        /// Windows with a compact toolbar
        let comapctToolbarRadius : CGFloat = 20
        
        /// Unified Window Radius
        let toolbarWindowRadius : CGFloat = 26
        
        guard let currentFocused else { return titlebarRadius }
        guard let appName = currentFocused.app.localizedName?.lowercased() else { return titlebarRadius }
        guard let bundleIdentifier = currentFocused.bundleIdentifier?.lowercased() else { return titlebarRadius }
        
        if bundleIdentifier.contains("com.apple") {
            return toolbarWindowRadius
        }
        if bundleIdentifier.contains("com.jetbrains") {
            return titlebarRadius
        }
        /// Zed Github says they use 16pt radius
        if bundleIdentifier.contains("dev.zed") {
            return titlebarRadius
        }
        if appName.contains("ghostty") {
            return comapctToolbarRadius
        }
        
        return comapctToolbarRadius
    }
    
    init() {
        observeFocused()
        observeFullScreen()
    }
    
    func observeFullScreen() {
        withObservationTracking {
            _ = isFullScreen
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                print("IS FULLSCREEN: \(isFullScreen)")

                if isFullScreen {
                    onHide?()
                } else {
                    if let _ = currentFocused {
                        onShow?(currentFocused)
                    } else {
                        onHide?()
                    }
                }
                
                observeFullScreen()
            }
        }
    }
    
    func observeFocused()  {
        withObservationTracking {
            _ = currentFocused;
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                if let _ = currentFocused, !isFullScreen {
                    onShow?(currentFocused)
                    syncHighlightThrottling()
                } else {
                    onHide?()
                }
                
                self.observeFocused()
            }
        }
    }
    
    var displayFrame: CGRect = .zero
    var displayPos: CGPoint = .zero
    
    func computePos(from frame: CGRect) -> CGPoint {
        
        guard let screen = currentFocused?.screen ?? WindowCore.screenUnderMouse(),
              let desktopTopY = NSScreen.screens.map(\.frame.maxY).max() else {
            return .zero
        }
        
        let panelLocalX = frame.origin.x - screen.frame.minX
        let screenTopAX = desktopTopY - screen.frame.maxY
        let panelLocalY = frame.origin.y - screenTopAX
        
        return CGPoint(
            x: panelLocalX + (frame.width / 2),
            y: panelLocalY + (frame.height / 2)
        )
    }
    
    func syncHighlight() {
        let newFrame = currentFocused?.element.frame ?? .zero
        let newPos = computePos(from: newFrame)
        
        guard !Task.isCancelled else { return }
        
        if newFrame == .zero {
            displayFrame = newFrame
            displayPos = newPos
        } else {
            withAnimation(.smooth) {
                self.displayFrame = newFrame
                self.displayPos = newPos
            }
        }
    }
    func syncHighlightThrottling() {
        /// Throttling highlight requests to make sure no weird glitchy things happen
        highLightTask?.cancel()
        highLightTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(0.1 * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            let newFrame = currentFocused?.element.frame ?? .zero
            let newPos = computePos(from: newFrame)
            
            guard !Task.isCancelled else { return }

            if newFrame == .zero {
                displayFrame = newFrame
                displayPos = newPos
            } else {
                withAnimation(.smooth) {
                    self.displayFrame = newFrame
                    self.displayPos = newPos
                }
            }
            highLightTask = nil
        }
    }
}

final class HighlightFocusedCoordinator: NSObject {
    
    var panel      : NSPanel!
    var windowCore : WindowCore
    var highlightVM : HighlightFocusedViewModel
    var defaultsManager: DefaultsManager
    
    @MainActor var hideTask: Task<Void, Never>?

    init(windowCore: WindowCore, highlightVM: HighlightFocusedViewModel, defaultsManager: DefaultsManager) {
        self.windowCore = windowCore
        self.highlightVM = highlightVM
        self.defaultsManager = defaultsManager
        
        super.init()
        
        windowCore.onNewFrame = { [weak self] win, highlightConfig, isFullScreen in
            guard let self else { return }
            self.highlightVM.currentFocused = win
            self.highlightVM.highlightConfig = highlightConfig
            self.highlightVM.isFullScreen = isFullScreen
        }

        highlightVM.onShow = { window in
            self.show(window: window)
        }
        highlightVM.onHide = {
            self.hide()
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(loadWindowsThenShowIfNeeded),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(loadWindowsThenShowIfNeeded),
            name: NSWorkspace.willLaunchApplicationNotification,
            object: nil
        )
    }
    
    @objc func loadWindowsThenShowIfNeeded() {
        windowCore.unAsyncLoadWindows { [weak self] in
                guard let self else { return }
                if highlightVM.isShown {
                    if let foc = windowCore.getFocusedWindow() {
                        foc.focusWindow()
                    }
                }
        }
    }
    
    @objc
    private func activeSpaceChanged() {
        guard let panel else { return }
        self.windowCore.unAsyncLoadWindows { [weak self] in
            guard let self else { return }
            
            let screen =
            highlightVM.currentFocused?.screen
            ?? WindowCore.screenUnderMouse()
            ?? NSScreen.main
            
            if let screen {
                panel.setFrame(screen.frame, display: true)
            }
            /// This works really well
            if self.highlightVM.isShown {
                hide()
                if let comfyWindow = highlightVM.currentFocused {
                    self.show(window: comfyWindow)
                }
            }
        }
    }
    
    var panelScreen: NSScreen?
    func setupPanel() {
        guard let screen = WindowCore.screenUnderMouse() else { return }
        panelScreen = screen
        panel = FocusablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.setFrame(screen.frame, display: true)
        /// Allow content to draw outside panel bounds
        panel.contentView?.wantsLayer = true
        panel.acceptsMouseMovedEvents = true
        
        let normalRaw = CGWindowLevelForKey(.normalWindow)
        panel.level = NSWindow.Level(rawValue: Int(normalRaw) + 1)
        
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
        panel.ignoresMouseEvents = true
        
        let view: NSView = NSHostingView(
            rootView: HighlightView(
                highlightVM: highlightVM,
                defaultsManager: defaultsManager
            )
        )
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.orderFrontRegardless()
    }
    
    func show(window: ComfyWindow?) {
        if panel == nil { setupPanel() }
        
        if let window {
            if let screen = window.screen, screen != panelScreen {
                panelScreen = screen
                panel.setFrame(screen.frame, display: true)
            }
            
            highlightVM.isShown = true
            hideTask?.cancel()
            hideTask = nil
            panel.orderFrontRegardless()
        }
    }
    
    public func hide() {
        hideTask?.cancel()
        hideTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(1.5 * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }

            self.panel?.orderOut(nil)
            self.highlightVM.isShown = false
            self.hideTask = nil
        }
    }
}

struct HighlightView: View {
    @Bindable var highlightVM: HighlightFocusedViewModel
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        if highlightVM.highlightConfig.contains(.superFocus) {
            FocusCutoutShape(
                size: highlightVM.displayFrame.size,
                center: highlightVM.displayPos,
                cornerRadius: highlightVM.cornerRadius
            )
            .fill(defaultsManager.superFocusColor, style: FillStyle(eoFill: true))
            .overlay {
                HighlightRing(highlightVM: highlightVM, color: .white)
            }
        } else {
            HighlightRing(
                highlightVM: highlightVM,
                color: defaultsManager.highlightFocusedWindowColor,
                lineWidth: defaultsManager.highlightedFocusedWindowWidth
            )
        }
    }
}

struct HighlightRing: View {
    
    @Bindable var highlightVM: HighlightFocusedViewModel
    var color: Color = .yellow
    var lineWidth: CGFloat = 1.5
    
    var body: some View {
        RoundedRectangle(cornerRadius: highlightVM.cornerRadius)
            .stroke(color, lineWidth: lineWidth)
            .frame(width: highlightVM.displayFrame.width, height: highlightVM.displayFrame.height)
            .position(x: highlightVM.displayPos.x, y: highlightVM.displayPos.y)
    }
}


struct FocusCutoutShape: Shape {
    var size: CGSize
    var center: CGPoint
    var cornerRadius: CGFloat
    
    // This tells SwiftUI exactly how to interpolate the shape during a .spring animation
    var animatableData: AnimatablePair<CGSize.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(size.animatableData, center.animatableData) }
        set {
            size.animatableData = newValue.first
            center.animatableData = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path(rect) // The full screen outer bounds
        
        // Calculate the hole
        let cutoutRect = CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        
        // Adding a shape inside another shape creates a hole when using eoFill
        path.addRoundedRect(in: cutoutRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius), style: .continuous)
        
        return path
    }
}

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
    
    var onShow: ((ComfyWindow?) -> Void)?
    var onHide: (() -> Void)?
    
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
            return toolbarWindowRadius
        }
        
        return comapctToolbarRadius
    }
    
    init() {
        observeFocused()
    }
    
    func observeFocused()  {
        withObservationTracking {
            _ = currentFocused
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let _ = currentFocused {
                    onShow?(currentFocused)
                } else {
                    onHide?()
                }
                
                self.observeFocused()
                syncHighlight()
            }
        }
    }
    
    var displayFrame: CGRect = .zero
    var displayPos: CGPoint = .zero
    
    func computePos(from frame: CGRect) -> CGPoint {
        guard let screen = WindowCore.screenUnderMouse(),
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
        let newPos = computePos(from: newFrame) // your math, returns center-point
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            displayFrame = newFrame
            displayPos = newPos
        }
    }
}

final class HighlightFocusedCoordinator: NSObject {
    
    var panel      : NSPanel!
    var windowCore : WindowCore
    var highlightVM : HighlightFocusedViewModel
    
    init(windowCore: WindowCore, highlightVM: HighlightFocusedViewModel) {
        self.windowCore = windowCore
        self.highlightVM = highlightVM
        
        super.init()
        
        windowCore.onNewFrame = { [weak self] win, highlightConfig in
            guard let self else { return }
            self.highlightVM.currentFocused = win
            self.highlightVM.highlightConfig = highlightConfig
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
    }
    
    @objc private func activeSpaceChanged() {
        guard let panel else { return }
        self.windowCore.unAsyncLoadWindows()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            let screen = WindowCore.screenUnderMouse() ?? NSScreen.main
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
//        if windowCore.superFocusWindow {
//            print("Config Contains Super Focus - Settings Panel to one level below normal")
            panel.level = NSWindow.Level(rawValue: Int(normalRaw))
//        } else {
//            print("Config Does not Contain Super Focus - Settings Panel to one level below normal")
//            panel.level = NSWindow.Level(rawValue: Int(normalRaw) - 1)
//        }
        
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
                highlightVM: highlightVM
            )
        )
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.orderFrontRegardless()
    }
    
    func show(window: ComfyWindow?) {
        if panel == nil { setupPanel() }
        
        if let screen = WindowCore.screenUnderMouse(), screen != panelScreen {
            panelScreen = screen
            panel.setFrame(screen.frame, display: true)
        }
        
        highlightVM.isShown = true
        panel.orderFrontRegardless()
    }
    
    public func hide() {
        panel?.orderOut(nil)
        highlightVM.isShown = false
    }
}

struct HighlightView: View {
    @Bindable var highlightVM: HighlightFocusedViewModel
    
    var body: some View {
        if highlightVM.highlightConfig.contains(.superFocus) {
//            VisualEffectView(material: .menu)
            Rectangle()
                .fill(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .compositingGroup()
                .drawingGroup()
            
                .mask {
                    Rectangle()
                        .overlay {
                            RoundedRectangle(cornerRadius: highlightVM.cornerRadius)
                                .frame(width: highlightVM.displayFrame.width,
                                       height: highlightVM.displayFrame.height)
                                .position(x: highlightVM.displayPos.x, y: highlightVM.displayPos.y)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
                .overlay {
                    HighlightRing(highlightVM: highlightVM, color: .white)
                }
        } else {
            HighlightRing(highlightVM: highlightVM)
        }
    }
}

struct HighlightRing: View {
    
    @Bindable var highlightVM: HighlightFocusedViewModel
    var color: Color = .yellow
    
    var body: some View {
        VStack {
        }
        .frame(width: highlightVM.displayFrame.width, height: highlightVM.displayFrame.height)
        /// Just 1 padding so it can pop out a little bit
        .padding(1)
        .background {
            RoundedRectangle(cornerRadius: highlightVM.cornerRadius)
                .fill(.clear)
                .stroke(color, lineWidth: 1.5)
        }
        .position(x: highlightVM.displayPos.x, y: highlightVM.displayPos.y)
    }
}


struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

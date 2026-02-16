//
//  HighlightFocusedCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 2/16/26.
//

import SwiftUI
import AppKit

@Observable
@MainActor
final class HighlightFocusedViewModel {
    var isShown = false
    var currentFocused: ComfyWindow?
    
    var onShow: (() -> Void)?
    var onHide: (() -> Void)?
    
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
                    onShow?()
                } else {
                    onHide?()
                }
                
                self.observeFocused()
            }
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
        
        
        windowCore.onNewFrame = { win in
            highlightVM.currentFocused = win
        }
        
        super.init()
        
        highlightVM.onShow = {
            self.show()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            let screen = WindowCore.screenUnderMouse() ?? NSScreen.main
            if let screen {
                panel.setFrame(screen.frame, display: true)
            }
            if self.highlightVM.isShown {
                panel.orderFrontRegardless()
            }
        }
    }
    
    func setupPanel() {
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
        panel.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        panel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        panel.collectionBehavior = [
            .moveToActiveSpace,
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
    
    func show() {
        if panel == nil { setupPanel() }
        highlightVM.isShown = true
        panel.orderFrontRegardless()
        print("Is Showing Highlight")
    }
    
    public func hide() {
        panel?.orderOut(nil)
        highlightVM.isShown = false
        print("is Hiding Highlight")
    }
}

struct HighlightView: View {
    
    @Bindable var highlightVM: HighlightFocusedViewModel
    
    var frame: CGRect {
        highlightVM.currentFocused?.element.frame ?? .zero
    }
    
    var body: some View {
        VStack {
            Text("This is Focused")
        }
        .frame(width: frame.width, height: frame.height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(0.5)
    }
}


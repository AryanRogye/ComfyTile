//
//  MenuBarCoordinator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Cocoa
import SwiftUI

@MainActor
class MenuBarCoordinator: NSObject {
    
    typealias MenubarView = ComfyTileMenuBarRootView

    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var hostingController: NSHostingController<MenubarView>?

    /// Event monitors for auto-dismiss behavior
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    /// Dependencies
    private var comfyTileMenuBarVM      : ComfyTileMenuBarViewModel?
    private var settingsVM     : SettingsViewModel?
    private var defaultsManager: DefaultsManager?
    private var fetchedWindowManager: FetchedWindowManager?
    private var updateController: UpdateController?

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Start the menu bar coordinator with required dependencies
    public func start(
        comfyTileMenuBarVM      : ComfyTileMenuBarViewModel,
        settingsVM              : SettingsViewModel,
        defaultsManager         : DefaultsManager,
        fetchedWindowManager    : FetchedWindowManager,
        updateController        : UpdateController
    ) {
        self.comfyTileMenuBarVM     = comfyTileMenuBarVM
        self.settingsVM             = settingsVM
        self.defaultsManager        = defaultsManager
        self.fetchedWindowManager   = fetchedWindowManager
        self.updateController       = updateController

        configureClosures()
        configureStatusItem()
        configurePanel()
    }

    private func configureClosures() {
        settingsVM?.openMenuBar = { [weak self] in
            guard let self else { return }
            self.showPanel()
        }
        updateController?.updaterVM.openMenuBar = { [weak self] in
            guard let self else { return }
            self.showPanel()
        }
        updateController?.updaterVM.closeMenuBar = { [weak self] in
            guard let self else { return }
            self.hidePanel()
        }

    }

    // MARK: - Status Item Configuration

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Use the same icon as the SwiftUI MenuBarExtra
        if let image = NSImage(named: "ComfyTileMenuBar") {
            image.isTemplate = true
            button.image = image
        } else {
            // Fallback to a system image
            button.image = NSImage(
                systemSymbolName: "square.grid.2x2", accessibilityDescription: "ComfyTile")
        }

        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(togglePanel(_:))
    }

    // MARK: - Panel Configuration

    private func configurePanel() {
        guard let comfyTileMenuBarVM = comfyTileMenuBarVM,
              let settingsVM = settingsVM,
              let defaultsManager = defaultsManager,
              let fetchedWindowManager = fetchedWindowManager,
              let updateController = updateController
        else {
            return
        }

        // Create the SwiftUI content view
        let contentView = MenubarView(
            settingsVM: settingsVM,
            comfyTileMenuBarVM: comfyTileMenuBarVM,
            defaultsManager: defaultsManager,
            fetchedWindowManager: fetchedWindowManager,
            updateController: updateController
        )

        // Create hosting controller
        hostingController = NSHostingController(rootView: contentView)

        // Create a borderless, floating panel with size from comfyTileMenuBarVM
        let panel = FocusablePanel(
            contentRect: NSRect(x: 0, y: 0, width: comfyTileMenuBarVM.width, height: comfyTileMenuBarVM.height),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: comfyTileMenuBarVM.width, height: comfyTileMenuBarVM.height))
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = true

        if let hostingView = hostingController?.view {
            hostingView.frame = containerView.bounds
            let width: AppKit.NSView.AutoresizingMask = .width
            let height: AppKit.NSView.AutoresizingMask = .height
            hostingView.autoresizingMask = [width, height]
            containerView.addSubview(hostingView)
        }

        panel.contentView = containerView

        self.panel = panel
        self.comfyTileMenuBarVM?.panel = panel
    }

    // MARK: - Panel Toggle

    @objc private func togglePanel(_ sender: Any?) {
        guard let panel = panel else { return }

        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let panel = panel,
            let button = statusItem?.button
        else { return }
        
        comfyTileMenuBarVM?.getLastFocusedWindow()

        // Position the panel below the status item
        let buttonRect =
            button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero

        let panelSize = panel.frame.size
        let panelOrigin = NSPoint(
            x: buttonRect.midX - panelSize.width / 2,
            y: buttonRect.minY - panelSize.height - 4
        )

        // Make sure panel doesn't go off screen
        if let screen = NSScreen.main {
            var adjustedOrigin = panelOrigin

            // Keep within horizontal bounds
            if adjustedOrigin.x < screen.visibleFrame.minX {
                adjustedOrigin.x = screen.visibleFrame.minX + 8
            } else if adjustedOrigin.x + panelSize.width > screen.visibleFrame.maxX {
                adjustedOrigin.x = screen.visibleFrame.maxX - panelSize.width - 8
            }

            panel.setFrameOrigin(adjustedOrigin)
        } else {
            panel.setFrameOrigin(panelOrigin)
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // Add event monitors for auto-dismiss
        addEventMonitors()
    }

    public func hidePanel() {
        panel?.orderOut(nil)
        removeEventMonitors()
    }

    // MARK: - Event Monitors

    private func addEventMonitors() {
        // Global event monitor - clicks outside the app
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown, .rightMouseDown,
        ]) { [weak self] _ in
            guard let self = self, let panel = self.panel else { return }
            let mouseLocation = NSEvent.mouseLocation
            if panel.frame.contains(mouseLocation) {
                return
            }
            if let button = self.statusItem?.button,
               let buttonWindow = button.window
            {
                let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
                if buttonRect.contains(mouseLocation) {
                    return
                }
            }
            self.hidePanel()
        }

        // Local event monitor - Escape key and clicks outside the panel
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .keyDown, .leftMouseDown, .rightMouseDown,
        ]) { [weak self] event in
            guard let self = self, let panel = self.panel else { return event }

            // Escape key to close
            if event.type == .keyDown && event.keyCode == 53 {
                self.hidePanel()
                return nil
            }

            // Click outside the panel (but inside the app)
            if event.type == .leftMouseDown || event.type == .rightMouseDown {

                // Check if click is in the status item button
                if let button = self.statusItem?.button,
                    let buttonWindow = button.window,
                    event.window == buttonWindow
                {
                    // Let the toggle handle it
                    return event
                }

                // Check if click is in the panel itself
                if event.window == panel {
                    return event
                }

                // Check if click is in a popover or child window (e.g., SwiftUI popover)
                // SwiftUI popovers create separate windows with a higher level
                if let clickedWindow = event.window {
                    // Allow clicks in any window that appears to be a popover/child
                    // Popovers have level >= panel level and are typically NSPanel subclasses
                    if clickedWindow.level >= panel.level {
                        return event
                    }

                    // Also check if it's a child window of the panel
                    if panel.childWindows?.contains(clickedWindow) == true {
                        return event
                    }
                }

                // Click is outside all related windows - dismiss
                self.hidePanel()
            }

            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}

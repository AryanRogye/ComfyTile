//
//  WindowCore.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import Foundation
import ScreenCaptureKit

@Observable
@MainActor
public final class WindowCore {
    
    public var windows: [ComfyWindow] = []
    
    /**
     We cache WindowElements when the window is in the active Space
     because they behave more reliably.
     
     AXUIElements can act differently depending on when/how they’re grabbed.
     Reusing a previously cached one keeps window interactions stable.
     */
    private var elementCache: [CGWindowID: WindowElement] = [:]
    
    var bootTask : Task<Void, Never>?
    var pollingWindowDragging : Task<Void, Never>?
    private var unAsyncLoadWindowTask: Task<Void, Never>?
    var loadWindowTask: Task<[ComfyWindow], Never>?
    var focusedWindowTask: Task<ComfyWindow, Never>?
    
    var highlightFocusedWindow: Bool = false
    var superFocusWindow: Bool = false
    
    @ObservationIgnored static let ignore_list = [
        "com.aryanrogye.ComfyTile"
    ]
    
    @ObservationIgnored
    public var windowSubscriptions: [pid_t: AXSubscription] = [:]

    var onNewFrame: ((ComfyWindow?, [HighlightConfiguration], Bool) -> Void)?
    var fullScreenDetection: ((Bool) -> Void)?

    public init() {
        bootTask = Task { [weak self] in
            guard let self else { return }
            await self.loadWindows()
            observeFocusedWindow()
        }
    }
    
    internal func observeFocusedWindow() {
        withObservationTracking {
            _ = highlightFocusedWindow;
            _ = superFocusWindow
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                let isHighlightFocusWindow = self.highlightFocusedWindow
                let isSuperFocusWindow = self.superFocusWindow
                
                if !isHighlightFocusWindow && !isSuperFocusWindow {
                    clearSubscriptions()
                }
                /// Else falls through if at least 1 is true
                else {
                    attachSubscriptionsOnAllWindows()
                }

                emitCurrentFocusedState()
                
                self.observeFocusedWindow()
            }
        }
    }

    private func currentHighlightConfig() -> [HighlightConfiguration] {
        var config: [HighlightConfiguration] = []
        if highlightFocusedWindow {
            config.append(.border)
        }
        if superFocusWindow {
            config.append(.superFocus)
        }
        return config
    }
    
    private func isFullScreen(on window: ComfyWindow?) -> Bool {
        if let element = window?.element.element {
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(element,
                                          kAXFullscreenAttribute as CFString,
                                          &value)
            if let bool = value as? Bool {
                return bool
            }
        }
        return false
    }

    private func emitCurrentFocusedState() {
        let config = currentHighlightConfig()
        guard !config.isEmpty else {
            onNewFrame?(nil, [], false)
            return
        }
        let win = getFocusedWindow()
        onNewFrame?(win, config, isFullScreen(on: win))
    }
    
    // MARK: - Helpers
    
    /// Global Helper
    public static func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first {
            NSMouseInRect(loc, $0.frame, false)
        }
    }
    
    @MainActor
    internal func refreshAndGetWindows() async -> [ComfyWindow] {
        await loadWindows()
    }
}

// MARK: - AXSubscriptions
extension WindowCore {
    private func assignHandler(subscription: AXSubscription) {
        subscription.setHandlerIfNeeded { [weak self] pid, _, notif in
            guard let self else { return }
            
            guard let win = self.activeWindowElement(for: pid) else { return }
            var comfyWindow = getFocusedWindow()
            
            /// if the focusedWindow != what the notification was
            if let id = win.cgWindowID, id != comfyWindow?.windowID {
                    /// We Can use windows api to get something stronger
                    /// Window state may already be cached/synchronized elsewhere.
                    /// lol funny ass bug, if we have { $0.windowID == win.cgWindowID } and its both nil, itll fall through
                if let win = windows.first(where: { $0.windowID == id }) {
                    comfyWindow = win
                }
            }
            
            guard let comfyWindow else {
                print("Couldnt Find Valid ComfyWindow"); return
            }
            
            onNewFrame?(comfyWindow, currentHighlightConfig(), isFullScreen(on: comfyWindow))
            
//            print("\(comfyWindow.windowTitle) [\(comfyWindow.app.localizedName, default: "[NIL]")]")
//            if notif as String == kAXFocusedUIElementChangedNotification as String {
//                print("Element Changed | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            if notif as String == kAXFocusedWindowChangedNotification as String {
//                print("Focused window Changed | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            if notif as String == kAXApplicationActivatedNotification as String {
//                print("Application Activated | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            if notif as String == kAXWindowMovedNotification as String {
//                print("Window Moved | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            if notif as String == kAXWindowResizedNotification as String {
//                print("Window Resized | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            if notif as String == kAXMovedNotification as String {
//                print("Window Moved | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            if notif as String == kAXResizedNotification as String {
//                print("Window Resized | id:", win.cgWindowID ?? "Unkown ID")
//            }
//            print("====================END==================")
        }
    }
    
    private func attachAppWatcher(subscription: AXSubscription?, pid: pid_t) {
        guard let sub = subscription else { return }
        
        // set onChange ONCE per subscription
        sub.watchApp()
    }
    
    private func attachWindowWatcher(subscription: AXSubscription?, windowEl: AXUIElement?, windowID: CGWindowID?) {
        guard let sub = subscription, let windowEl, let windowID else { return }
        sub.watchWindow(windowEl, windowID: windowID)
    }
    
    /// Main API For
    internal func attachSubscriptionIfNeeded(pid: pid_t, windowEl: AXUIElement?, windowID: CGWindowID?) {
        guard highlightFocusedWindow || superFocusWindow else { return }
        /// if we come in as a "false" on usedAppElement we can test to see if a true one exists
        if self.windowSubscriptions[pid] == nil {
            /// if we dont have a subscription stored
            /// if we can make a valid subscription
            if let sub = AXSubscription(pid: pid) {
                /// add it in
                self.windowSubscriptions[pid] = sub
            }
        }
        
        if let sub = self.windowSubscriptions[pid] {
            self.attachAppWatcher(subscription: sub, pid: pid)
            self.attachWindowWatcher(subscription: sub, windowEl: windowEl, windowID: windowID)
            self.assignHandler(subscription: sub)
        }
    }
    
    internal func clearSubscriptions() {
        self.windowSubscriptions.removeAll()
    }
    internal func attachSubscriptionsOnAllWindows() {
        for cw in windows {
            if self.windowSubscriptions[cw.pid] == nil {
                self.attachSubscriptionIfNeeded(
                    pid: cw.pid,
                    windowEl: cw.element.element,
                    windowID: cw.windowID
                )
            }
        }
    }
}


// MARK: - Main Loading Of Windows
extension WindowCore {
    
    public func unAsyncLoadWindows() {
        unAsyncLoadWindowTask?.cancel()
        unAsyncLoadWindowTask = Task {
            await loadWindows()
        }
    }
    
    @discardableResult
    public func loadWindows() async -> [ComfyWindow] {
        var allWindows: [SCWindow]
        
        /// Use ScreenRecordingKit to get all windows the user owns
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
            allWindows = content.windows
        } catch {
            print("There Was an Error Getting the Windows With SCShareableContent: \(error)")
            return []
        }
        
        /// return [] on no windows found
        if allWindows.isEmpty {
            print("No Windows Found")
            return []
        }
        
        let cscWindows: [ComfySCWindow] = ComfySCWindow.toComfySCWindows(allWindows)
        
        loadWindowTask = Task.detached(priority: .userInitiated) { [weak self, cscWindows] in
            guard let self else { return [] }
            var userWindows: [ComfyWindow] = []
            for w in cscWindows {
                /// Create a ComfyWindow Object
                if let cw = await ComfyWindow(window: w) {
                    
                    await MainActor.run {
                        if let windowID = cw.windowID {
                            /// if the element in ComfyWindow is a valid AXUIElement?, we can update cache
                            if cw.element.element != nil {
                                self.elementCache[windowID] = cw.element
                            }
                            /// if AXUIElement is nil, we can check our cache and update
                            else if let element = self.elementCache[windowID] {
                                cw.setElement(element)
                            }
                        }
                        
                        self.attachSubscriptionIfNeeded(
                            pid: cw.pid,
                            windowEl: cw.element.element,
                            windowID: cw.windowID
                        )
                    }
                    /// Add Window into userWindows
                    userWindows.append(cw)
                    
                }
            }
            /// Return of the task
            return userWindows
        }
        
        
        if let loadWindowTask = loadWindowTask {
            let userWindows = await loadWindowTask.value
            if userWindows.isEmpty { return [] }
            
            // fast lookup of the newest snapshot by windowID
            let newByID = Dictionary(uniqueKeysWithValues: userWindows.map { ($0.windowID, $0) })
            
            var merged: [ComfyWindow] = []
            merged.reserveCapacity(userWindows.count)
            
            // 1) preserve previous order (self.windows), refreshing data when present
            var seen = Set<String>()
            seen.reserveCapacity(userWindows.count)
            
            for old in self.windows {
                if let updated = newByID[old.windowID] {
                    merged.append(updated)
                    seen.insert(old.id)
                }
            }
            
            // 2) append any brand-new windows (order = snapshot order for new ones)
            for w in userWindows where !seen.contains(w.id) {
                merged.append(w)
                seen.insert(w.id)
            }
            
            self.windows = merged
            return merged
        } else {
            return []
        }
    }
}

// MARK: - Main Focus Window
extension WindowCore {
    
    internal func activeWindowElement(for pid: pid_t) -> WindowElement? {
        let appEl = AXUIElementCreateApplication(pid)
        var focused: CFTypeRef?
        let r = AXUIElementCopyAttributeValue(appEl, kAXFocusedWindowAttribute as CFString, &focused)
        guard r == .success, let focused else { return nil }
        // Ensure the returned CFType is actually an AXUIElement before casting
        guard CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        let element = focused as! AXUIElement
        
        return WindowElement(element: element)
    }

    
    /// This is used for Tiling + Layouts
    ///
    /// Layouts, use focusing on the WindowElement then call Focus

    public func getFocusedWindow() -> ComfyWindow? {
        // If we can't get the screen under the mouse, stop.
        guard let screen = Self.screenUnderMouse() else {
            print("❌ Failed to determine screen under mouse")
            return nil
        }
        
        // Get the frontmost app.
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        guard let bundle = app.bundleIdentifier else { return nil }
        let pid = app.processIdentifier
        
        if Self.ignore_list.contains(bundle) { return nil }
        
        let appElement = AXUIElementCreateApplication(pid)
        
        // Ask Accessibility for the app's focused window.
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        // If that fails, stop.
        if result != .success {
            print("❌ Failed to get focused window: \(result)")
            return nil
        }
        let windowElement = focusedWindow as! AXUIElement
        let element : WindowElement = WindowElement(element: windowElement)

        self.attachSubscriptionIfNeeded(
            pid: app.processIdentifier,
            windowEl: element.element,
            windowID: element.cgWindowID
        )
        
        return ComfyWindow(
            app: app,
            windowID: element.cgWindowID,
            windowTitle: element.title ?? "Unamed",
            element: element,
            screen: screen,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            /// Most Likely Focused will always be in space
            isInSpace: true
        )
    }
}

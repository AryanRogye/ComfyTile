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
    let clickMonitor = GlobalClickMonitor()
    
    public var isHoldingModifier: Bool = false
    
    private var elementCache: [CGWindowID: WindowElement] = [:]
    
    var bootTask : Task<Void, Never>?
    var pollingWindowDragging : Task<Void, Never>?
    var loadWindowTask: Task<[ComfyWindow], Never>?
    
    @ObservationIgnored static let ignore_list = [
        "com.aryanrogye.ComfyTile"
    ]
    

    public init() {
        bootTask = Task { [weak self] in
            guard let self else { return }
            await self.loadWindows()
            self.observeModifierChange()
        }
    }
    
    // MARK: - Helpers
    
    /// Global Helper
    public static func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first {
            NSMouseInRect(loc, $0.frame, false)
        }
    }
}

// MARK: - Drag Layouts
extension WindowCore {
    
    /// ObserveModifer Change
    /// This is used if `defaultsManager.modiferKey` is either
    /// .control or .option - ``AppCoordinator``
    private func observeModifierChange() {
        withObservationTracking {
            _ = isHoldingModifier
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if isHoldingModifier {
                    print("Started Pollng")
                    /// We Want to check for a click
//                    clickMonitor.start {
                        self.pollAllWindowsOnScreen()
//                    }
                } else {
                    print("Stopped Polling")
                    pollingWindowDragging?.cancel()
//                    clickMonitor.stop()
                }
                self.observeModifierChange()
            }
        }
    }
    
    private func pollAllWindowsOnScreen() {
        guard let screen = Self.screenUnderMouse() else { return }
        
        pollingWindowDragging?.cancel()
        pollingWindowDragging = Task { @MainActor [weak self] in
            guard let self else { return }
            
            let wins: [ComfyWindow] = await refreshAndGetWindows()
            
            /// This is all the windows in the current space
            let inSpace = wins.filter(\.isInSpace)
            
            /// Storage for positions
            var positions: [CGWindowID: CGRect] = [:]
            var elements: [CGWindowID: WindowElement] = [:]
            
            /// Fill Positions with default positions
            for window in inSpace {
                if let windowID = window.windowID {
                    /// this is default position
                    positions[windowID] = window.element.frame
                    
                    /// this is the window element so we can poll the element for frame again
                    elements[windowID] = window.element
                }
            }
            if positions.isEmpty { return }
            
            let screenFrame : CGRect = screen.visibleFrame
            print("Started Polling With: \(positions.count) Windows On Screen")
            
            var startedTask = false
            while !Task.isCancelled {
                if !startedTask {
                    print("Started Task")
                    startedTask = true
                }
                for (id, frame) in positions {
                    guard let element = elements[id] else { continue }
                    
                    let newFrame: CGRect = element.frame
                    
                    if newFrame != frame {
                        print("\(Date()): \(element.title ?? "Unkown") Frame Adjusted From: \(frame) to \(newFrame)")
                        
                        /// set old frame to be this new one, so it doesnt spam, that we kept changing
                        positions[id] = newFrame
                        
                        /// We can check other frames on the screen if their positions intersect with our newFrame
                        
                    }
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    @MainActor
    internal func refreshAndGetWindows() async -> [ComfyWindow] {
        await loadWindows()
    }
}


// MARK: - Main Loading Of Windows
extension WindowCore {
    
    /// Load Windows is used for Layouts + Window Switcher
    
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
                    }
                    /// Add Window into userWindows
                    userWindows.append(cw)
                    
                }
            }
            
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
        let element = WindowElement(element: windowElement)
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

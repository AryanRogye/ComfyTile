//
//  WindowCore.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

import Foundation
import CoreGraphics
import ScreenCaptureKit

@Observable
@MainActor
public final class WindowCore {
    
    public var windows: [ComfyWindow] = []
    let clickMonitor = GlobalClickMonitor()
    
    public var isHoldingModifier: Bool = false
    
    private var elementCache: [CGWindowID: WindowElement] = [:]
    private var onLayoutWindowsChanged: (([ComfyWindow]) -> Void)?
    private var trackedWindowFramesByID: [CGWindowID: CGRect] = [:]
    private var trackedWindowsByID: [CGWindowID: ComfyWindow] = [:]
    private let frameChangeTolerance: CGFloat = 0.5
    private let dragPollingIntervalNs: UInt64 = 60_000_000
    
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
    
    public func startPollingForDragsInCurrentLayout(onLayoutChanged: (([ComfyWindow]) -> Void)? = nil) {
        onLayoutWindowsChanged = onLayoutChanged
        pollingWindowDragging?.cancel()
        pollingWindowDragging = nil
        clickMonitor.stop()
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            let windows = await self.refreshAndGetWindows()
            let currentWindowsByID = self.currentSpaceWindowsByID(from: windows)
            let currentFrames = self.currentSpaceFramesByID(from: currentWindowsByID)
            
            self.trackedWindowsByID = currentWindowsByID
            self.trackedWindowFramesByID = currentFrames
            self.emitTrackedLayoutWindows()
            
            self.clickMonitor.start { [weak self] in
                Task { @MainActor [weak self] in
                    self?.startDragPollingLoopIfNeeded()
                }
            }
            
            if self.isLeftMousePressed() {
                self.startDragPollingLoopIfNeeded()
            }
        }
    }
    
    public func stopPollingForDragInCurrentLayout() {
        pollingWindowDragging?.cancel()
        pollingWindowDragging = nil
        clickMonitor.stop()
        trackedWindowsByID.removeAll()
        trackedWindowFramesByID.removeAll()
        onLayoutWindowsChanged = nil
    }
    
    /// ObserveModifer Change
    /// This is used if `defaultsManager.modiferKey` is either
    /// .control or .option - ``AppCoordinator``
    private func observeModifierChange() {
        /// Dont do anything here for now, this is unfinished
//        withObservationTracking {
//            _ = isHoldingModifier
//        } onChange: {
//            DispatchQueue.main.async { [weak self] in
//                guard let self else { return }
//                if isHoldingModifier {
//                    print("Started Pollng")
//                    /// We Want to check for a click
////                    clickMonitor.start {
//                        self.pollAllWindowsOnScreen()
////                    }
//                } else {
//                    print("Stopped Polling")
//                    pollingWindowDragging?.cancel()
////                    clickMonitor.stop()
//                }
//                self.observeModifierChange()
//            }
//        }
    }

    private func startDragPollingLoopIfNeeded() {
        if let pollingWindowDragging, !pollingWindowDragging.isCancelled {
            return
        }
        
        pollingWindowDragging = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.reloadTrackedWindowsForCurrentSpace()
            
            while !Task.isCancelled {
                let isDragging = self.clickMonitor.mouseDown || self.isLeftMousePressed()
                if !isDragging {
                    break
                }
                
                let trackedState = self.readTrackedWindowState()
                let latestWindowsByID = trackedState.windowsByID
                let latestFrames = trackedState.framesByID
                
                if self.didFramesChange(
                    from: self.trackedWindowFramesByID,
                    to: latestFrames
                ) {
                    self.trackedWindowsByID = latestWindowsByID
                    self.trackedWindowFramesByID = latestFrames
                    self.emitTrackedLayoutWindows()
                }
                
                try? await Task.sleep(nanoseconds: self.dragPollingIntervalNs)
            }
            
            self.pollingWindowDragging = nil
        }
    }
    
    private func isLeftMousePressed() -> Bool {
        CGEventSource.buttonState(.combinedSessionState, button: .left)
    }
    
    private func reloadTrackedWindowsForCurrentSpace() async {
        let windows = await self.refreshAndGetWindows()
        let windowsByID = self.currentSpaceWindowsByID(from: windows)
        guard !windowsByID.isEmpty else { return }
        
        trackedWindowsByID = windowsByID
        trackedWindowFramesByID = currentSpaceFramesByID(from: windowsByID)
        emitTrackedLayoutWindows()
    }
    
    private func currentSpaceWindowsByID(from windows: [ComfyWindow]) -> [CGWindowID: ComfyWindow] {
        var windowsByID: [CGWindowID: ComfyWindow] = [:]
        
        for window in windows {
            guard let windowID = window.windowID else { continue }
            windowsByID[windowID] = window
        }
        
        return windowsByID
    }
    
    private func currentSpaceFramesByID(from windowsByID: [CGWindowID: ComfyWindow]) -> [CGWindowID: CGRect] {
        var framesByID: [CGWindowID: CGRect] = [:]
        
        for (windowID, window) in windowsByID {
            guard let frame = window.element.windowFrame else { continue }
            guard frame.width > 0, frame.height > 0 else { continue }
            framesByID[windowID] = frame.standardized
        }
        
        return framesByID
    }
    
    private func readTrackedWindowState() -> (
        windowsByID: [CGWindowID: ComfyWindow],
        framesByID: [CGWindowID: CGRect]
    ) {
        var windowsByID: [CGWindowID: ComfyWindow] = [:]
        var framesByID: [CGWindowID: CGRect] = [:]
        
        for (windowID, window) in trackedWindowsByID {
            guard let frame = window.element.windowFrame else { continue }
            guard frame.width > 0, frame.height > 0 else { continue }
            
            windowsByID[windowID] = window
            framesByID[windowID] = frame.standardized
        }
        
        return (windowsByID, framesByID)
    }
    
    private func emitTrackedLayoutWindows() {
        let windows = trackedWindowsByID
            .values
            .sorted {
                guard let lhs = $0.windowID, let rhs = $1.windowID else {
                    return $0.id < $1.id
                }
                return lhs < rhs
            }
        onLayoutWindowsChanged?(windows)
    }
    
    private func didFramesChange(
        from previous: [CGWindowID: CGRect],
        to latest: [CGWindowID: CGRect]
    ) -> Bool {
        if previous.count != latest.count {
            return true
        }
        
        for (windowID, previousFrame) in previous {
            guard let latestFrame = latest[windowID] else {
                return true
            }
            
            if !framesEqual(previousFrame, latestFrame) {
                return true
            }
        }
        
        return false
    }
    
    private func framesEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) <= frameChangeTolerance &&
            abs(lhs.origin.y - rhs.origin.y) <= frameChangeTolerance &&
            abs(lhs.width - rhs.width) <= frameChangeTolerance &&
            abs(lhs.height - rhs.height) <= frameChangeTolerance
    }
    
//    private func pollAllWindowsOnScreen() {
//        guard let screen = Self.screenUnderMouse() else { return }
//        
//        pollingWindowDragging?.cancel()
//        pollingWindowDragging = Task { @MainActor [weak self] in
//            guard let self else { return }
//            
//            let wins: [ComfyWindow] = await refreshAndGetWindows()
//            
//            /// This is all the windows in the current space
//            let inSpace = wins.filter(\.isInSpace)
//            
//            /// Storage for positions
//            var positions: [CGWindowID: CGRect] = [:]
//            var elements: [CGWindowID: WindowElement] = [:]
//            
//            /// Fill Positions with default positions
//            for window in inSpace {
//                if let windowID = window.windowID {
//                    /// this is default position
//                    positions[windowID] = window.element.frame
//                    
//                    /// this is the window element so we can poll the element for frame again
//                    elements[windowID] = window.element
//                }
//            }
//            if positions.isEmpty { return }
//            
//            let screenFrame : CGRect = screen.visibleFrame
//            print("Started Polling With: \(positions.count) Windows On Screen")
//            
//            var startedTask = false
//            while !Task.isCancelled {
//                if !startedTask {
//                    print("Started Task")
//                    startedTask = true
//                }
//                for (id, frame) in positions {
//                    guard let element = elements[id] else { continue }
//                    
//                    let newFrame: CGRect = element.frame
//                    
//                    if newFrame != frame {
//                        print("\(Date()): \(element.title ?? "Unkown") Frame Adjusted From: \(frame) to \(newFrame)")
//                        
//                        /// set old frame to be this new one, so it doesnt spam, that we kept changing
//                        positions[id] = newFrame
//                        
//                        /// We can check other frames on the screen if their positions intersect with our newFrame
//                        
//                    }
//                }
//                
//                try? await Task.sleep(nanoseconds: 500_000_000)
//            }
//        }
//    }
    
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

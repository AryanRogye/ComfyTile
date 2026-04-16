//
//  WindowViewerViewModel.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/16/26.
//

import Foundation

@Observable
@MainActor
class WindowViewerViewModel {
    var isShown = false
    
    var onEscape: (() -> Void) = { }
    
    var selected: Int = 1
    
    public var windows: [ComfyWindow] = []
    
    @ObservationIgnored
    private var allWindows: [ComfyWindow] = []

    @ObservationIgnored
    private var focusedAppPID: pid_t?

    public var isFocusedActive: Bool {
        focusedAppPID != nil
    }

    public var selectedWindow: ComfyWindow? {
        guard windows.indices.contains(selected) else { return nil }
        return windows[selected]
    }

    public func beginCycle(with windows: [ComfyWindow]) {
        allWindows = windows
        focusedAppPID = nil
        self.windows = windows
        selected = initialSelectedIndex(for: windows)
    }

    public func refreshWindows(_ windows: [ComfyWindow]) {
        let selectedWindowID = selectedWindow?.id
        allWindows = windows
        applyCurrentFilter(preferredSelectedWindowID: selectedWindowID)
    }

    public func selectNext() {
        guard !windows.isEmpty else { return }
        selected = (selected + 1) % windows.count
    }

    public func selectPrevious() {
        guard !windows.isEmpty else { return }
        selected = (selected - 1 + windows.count) % windows.count
    }

    public func removeWindow(withID windowID: String) {
        allWindows.removeAll(where: { $0.id == windowID })
        windows.removeAll(where: { $0.id == windowID })

        if let focusedAppPID, !allWindows.contains(where: { $0.pid == focusedAppPID }) {
            self.focusedAppPID = nil
            windows = allWindows
        }

        clampSelection()
    }

    public func toggleFocusedAppFilter() {
        guard let selectedWindow else { return }

        if isFocusedActive {
            focusedAppPID = nil
        } else {
            focusedAppPID = selectedWindow.pid
        }

        applyCurrentFilter(preferredSelectedWindowID: selectedWindow.id)
    }
    
    public func reset() {
        focusedAppPID = nil
        windows = allWindows
        selected = initialSelectedIndex(for: windows)
    }

    private func applyCurrentFilter(preferredSelectedWindowID: String? = nil) {
        if let focusedAppPID,
           allWindows.contains(where: { $0.pid == focusedAppPID }) {
            var filtered = allWindows.filter { window in
                let isPreferredWindow = preferredSelectedWindowID.map { window.id == $0 } ?? false

                return window.pid == focusedAppPID
                    && (isPreferredWindow || window.screenshot != nil)
            }

            if filtered.isEmpty {
                filtered = allWindows.filter { $0.pid == focusedAppPID }
            }

            if let preferredSelectedWindowID,
               let preferredIndex = filtered.firstIndex(where: { $0.id == preferredSelectedWindowID }) {
                let selectedWindow = filtered.remove(at: preferredIndex)
                filtered.insert(selectedWindow, at: 0)
            }

            windows = filtered
        } else {
            focusedAppPID = nil
            windows = allWindows
        }

        clampSelection(preferredSelectedWindowID: preferredSelectedWindowID)
    }

    private func clampSelection(preferredSelectedWindowID: String? = nil) {
        guard !windows.isEmpty else {
            selected = 0
            return
        }

        if let preferredSelectedWindowID,
           let preferredIndex = windows.firstIndex(where: { $0.id == preferredSelectedWindowID }) {
            selected = preferredIndex
            return
        }

        selected = min(selected, windows.count - 1)
    }

    private func initialSelectedIndex(for windows: [ComfyWindow]) -> Int {
        windows.count > 1 ? 1 : 0
    }
}

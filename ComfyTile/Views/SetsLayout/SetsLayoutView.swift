//
//  SetsLayoutView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 2/14/26.
//

import SwiftUI
import AppKit

struct SetsLayoutView: View {
    
    @Environment(ComfyTileMenuBarViewModel.self) var vm
    @State private var outlineCoordinator = SetsLayoutOutlineCoordinator()
    @State private var isPolling = false
    @State private var showStartPrompt = false
    @State private var isApplyingLayout = false
    @State private var previewHideTask: Task<Void, Never>?
    @State private var previousFramesByWindowID: [CGWindowID: CGRect] = [:]
    @State private var showDebugOverlayDuringPolling = true
    @State private var lockedDraggedWindowID: CGWindowID?
    
    private let minGapDimension: CGFloat = 20
    private let minGapArea: CGFloat = 2_000
    private let previewDurationNs: UInt64 = 1_000_000_000
    private let applyTolerance: CGFloat = 1
    private let dragMovementThreshold: CGFloat = 1.5
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if isPolling {
                    Button {
                        stopPolling()
                    } label: {
                        Text("Stop Polling")
                    }
                    
                    Toggle("Show Debug Overlay", isOn: $showDebugOverlayDuringPolling)
                        .toggleStyle(.switch)
                        .padding(.horizontal)
                } else {
                    Button {
                        showLayoutPreview()
                    } label: {
                        Text("Show Layout Preview")
                    }
                    
                    if showStartPrompt {
                        Text("Are you ready to start polling?")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            startPolling()
                        } label: {
                            Text("Start Polling")
                        }
                    }
                }
            }
            .padding(.top)
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    private func showLayoutPreview() {
        // Hard reset before every preview so Space switches never reuse stale state.
        previewHideTask?.cancel()
        previewHideTask = nil
        outlineCoordinator.hide()
        showStartPrompt = false
        previousFramesByWindowID = [:]
        lockedDraggedWindowID = nil
        
        Task { @MainActor in
            let windows = await vm.windowCore.loadWindows()
            let allSnapshots = makeSnapshots(from: windows)
            let activeScreen = activeScreenForPreview(from: allSnapshots)
            let snapshots = allSnapshots.filter { snapshot in
                guard let activeScreen else { return false }
                return sameScreen(snapshot.screen, activeScreen)
            }
            let plan = buildLayoutPlan(from: snapshots)
            let previewItems = makePreviewOverlayItems(snapshots: snapshots, plan: plan)
            
            guard !previewItems.isEmpty else {
                outlineCoordinator.hide()
                showStartPrompt = false
                return
            }
            
            outlineCoordinator.show(items: previewItems)
            showStartPrompt = true
            
            previewHideTask?.cancel()
            previewHideTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: previewDurationNs)
                guard !Task.isCancelled else { return }
                outlineCoordinator.hide()
            }
        }
    }
    
    private func startPolling() {
        previewHideTask?.cancel()
        previewHideTask = nil
        outlineCoordinator.hide()
        
        isPolling = true
        isApplyingLayout = false
        showStartPrompt = false
        previousFramesByWindowID = [:]
        lockedDraggedWindowID = nil
        
        vm.windowCore.startPollingForDragsInCurrentLayout { windows in
            applyAlignedLayout(on: windows)
        }
    }
    
    private func stopPolling() {
        previewHideTask?.cancel()
        previewHideTask = nil
        vm.windowCore.stopPollingForDragInCurrentLayout()
        isApplyingLayout = false
        outlineCoordinator.hide()
        isPolling = false
        showStartPrompt = false
        previousFramesByWindowID = [:]
        lockedDraggedWindowID = nil
    }
    
    private func applyAlignedLayout(on windows: [ComfyWindow]) {
        guard isPolling else { return }
        guard !isApplyingLayout else { return }
        
        let allSnapshots = makeSnapshots(from: windows)
        guard !allSnapshots.isEmpty else { return }
        
        let currentFramesByWindowID = Dictionary(
            uniqueKeysWithValues: allSnapshots.map { ($0.windowID, $0.appKitFrame) }
        )
        let draggedWindowID = resolvedDraggedWindowID(from: currentFramesByWindowID)
        guard let draggedWindowID else {
            previousFramesByWindowID = currentFramesByWindowID
            return
        }
        
        let activeScreen = activeScreenForApply(
            from: allSnapshots,
            draggedWindowID: draggedWindowID
        )
        let snapshots = allSnapshots.filter { snapshot in
            guard let activeScreen else { return false }
            return sameScreen(snapshot.screen, activeScreen)
        }
        
        let plan = buildLayoutPlan(from: snapshots)
        guard !plan.windowAssignments.isEmpty else {
            previousFramesByWindowID = currentFramesByWindowID
            if !isLeftMousePressed() {
                lockedDraggedWindowID = nil
            }
            return
        }
        
        if showDebugOverlayDuringPolling {
            let debugItems = makeDebugOverlayItems(
                snapshots: snapshots,
                plan: plan,
                draggedWindowID: draggedWindowID
            )
            outlineCoordinator.show(items: debugItems)
        } else {
            outlineCoordinator.hide()
        }
        
        isApplyingLayout = true
        
        for snapshot in snapshots {
            if snapshot.windowID == draggedWindowID {
                continue
            }
            
            guard let assignment = plan.windowAssignments[snapshot.windowID] else {
                continue
            }
            
            if framesApproximatelyEqual(snapshot.appKitFrame, assignment.targetFrame) {
                continue
            }
            
            let rect = NSRect(
                x: assignment.targetFrame.minX,
                y: assignment.targetFrame.minY,
                width: assignment.targetFrame.width,
                height: assignment.targetFrame.height
            )
            let axPosition = rect.axPosition(on: assignment.screen)
            
            snapshot.window.element.setSize(
                width: assignment.targetFrame.width,
                height: assignment.targetFrame.height
            )
            snapshot.window.element.setPosition(x: axPosition.x, y: axPosition.y)
            snapshot.window.element.setSize(
                width: assignment.targetFrame.width,
                height: assignment.targetFrame.height
            )
        }
        
        var nextFramesByWindowID = currentFramesByWindowID
        for snapshot in snapshots where snapshot.windowID != draggedWindowID {
            guard let assignment = plan.windowAssignments[snapshot.windowID] else { continue }
            nextFramesByWindowID[snapshot.windowID] = assignment.targetFrame
        }
        previousFramesByWindowID = nextFramesByWindowID
        
        if !isLeftMousePressed() {
            lockedDraggedWindowID = nil
        }
        
        isApplyingLayout = false
    }
    
    private func activeScreenForPreview(from snapshots: [SetsLayoutWindowSnapshot]) -> NSScreen? {
        if let mouseScreen = WindowCore.screenUnderMouse() {
            return mouseScreen
        }
        
        return snapshots.first?.screen
    }
    
    private func activeScreenForApply(
        from snapshots: [SetsLayoutWindowSnapshot],
        draggedWindowID: CGWindowID?
    ) -> NSScreen? {
        if let draggedWindowID,
           let draggedSnapshot = snapshots.first(where: { $0.windowID == draggedWindowID }) {
            return draggedSnapshot.screen
        }
        
        if let mouseScreen = WindowCore.screenUnderMouse() {
            return mouseScreen
        }
        
        return snapshots.first?.screen
    }
    
    private func sameScreen(_ lhs: NSScreen, _ rhs: NSScreen) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    private func buildLayoutPlan(from snapshots: [SetsLayoutWindowSnapshot]) -> SetsLayoutPlan {
        guard !snapshots.isEmpty else {
            return .init(windowAssignments: [:], gapFrames: [])
        }
        
        let groupedByScreen = Dictionary(grouping: snapshots) { snapshot in
            ObjectIdentifier(snapshot.screen)
        }
        
        var windowAssignments: [CGWindowID: SetsLayoutWindowAssignment] = [:]
        var gapFrames: [CGRect] = []
        
        for groupedSnapshots in groupedByScreen.values {
            guard let screen = groupedSnapshots.first?.screen else { continue }
            
            let clippedWindows = groupedSnapshots.map { snapshot in
                snapshot.appKitFrame.intersection(screen.visibleFrame).standardized
            }
            
            let alignedLayout = BinarySpacePartitioningCalculator.alignedLayout(
                occupiedFrames: clippedWindows,
                in: screen.visibleFrame
            )
            
            let filteredGapFrames = alignedLayout.gapRegions
                .filter { isRenderableFrame($0) }
            gapFrames.append(contentsOf: filteredGapFrames)
            
            for (index, rect) in alignedLayout.ownerRegions {
                guard groupedSnapshots.indices.contains(index) else { continue }
                let snapshot = groupedSnapshots[index]
                windowAssignments[snapshot.windowID] = .init(
                    targetFrame: rect.standardized,
                    screen: screen
                )
            }
        }
        
        return .init(
            windowAssignments: windowAssignments,
            gapFrames: gapFrames
        )
    }
    
    private func makeSnapshots(from windows: [ComfyWindow]) -> [SetsLayoutWindowSnapshot] {
        var snapshots = windows.compactMap { window -> SetsLayoutWindowSnapshot? in
            guard let windowID = window.windowID else { return nil }
            guard ComfyWindow.isWindowInActiveSpace(windowID) else { return nil }
            guard let axFrame = window.element.windowFrame else { return nil }
            
            let appKitFrame = axFrame.appKitFrameFromAX
            guard appKitFrame.width > 0, appKitFrame.height > 0 else { return nil }
            guard let screen = bestScreen(for: appKitFrame) else { return nil }
            
            return SetsLayoutWindowSnapshot(
                window: window,
                windowID: windowID,
                appKitFrame: appKitFrame,
                screen: screen
            )
        }
        
        // Focused-window fallback helps apps that are flaky in tracked snapshots.
        if let focused = vm.windowCore.getFocusedWindow(),
           let focusedID = focused.windowID,
           !snapshots.contains(where: { $0.windowID == focusedID }),
           ComfyWindow.isWindowInActiveSpace(focusedID),
           let focusedFrame = focused.element.windowFrame?.appKitFrameFromAX,
           focusedFrame.width > 0,
           focusedFrame.height > 0,
           let focusedScreen = bestScreen(for: focusedFrame) {
            snapshots.append(
                .init(
                    window: focused,
                    windowID: focusedID,
                    appKitFrame: focusedFrame,
                    screen: focusedScreen
                )
            )
        }
        
        return snapshots
    }
    
    private func bestScreen(for frame: CGRect) -> NSScreen? {
        let candidate = NSScreen.screens.max(by: { lhs, rhs in
            intersectionArea(frame, lhs.visibleFrame) < intersectionArea(frame, rhs.visibleFrame)
        })
        
        guard let candidate else { return nil }
        guard intersectionArea(frame, candidate.visibleFrame) > 1 else { return nil }
        return candidate
    }
    
    private func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        return intersection.width * intersection.height
    }
    
    private func isRenderableFrame(_ rect: CGRect) -> Bool {
        rect.width >= minGapDimension &&
            rect.height >= minGapDimension &&
            rect.width * rect.height >= minGapArea
    }
    
    private func framesApproximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) <= applyTolerance &&
            abs(lhs.origin.y - rhs.origin.y) <= applyTolerance &&
            abs(lhs.width - rhs.width) <= applyTolerance &&
            abs(lhs.height - rhs.height) <= applyTolerance
    }
    
    private func resolvedDraggedWindowID(from currentFrames: [CGWindowID: CGRect]) -> CGWindowID? {
        guard isLeftMousePressed() else {
            lockedDraggedWindowID = nil
            return nil
        }
        
        if let lockedDraggedWindowID,
           currentFrames[lockedDraggedWindowID] != nil {
            return lockedDraggedWindowID
        }
        
        if let movedWindowID = mostMovedWindowID(currentFrames) {
            lockedDraggedWindowID = movedWindowID
            return movedWindowID
        }
        
        if let focusedWindowID = vm.windowCore.getFocusedWindow()?.windowID,
           currentFrames[focusedWindowID] != nil {
            lockedDraggedWindowID = focusedWindowID
            return focusedWindowID
        }
        
        return nil
    }
    
    private func mostMovedWindowID(_ currentFrames: [CGWindowID: CGRect]) -> CGWindowID? {
        var bestID: CGWindowID?
        var bestMovement: CGFloat = 0
        
        for (windowID, current) in currentFrames {
            guard let previous = previousFramesByWindowID[windowID] else { continue }
            
            let movement = hypot(
                current.midX - previous.midX,
                current.midY - previous.midY
            )
            
            if movement > bestMovement {
                bestMovement = movement
                bestID = windowID
            }
        }
        
        if bestMovement >= dragMovementThreshold {
            return bestID
        }
        
        return nil
    }
    
    private func isLeftMousePressed() -> Bool {
        CGEventSource.buttonState(.combinedSessionState, button: .left)
    }
    
    private func makePreviewOverlayItems(
        snapshots: [SetsLayoutWindowSnapshot],
        plan: SetsLayoutPlan
    ) -> [SetsLayoutOutlineItem] {
        var items: [SetsLayoutOutlineItem] = []
        
        for snapshot in snapshots {
            items.append(
                .init(
                    frame: snapshot.appKitFrame,
                    style: .rawWindow,
                    label: "RAW \(snapshot.debugLabel)"
                )
            )
        }
        
        for (windowID, assignment) in plan.windowAssignments {
            guard let snapshot = snapshots.first(where: { $0.windowID == windowID }) else { continue }
            items.append(
                .init(
                    frame: assignment.targetFrame,
                    style: .targetWindow,
                    label: "TGT \(snapshot.debugLabel)"
                )
            )
        }
        
        for gap in plan.gapFrames {
            items.append(.init(frame: gap, style: .gap, label: "GAP"))
        }
        
        return items
    }
    
    private func makeDebugOverlayItems(
        snapshots: [SetsLayoutWindowSnapshot],
        plan: SetsLayoutPlan,
        draggedWindowID: CGWindowID?
    ) -> [SetsLayoutOutlineItem] {
        var items: [SetsLayoutOutlineItem] = []
        
        for snapshot in snapshots {
            let style: SetsLayoutOutlineStyle = snapshot.windowID == draggedWindowID
                ? .dragged
                : .rawWindow
            let prefix = snapshot.windowID == draggedWindowID ? "DRAG" : "RAW"
            items.append(
                .init(
                    frame: snapshot.appKitFrame,
                    style: style,
                    label: "\(prefix) \(snapshot.debugLabel)"
                )
            )
        }
        
        for (windowID, assignment) in plan.windowAssignments {
            guard let snapshot = snapshots.first(where: { $0.windowID == windowID }) else { continue }
            items.append(
                .init(
                    frame: assignment.targetFrame,
                    style: .targetWindow,
                    label: "TGT \(snapshot.debugLabel)"
                )
            )
        }
        
        for gap in plan.gapFrames {
            items.append(.init(frame: gap, style: .gap, label: "GAP"))
        }
        
        return items
    }
}

private struct SetsLayoutPlan {
    let windowAssignments: [CGWindowID: SetsLayoutWindowAssignment]
    let gapFrames: [CGRect]
}

private struct SetsLayoutWindowAssignment {
    let targetFrame: CGRect
    let screen: NSScreen
}

private struct SetsLayoutWindowSnapshot {
    let window: ComfyWindow
    let windowID: CGWindowID
    let appKitFrame: CGRect
    let screen: NSScreen
    
    var debugLabel: String {
        let title = window.windowTitle.isEmpty ? "Untitled" : window.windowTitle
        return "\(windowID) \(title.prefix(24))"
    }
}

@MainActor
private final class SetsLayoutOutlineCoordinator {
    private var outlinePanels: [NSPanel] = []
    
    func show(items: [SetsLayoutOutlineItem]) {
        hide()
        
        let overlayLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        for item in items {
            let panel = NSPanel(
                contentRect: item.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.level = overlayLevel
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
            panel.ignoresMouseEvents = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            
            let host = NSHostingView(rootView: SetsLayoutOutlineFrameView(item: item))
            host.frame = NSRect(origin: .zero, size: item.frame.size)
            host.autoresizingMask = [.width, .height]
            panel.contentView = host
            
            panel.orderFrontRegardless()
            outlinePanels.append(panel)
        }
    }
    
    func hide() {
        for panel in outlinePanels {
            panel.orderOut(nil)
        }
        outlinePanels.removeAll()
    }
}

private struct SetsLayoutOutlineFrameView: View {
    let item: SetsLayoutOutlineItem
    
    private var strokeColor: Color {
        switch item.style {
        case .rawWindow: return .blue.opacity(0.9)
        case .targetWindow: return .green.opacity(0.95)
        case .gap: return .orange.opacity(0.9)
        case .dragged: return .red.opacity(0.95)
        }
    }
    
    private var fillColor: Color {
        switch item.style {
        case .rawWindow: return .blue.opacity(0.05)
        case .targetWindow: return .green.opacity(0.08)
        case .gap: return .orange.opacity(0.04)
        case .dragged: return .red.opacity(0.08)
        }
    }
    
    private var dashPattern: [CGFloat] {
        switch item.style {
        case .gap: return [8, 6]
        case .targetWindow: return [4, 4]
        default: return []
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            strokeColor,
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: dashPattern
                            )
                        )
                }
            
            if let label = item.label {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(6)
            }
        }
        .padding(2)
    }
}

private struct SetsLayoutOutlineItem {
    let frame: CGRect
    let style: SetsLayoutOutlineStyle
    let label: String?
}

private enum SetsLayoutOutlineStyle {
    case rawWindow
    case targetWindow
    case gap
    case dragged
}

private extension CGRect {
    var appKitFrameFromAX: CGRect {
        guard let desktopTopY = NSScreen.screens.map(\.frame.maxY).max() else {
            return self
        }
        
        return CGRect(
            x: origin.x,
            y: desktopTopY - origin.y - height,
            width: width,
            height: height
        )
    }
}

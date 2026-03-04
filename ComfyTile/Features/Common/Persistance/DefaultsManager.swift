//
//  DefaultsManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import Defaults
import Foundation
import SwiftUI

struct NormalizedRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let full = NormalizedRect(x: 0, y: 0, width: 1, height: 1)

    var area: Double {
        width * height
    }

    func clamped(minSize: Double = 0.08) -> NormalizedRect {
        let clampedWidth = min(1, max(minSize, width))
        let clampedHeight = min(1, max(minSize, height))
        let maxX = max(0, 1 - clampedWidth)
        let maxY = max(0, 1 - clampedHeight)

        return NormalizedRect(
            x: min(max(0, x), maxX),
            y: min(max(0, y), maxY),
            width: clampedWidth,
            height: clampedHeight
        )
    }
}

struct WindowLayoutSlot: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var rect: NormalizedRect = .full
    var isManuallyEdited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case rect
        case isManuallyEdited
    }

    init(id: UUID = UUID(), rect: NormalizedRect = .full, isManuallyEdited: Bool = false) {
        self.id = id
        self.rect = rect
        self.isManuallyEdited = isManuallyEdited
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        rect = try container.decodeIfPresent(NormalizedRect.self, forKey: .rect) ?? .full
        isManuallyEdited = try container.decodeIfPresent(Bool.self, forKey: .isManuallyEdited) ?? false
    }
}

struct WindowLayoutDraft: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = "Layout"
    var windows: [WindowLayoutSlot] = []

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case windows
    }

    init(id: UUID = UUID(), name: String = "Layout", windows: [WindowLayoutSlot] = []) {
        self.id = id
        self.name = name
        self.windows = windows
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Layout"
        windows = try container.decodeIfPresent([WindowLayoutSlot].self, forKey: .windows) ?? []
    }
}

private struct WindowLayoutStore: Codable, Equatable {
    var selectedLayoutID: UUID?
    var layouts: [WindowLayoutDraft]

    static let empty = WindowLayoutStore(selectedLayoutID: nil, layouts: [])
}

@Observable @MainActor
class DefaultsManager {
    var nudgeStep: Int = Defaults[.nudgeStep]
    var modiferKey: ModifierGroup = ModifierGroup(rawValue: Defaults[.modiferKey]) ?? .control

    var highlightFocusedWindow: Bool = Defaults[.highlightFocusedWindow] {
        didSet {
            Defaults[.highlightFocusedWindow] = highlightFocusedWindow
        }
    }

    var highlightFocusedWindowColor: Color = Defaults[.highlightFocusedWindowColor] {
        didSet {
            Defaults[.highlightFocusedWindowColor] = highlightFocusedWindowColor
        }
    }

    var highlightedFocusedWindowWidth: Double = Defaults[.highlightedFocusedWindowWidth] {
        didSet {
            Defaults[.highlightedFocusedWindowWidth] = highlightedFocusedWindowWidth
        }
    }

    var superFocusWindow: Bool = Defaults[.superFocusWindow] {
        didSet {
            Defaults[.superFocusWindow] = superFocusWindow
        }
    }

    var superFocusColor: Color = Defaults[.superFocusColor] {
        didSet {
            Defaults[.superFocusColor] = superFocusColor
        }
    }

    var showTilingAnimations: Bool = Defaults[.showTilingAnimations] {
        didSet {
            Defaults[.showTilingAnimations] = showTilingAnimations
        }
    }

    var comfyTileTabPlacement: ComfyTileTabPlacement = Defaults[.comfyTileTabPlacement] {
        didSet {
            Defaults[.comfyTileTabPlacement] = comfyTileTabPlacement
        }
    }

    private(set) var windowLayouts: [WindowLayoutDraft] = []
    private(set) var selectedWindowLayoutID: UUID?

    var selectedWindowLayout: WindowLayoutDraft? {
        guard let selectedWindowLayoutID,
              let index = windowLayouts.firstIndex(where: { $0.id == selectedWindowLayoutID }) else {
            return nil
        }

        return windowLayouts[index]
    }

    var selectedWindowLayoutWindows: [WindowLayoutSlot] {
        selectedWindowLayout?.windows ?? []
    }

    private var windowLayoutStoreSaveWorkItem: DispatchWorkItem?

    init() {
        let store = Self.decodeWindowLayoutStore(from: Defaults[.windowLayoutStoreJSON])

        if !store.layouts.isEmpty {
            windowLayouts = store.layouts
            selectedWindowLayoutID = store.selectedLayoutID
        } else if let legacy = Self.decodeLegacyWindowLayoutDraft(from: Defaults[.windowLayoutDraftJSON]) {
            let migrated = WindowLayoutDraft(
                id: UUID(),
                name: legacy.name.isEmpty ? "Layout 1" : legacy.name,
                windows: legacy.windows
            )
            windowLayouts = [migrated]
            selectedWindowLayoutID = migrated.id
        }

        ensureLayoutSelection()
        scheduleWindowLayoutStoreSave()
    }

    public func saveModiferKey() {
        Defaults[.modiferKey] = modiferKey.rawValue
    }

    public func saveNudgeStep() {
        Defaults[.nudgeStep] = nudgeStep
    }

    func selectWindowLayout(id: UUID) {
        guard windowLayouts.contains(where: { $0.id == id }) else { return }
        selectedWindowLayoutID = id
        scheduleWindowLayoutStoreSave()
    }

    @discardableResult
    func createWindowLayout(named name: String? = nil) -> UUID {
        let nextName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (nextName?.isEmpty == false) ? nextName! : suggestedLayoutName()

        let layout = WindowLayoutDraft(id: UUID(), name: finalName, windows: [])
        windowLayouts.append(layout)
        selectedWindowLayoutID = layout.id
        scheduleWindowLayoutStoreSave()
        return layout.id
    }

    func deleteSelectedWindowLayout() {
        guard let selectedIndex = selectedWindowLayoutIndex else { return }

        windowLayouts.remove(at: selectedIndex)

        if windowLayouts.isEmpty {
            let replacement = WindowLayoutDraft(id: UUID(), name: "Layout 1", windows: [])
            windowLayouts = [replacement]
            selectedWindowLayoutID = replacement.id
        } else {
            let nextIndex = min(selectedIndex, windowLayouts.count - 1)
            selectedWindowLayoutID = windowLayouts[nextIndex].id
        }

        scheduleWindowLayoutStoreSave()
    }

    func renameSelectedWindowLayout(_ name: String) {
        updateSelectedLayout { layout in
            layout.name = name
        }
    }

    func addWindowToSelectedLayout() {
        updateSelectedLayout { layout in
            if layout.windows.isEmpty {
                layout.windows.append(WindowLayoutSlot(rect: .full))
                return
            }

            if let largestIndex = largestAutoSplitCandidateIndex(in: layout.windows) {
                var target = layout.windows[largestIndex]
                let source = target.rect
                let isHorizontalSplit = source.width >= source.height

                let first: NormalizedRect
                let second: NormalizedRect

                if isHorizontalSplit {
                    let splitWidth = source.width / 2
                    first = NormalizedRect(x: source.x, y: source.y, width: splitWidth, height: source.height)
                    second = NormalizedRect(x: source.x + splitWidth, y: source.y, width: splitWidth, height: source.height)
                } else {
                    let splitHeight = source.height / 2
                    first = NormalizedRect(x: source.x, y: source.y, width: source.width, height: splitHeight)
                    second = NormalizedRect(x: source.x, y: source.y + splitHeight, width: source.width, height: splitHeight)
                }

                target.rect = first.clamped()
                target.isManuallyEdited = false
                layout.windows[largestIndex] = target
                layout.windows.append(
                    WindowLayoutSlot(rect: second.clamped(), isManuallyEdited: false)
                )
                return
            }

            // If everything has been manually edited, do not mutate existing windows.
            let freeRect = largestAvailableGap(in: layout.windows)
            let fallbackRect = suggestedOverlayRect(forCount: layout.windows.count)
            let newRect = freeRect ?? fallbackRect
            layout.windows.append(
                WindowLayoutSlot(rect: newRect.clamped(minSize: 0.12), isManuallyEdited: false)
            )
        }
    }

    func removeWindowFromSelectedLayout(id: UUID) {
        updateSelectedLayout { layout in
            layout.windows.removeAll(where: { $0.id == id })
        }
    }

    func updateSelectedLayoutWindowRect(id: UUID, rect: NormalizedRect, isManualEdit: Bool = true) {
        updateSelectedLayout { layout in
            guard let index = layout.windows.firstIndex(where: { $0.id == id }) else { return }
            layout.windows[index].rect = rect.clamped()
            if isManualEdit {
                layout.windows[index].isManuallyEdited = true
            }
        }
    }

    func clearSelectedLayoutWindows() {
        updateSelectedLayout { layout in
            layout.windows.removeAll()
        }
    }

    private var selectedWindowLayoutIndex: Int? {
        guard let selectedWindowLayoutID else { return nil }
        return windowLayouts.firstIndex(where: { $0.id == selectedWindowLayoutID })
    }

    private func updateSelectedLayout(_ update: (inout WindowLayoutDraft) -> Void) {
        ensureLayoutSelection()

        guard let selectedWindowLayoutIndex else { return }
        update(&windowLayouts[selectedWindowLayoutIndex])
        scheduleWindowLayoutStoreSave()
    }

    private func ensureLayoutSelection() {
        if windowLayouts.isEmpty {
            let defaultLayout = WindowLayoutDraft(id: UUID(), name: "Layout 1", windows: [])
            windowLayouts = [defaultLayout]
            selectedWindowLayoutID = defaultLayout.id
            return
        }

        if let selectedWindowLayoutID,
           windowLayouts.contains(where: { $0.id == selectedWindowLayoutID }) {
            return
        }

        selectedWindowLayoutID = windowLayouts.first?.id
    }

    private func suggestedLayoutName() -> String {
        var index = max(windowLayouts.count + 1, 1)
        var candidate = "Layout \(index)"
        let existing = Set(windowLayouts.map { $0.name.lowercased() })

        while existing.contains(candidate.lowercased()) {
            index += 1
            candidate = "Layout \(index)"
        }

        return candidate
    }

    private func scheduleWindowLayoutStoreSave() {
        windowLayoutStoreSaveWorkItem?.cancel()
        let snapshot = WindowLayoutStore(
            selectedLayoutID: selectedWindowLayoutID,
            layouts: windowLayouts
        )

        let workItem = DispatchWorkItem {
            Defaults[.windowLayoutStoreJSON] = Self.encodeWindowLayoutStore(snapshot)
        }
        windowLayoutStoreSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: workItem)
    }

    private func largestAutoSplitCandidateIndex(in windows: [WindowLayoutSlot]) -> Int? {
        let candidates = windows.indices.filter {
            windows[$0].isManuallyEdited == false
        }
        guard !candidates.isEmpty else { return nil }

        return candidates.max { lhs, rhs in
            windows[lhs].rect.area < windows[rhs].rect.area
        }
    }

    private func largestAvailableGap(in windows: [WindowLayoutSlot]) -> NormalizedRect? {
        guard !windows.isEmpty else { return .full }

        let xEdges = uniqueSortedEdges(
            [0, 1] + windows.flatMap { [$0.rect.x, $0.rect.x + $0.rect.width] }
        )
        let yEdges = uniqueSortedEdges(
            [0, 1] + windows.flatMap { [$0.rect.y, $0.rect.y + $0.rect.height] }
        )

        var bestRect: NormalizedRect?
        var bestArea = 0.0
        let minSide = 0.12

        guard xEdges.count > 1, yEdges.count > 1 else { return nil }

        for xi in 0..<(xEdges.count - 1) {
            for yi in 0..<(yEdges.count - 1) {
                let x0 = xEdges[xi]
                let x1 = xEdges[xi + 1]
                let y0 = yEdges[yi]
                let y1 = yEdges[yi + 1]
                let width = x1 - x0
                let height = y1 - y0

                guard width >= minSide, height >= minSide else { continue }

                let centerX = x0 + (width / 2)
                let centerY = y0 + (height / 2)
                let isOccupied = windows.contains(where: { slot in
                    contains(slot.rect, x: centerX, y: centerY)
                })

                if isOccupied { continue }

                let area = width * height
                if area > bestArea {
                    bestArea = area
                    bestRect = NormalizedRect(x: x0, y: y0, width: width, height: height)
                }
            }
        }

        return bestRect
    }

    private func suggestedOverlayRect(forCount count: Int) -> NormalizedRect {
        let offset = Double(count % 6) * 0.04
        return NormalizedRect(
            x: min(0.58, 0.08 + offset),
            y: min(0.58, 0.08 + offset),
            width: 0.34,
            height: 0.34
        )
    }

    private func uniqueSortedEdges(_ values: [Double]) -> [Double] {
        let snapped = values.map { value in
            (value * 10_000).rounded() / 10_000
        }
        return Array(Set(snapped)).sorted()
    }

    private func contains(_ rect: NormalizedRect, x: Double, y: Double) -> Bool {
        x >= rect.x &&
        y >= rect.y &&
        x <= rect.x + rect.width &&
        y <= rect.y + rect.height
    }

    private static func encodeWindowLayoutStore(_ store: WindowLayoutStore) -> String {
        guard let data = try? JSONEncoder().encode(store),
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }

        return value
    }

    private static func decodeWindowLayoutStore(from value: String) -> WindowLayoutStore {
        guard !value.isEmpty,
              let data = value.data(using: .utf8),
              let store = try? JSONDecoder().decode(WindowLayoutStore.self, from: data) else {
            return .empty
        }

        return store
    }

    private static func decodeLegacyWindowLayoutDraft(from value: String) -> WindowLayoutDraft? {
        guard !value.isEmpty,
              let data = value.data(using: .utf8),
              let legacy = try? JSONDecoder().decode(WindowLayoutDraft.self, from: data) else {
            return nil
        }

        return legacy
    }
}

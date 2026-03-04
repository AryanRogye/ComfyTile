//
//  GeneralSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI
import AppKit

struct GeneralSettings: View {

    @Environment(UpdateController.self) var updateController
    @Bindable var defaultsManager: DefaultsManager

    var body: some View {
        Form {
            Section("About") {
                if let updateNotFoundError = updateController.updaterVM.updateNotFoundError,
                   updateController.updaterVM.showUpdateNotFoundError {
                    Text(updateNotFoundError)
                    Button {
                        updateController.updaterVM.updateNotFoundError = nil
                        updateController.updaterVM.showUpdateNotFoundError = false
                        updateController.updaterVM.showUserInitiatedUpdate = false
                    } label: {
                        Text("Ok")
                    }
                } else {
                    if updateController.updaterVM.showUserInitiatedUpdate {
                        HStack {
                            Button {
                                updateController.updaterVM.cancelUserInitiatedUpdate()
                            } label: {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                            }

                            ProgressView()
                                .progressViewStyle(.linear)
                                .frame(maxWidth: .infinity)
                        }

                    } else {
                        CheckForUpdatesView(updater: updateController.updater)
                    }
                }

                Button("Quit") {
                    NSApplication.shared.terminate(self)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: updateController.updaterVM.showUserInitiatedUpdate)
    }
}

struct LayoutBuilderSettings: View {

    @Bindable var defaultsManager: DefaultsManager

    @State private var selectedWindowID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                layoutsCard
                editorCard
                selectedWindowCard
                shortcutCard
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            syncSelectedWindowSelection()
        }
        .onChange(of: defaultsManager.selectedWindowLayoutID) { _, _ in
            syncSelectedWindowSelection()
        }
        .onChange(of: defaultsManager.selectedWindowLayoutWindows) { _, _ in
            syncSelectedWindowSelection()
        }
    }

    private var layoutsCard: some View {
        settingsCard(
            title: "Layouts",
            subtitle: "Create and switch between multiple named layouts."
        ) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(defaultsManager.windowLayouts) { layout in
                        let isSelected = layout.id == defaultsManager.selectedWindowLayoutID

                        Button {
                            defaultsManager.selectWindowLayout(id: layout.id)
                        } label: {
                            Text(layout.name.isEmpty ? "Untitled" : layout.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.18))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }

            HStack(spacing: 10) {
                Button("New Layout") {
                    _ = defaultsManager.createWindowLayout()
                    selectedWindowID = nil
                }

                Button("Delete Layout", role: .destructive) {
                    defaultsManager.deleteSelectedWindowLayout()
                    selectedWindowID = nil
                }
                .disabled(defaultsManager.windowLayouts.count <= 1)
            }

            TextField("Layout name", text: layoutNameBinding)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var editorCard: some View {
        settingsCard(
            title: "Editor",
            subtitle: "Start with 0 windows. Add windows and drag/resize freely."
        ) {
            LayoutCanvasView(
                windows: defaultsManager.selectedWindowLayoutWindows,
                selectedWindowID: $selectedWindowID,
                onUpdate: { id, rect in
                    defaultsManager.updateSelectedLayoutWindowRect(id: id, rect: rect)
                }
            )
            .aspectRatio(layoutCanvasAspectRatio, contentMode: .fit)
            .frame(minHeight: 220, maxHeight: 420)
            .clipped()

            Text("Drag a window to move it. Use the bottom-right handle to resize.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Add Window") {
                    defaultsManager.addWindowToSelectedLayout()
                    selectedWindowID = defaultsManager.selectedWindowLayoutWindows.last?.id
                }

                Button("Remove Selected", role: .destructive) {
                    guard let selectedWindowID else { return }
                    defaultsManager.removeWindowFromSelectedLayout(id: selectedWindowID)
                    self.selectedWindowID = defaultsManager.selectedWindowLayoutWindows.first?.id
                }
                .disabled(selectedWindowID == nil)

                Button("Clear") {
                    defaultsManager.clearSelectedLayoutWindows()
                    selectedWindowID = nil
                }
                .disabled(defaultsManager.selectedWindowLayoutWindows.isEmpty)
            }
        }
    }

    private var selectedWindowCard: some View {
        settingsCard(
            title: "Selected Window",
            subtitle: "Fine tune exact position and size."
        ) {
            if let selectedWindowID,
               let selected = defaultsManager.selectedWindowLayoutWindows.first(where: { $0.id == selectedWindowID }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window \(windowNumber(for: selectedWindowID))")
                        .font(.headline)

                    SliderRow(title: "X", value: rectBinding(for: selected.id, keyPath: \.x), range: 0...100)
                    SliderRow(title: "Y", value: rectBinding(for: selected.id, keyPath: \.y), range: 0...100)
                    SliderRow(title: "Width", value: rectBinding(for: selected.id, keyPath: \.width), range: 8...100)
                    SliderRow(title: "Height", value: rectBinding(for: selected.id, keyPath: \.height), range: 8...100)
                }
            } else {
                Text("Select a window rectangle to edit precise values.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shortcutCard: some View {
        settingsCard(
            title: "Layout Palette Shortcut",
            subtitle: "This hotkey is wired to a stub action for now."
        ) {
            ShortcutRecorder(label: "Open Layout Palette", type: .layoutPalette)
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.7)
        )
    }

    private var layoutNameBinding: Binding<String> {
        Binding(
            get: { defaultsManager.selectedWindowLayout?.name ?? "" },
            set: { defaultsManager.renameSelectedWindowLayout($0) }
        )
    }

    private func rectBinding(for id: UUID, keyPath: WritableKeyPath<NormalizedRect, Double>) -> Binding<Double> {
        Binding(
            get: {
                guard let slot = defaultsManager.selectedWindowLayoutWindows.first(where: { $0.id == id }) else {
                    return 0
                }
                return slot.rect[keyPath: keyPath] * 100
            },
            set: { newValue in
                guard let slot = defaultsManager.selectedWindowLayoutWindows.first(where: { $0.id == id }) else { return }
                var nextRect = slot.rect
                nextRect[keyPath: keyPath] = newValue / 100
                defaultsManager.updateSelectedLayoutWindowRect(id: id, rect: nextRect)
            }
        )
    }

    private func windowNumber(for id: UUID) -> Int {
        guard let idx = defaultsManager.selectedWindowLayoutWindows.firstIndex(where: { $0.id == id }) else {
            return 1
        }
        return idx + 1
    }

    private func syncSelectedWindowSelection() {
        let windows = defaultsManager.selectedWindowLayoutWindows

        if let selectedWindowID,
           windows.contains(where: { $0.id == selectedWindowID }) {
            return
        }

        self.selectedWindowID = windows.first?.id
    }
    
    private var layoutCanvasAspectRatio: CGFloat {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 16, height: 10)
        guard frame.height > 0 else { return 1.6 }
        
        let ratio = frame.width / frame.height
        return min(max(ratio, 0.8), 3.0)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .frame(width: 50, alignment: .leading)
            Slider(value: $value, in: range, step: 0.5)
            Text("\(Int(value.rounded()))%")
                .monospacedDigit()
                .frame(width: 52, alignment: .trailing)
        }
    }
}

private struct LayoutCanvasView: View {
    let windows: [WindowLayoutSlot]
    @Binding var selectedWindowID: UUID?
    let onUpdate: (UUID, NormalizedRect) -> Void
    
    @State private var wallpaperImage: NSImage?
    @State private var wallpaperURL: URL?
    @State private var lastWallpaperLoadSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = proxy.size

            ZStack(alignment: .topLeading) {
                wallpaperBackground(canvasSize: canvasSize)

                if windows.isEmpty {
                    Text("0 windows\nClick Add Window to start")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                ForEach(Array(windows.enumerated()), id: \.element.id) { pair in
                    let index = pair.offset
                    let window = pair.element

                    LayoutWindowRectView(
                        index: index,
                        slot: window,
                        canvasSize: canvasSize,
                        isSelected: selectedWindowID == window.id,
                        onSelect: {
                            selectedWindowID = window.id
                        },
                        onUpdate: { rect in
                            onUpdate(window.id, rect)
                        }
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .onAppear {
                loadWallpaper(for: canvasSize, force: true)
            }
            .onChange(of: canvasSize) { _, newSize in
                loadWallpaper(for: newSize, force: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)) { _ in
            loadWallpaper(for: lastWallpaperLoadSize, force: true)
        }
    }
    
    @ViewBuilder
    private func wallpaperBackground(canvasSize: CGSize) -> some View {
        if let wallpaperImage {
            Image(nsImage: wallpaperImage)
                .resizable()
                .interpolation(.low)
                .scaledToFill()
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.32),
                            Color.black.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                }
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.18, blue: 0.24),
                            Color(red: 0.10, green: 0.12, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: canvasSize.width, height: canvasSize.height)
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: 20, y: 20)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 190, height: 190)
                .offset(x: max(0, canvasSize.width - 220), y: max(0, canvasSize.height - 220))
        }
    }
    
    private func loadWallpaper(for size: CGSize, force: Bool) {
        guard size.width > 2, size.height > 2 else { return }

        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen,
              let url = NSWorkspace.shared.desktopImageURL(for: screen) else {
            wallpaperImage = nil
            wallpaperURL = nil
            lastWallpaperLoadSize = .zero
            return
        }
        
        let sizeDelta = abs(size.width - lastWallpaperLoadSize.width) + abs(size.height - lastWallpaperLoadSize.height)
        let shouldReload = force || wallpaperURL != url || sizeDelta > 40

        guard shouldReload else { return }

        guard let sourceImage = NSImage(contentsOf: url) else {
            wallpaperImage = nil
            wallpaperURL = nil
            lastWallpaperLoadSize = .zero
            return
        }

        wallpaperImage = downsampledWallpaper(sourceImage, targetSize: size)
        wallpaperURL = url
        lastWallpaperLoadSize = size
    }

    private func downsampledWallpaper(_ image: NSImage, targetSize: CGSize) -> NSImage {
        let finalSize = NSSize(
            width: max(targetSize.width, 1),
            height: max(targetSize.height, 1)
        )

        let rendered = NSImage(size: finalSize)
        rendered.lockFocus()
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = .low
        }
        image.draw(
            in: NSRect(origin: .zero, size: finalSize),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        rendered.unlockFocus()
        return rendered
    }
}

private struct LayoutWindowRectView: View {
    let index: Int
    let slot: WindowLayoutSlot
    let canvasSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (NormalizedRect) -> Void

    @State private var dragStartRect: NormalizedRect?
    @State private var resizeStartRect: NormalizedRect?
    @State private var liveRect: NormalizedRect?

    var body: some View {
        let currentRect = liveRect ?? slot.rect
        let rect = frame(for: currentRect)

        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.42) : Color.blue.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
                .gesture(moveGesture)

            Text("W\(index + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            resizeHandle
        }
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.minX, y: rect.minY)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onChange(of: slot.rect) { _, _ in
            if dragStartRect == nil && resizeStartRect == nil {
                liveRect = nil
            }
        }
    }

    private var resizeHandle: some View {
        ZStack {
            Color.clear
                .frame(width: 34, height: 34)

            RoundedRectangle(cornerRadius: 5)
                .fill(.white.opacity(0.95))
                .frame(width: 20, height: 20)
                .overlay {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black.opacity(0.75))
                }
        }
        .padding(2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .highPriorityGesture(resizeGesture)
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                onSelect()

                if dragStartRect == nil {
                    dragStartRect = slot.rect
                }

                guard let start = dragStartRect, canvasSize.width > 0, canvasSize.height > 0 else { return }

                let dx = value.translation.width / canvasSize.width
                let dy = value.translation.height / canvasSize.height

                let next = NormalizedRect(
                    x: start.x + dx,
                    y: start.y + dy,
                    width: start.width,
                    height: start.height
                )

                liveRect = next.clamped()
            }
            .onEnded { _ in
                if let liveRect {
                    onUpdate(liveRect)
                }
                dragStartRect = nil
                liveRect = nil
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0.5)
            .onChanged { value in
                onSelect()

                if resizeStartRect == nil {
                    resizeStartRect = slot.rect
                }

                guard let start = resizeStartRect, canvasSize.width > 0, canvasSize.height > 0 else { return }

                let dx = value.translation.width / canvasSize.width
                let dy = value.translation.height / canvasSize.height

                let next = NormalizedRect(
                    x: start.x,
                    y: start.y,
                    width: start.width + dx,
                    height: start.height + dy
                )

                liveRect = next.clamped()
            }
            .onEnded { _ in
                if let liveRect {
                    onUpdate(liveRect)
                }
                resizeStartRect = nil
                liveRect = nil
            }
    }

    private func frame(for rect: NormalizedRect) -> CGRect {
        CGRect(
            x: rect.x * canvasSize.width,
            y: rect.y * canvasSize.height,
            width: rect.width * canvasSize.width,
            height: rect.height * canvasSize.height
        )
    }
}

//
//  TilingSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//

import SwiftUI
import os.signpost

// MARK: - Center Tiling Settings
struct CenterTilingGeneralView: View {
    @Bindable var defaultsManager : DefaultsManager
    @Bindable var menuBarVM: ComfyTileMenuBarViewModel

    // State to hold the ID so we can access it from a button
    @State private var activeSignpostID: OSSignpostID? = nil
    let log = OSLog.comfyView

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Center Tiling Padding")
                Spacer()
                Text("\(Int(defaultsManager.centerTilingPadding)) px")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .redacted(reason: menuBarVM.showSettings == false ? .placeholder : [])

            /// This allows us to not lag while opening
            if menuBarVM.showSettings {
                Slider(value: $defaultsManager.centerTilingPadding, in: 10...300, step: 1) {
                    EmptyView()
                } minimumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .labelsHidden()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring, value: menuBarVM.showSettings)
    }
}

// MARK: - Center Tiling Advanced General View
struct CenterTilingAdvancedGeneralView: View {
    @Bindable var defaultsManager : DefaultsManager
    @Bindable var menuBarVM: ComfyTileMenuBarViewModel
    @Environment(DisplayManager.self) var displayManager

    @AppStorage("HideAdvancedCenterTilingPadding") var hideAdvancedCenterTilingPadding: Bool = false

    var spacing   : CGFloat { 12 }
    var cardWidth : CGFloat { 160 }

    var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    var body: some View {
        /// Advanced Center Padding Toggle
        LazyVStack(alignment: .leading) {
            if menuBarVM.showSettings {
                Toggle("Advanced Center Padding", isOn: $defaultsManager.advancedCenterTilingPadding)
                    .help("If enabled, and a monitor doesnt have padding, will default to center padding")
            }
            if defaultsManager.advancedCenterTilingPadding && menuBarVM.showSettings {

                Button(action: {
                    hideAdvancedCenterTilingPadding.toggle()
                }) {
                    Text(hideAdvancedCenterTilingPadding ? "Show" :"Hide")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if !hideAdvancedCenterTilingPadding {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(displayManager.screenSnapshots.keys), id: \.self) { key in
                            if let image = displayManager.snapshot(for: key) {
                                DisplayCard(
                                    key: key,
                                    image: image,
                                    displayManager: displayManager
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring, value: menuBarVM.showSettings)
        .animation(.spring, value: defaultsManager.advancedCenterTilingPadding)
        .animation(.spring, value: hideAdvancedCenterTilingPadding)
    }
}

// MARK: - Display Card
struct DisplayCard: View {
    let key: CGDirectDisplayID
    let image: NSImage
    @Bindable var displayManager: DisplayManager

    var info: DisplayInfo? {
        displayManager.displayInfos.first(where: { $0.screenID == key })
    }

    var padding: Double {
        info?.padding ?? 0
    }

    var isEnabled: Bool {
        displayManager.isPaddingEnabled(for: key)
    }

    var paddingAround: CGFloat {
        10
    }

    var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            wallpaper

            VStack(alignment: .leading, spacing: 12) {

                paddingToggle

                VStack(alignment: .leading, spacing: 4) {
                    sliderLabel
                    slider
                }
            }
            .padding(paddingAround)
            .background(Color.black.opacity(isEnabled ? 0.1 : 0.02))
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .background {
            cardShape
                .fill(Color.opposite.opacity(0.18))
        }
        .clipShape(cardShape)
        .overlay {
            cardShape
                .strokeBorder(.primary.opacity(0.08))
        }
    }

    private var wallpaper: some View {
        Image(nsImage: image)
            .resizable()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .overlay(alignment: .center) {
                Text(displayManager.displayName(for: key))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    .padding(12)
            }
            .padding(.top, paddingAround)
    }

    private var paddingToggle: some View {
        HStack {
            Text("Padding Control")
            Spacer()
            Toggle("Padding Control", isOn: Binding(
                get: { isEnabled },
                set: { enabled in
                    if enabled {
                        if let screen = NSScreen.screens.first(where: { $0.displayID == key }) {
                            displayManager.enablePadding(for: screen)
                        }
                    } else {
                        displayManager.disablePadding(for: key)
                    }
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
        }
    }

    private var slider: some View {
        Slider(value: Binding(
            get: { displayManager.displayInfo(for: key)?.padding ?? 0 },
            set: { displayManager.updatePadding(for: key, padding: $0) }
        ), in: 10...300, step: 1) {
            EmptyView()
        }
        .labelsHidden()
        .controlSize(.small)
        .frame(maxWidth: .infinity)
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }

    private var sliderLabel: some View {
        HStack {
            Text("Pixels")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(displayManager.displayInfo(for: key)?.padding ?? 0))px")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .opacity(isEnabled ? 1 : 0.5)
    }
}


// MARK: - Tiling Snap Behavior
struct TilingSnapBehavior: View {
    @Bindable var defaultsManager : DefaultsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Enable Layout Cycling", isOn: $defaultsManager.enableLayoutCycling)
                .help("Repeatedly pressing a tiling shortcut will cycle through different sizes (1/2, 1/3).")
        }
    }
}

// MARK: - Smart Tiling Behavior
struct SmartTilingBehavior: View {
    @Bindable var defaultsManager : DefaultsManager

    var body: some View {
        if defaultsManager.enableLayoutCycling {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable Smart Tiling", isOn: $defaultsManager.enableSmartTiling)
                    .help("""
                    Intelligently fills the remaining space.
                    (e.g., tiling 1/3 left makes the next right-tile 2/3).
                    
                    Keeps your workspace balanced and contained.
                    """)
            }
            .animation(.bouncy, value: defaultsManager.enableLayoutCycling)
        }
    }
}

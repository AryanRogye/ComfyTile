//
//  TilingSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//

import SwiftUI

// MARK: - Center Tiling Settings
struct CenterTilingGeneralView: View {
    @Bindable var defaultsManager : DefaultsManager
    @Environment(ComfyTileMenuBarViewModel.self) var comfyTileMenuBarVM

    var body: some View {

        @Bindable var menuBarVM = comfyTileMenuBarVM

        VStack(alignment: .leading, spacing: 4) {
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
                Slider(value: $defaultsManager.centerTilingPadding, in: 10...100, step: 1) {
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
    @Environment(ComfyTileMenuBarViewModel.self) var comfyTileMenuBarVM
    @Environment(DisplayManager.self) var displayManager

    var spacing   : CGFloat { 12 }
    var cardWidth : CGFloat { 160 }

    var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    var body: some View {
        @Bindable var menuBarVM = comfyTileMenuBarVM

        /// Advanced Center Padding Toggle
        VStack(alignment: .leading) {
            if menuBarVM.showSettings {
                Toggle("Advanced Center Padding", isOn: $defaultsManager.advancedCenterTilingPadding)
                    .help("If enabled, and a monitor doesnt have padding, will default to center padding")
            }
            if defaultsManager.advancedCenterTilingPadding && menuBarVM.showSettings {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring, value: menuBarVM.showSettings)
        .animation(.spring, value: defaultsManager.advancedCenterTilingPadding)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(nsImage: image)
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .overlay(alignment: .center) {
                    Text(displayManager.displayName(for: key))
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal)
                }

            HStack {
                Text("Custom Padding")
                Spacer()
                Toggle("Custom Padding", isOn: Binding(
                    get: { displayManager.isPaddingEnabled(for: key) },
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

            Divider()

            HStack {
                Text("Padding")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(
                        displayManager.isPaddingEnabled(for: key) ? 1 : 0.5
                    ))
                Spacer()
                Text("\(Int(padding))px")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(
                        displayManager.isPaddingEnabled(for: key) ? 1 : 0.5
                    ))
            }

            Slider(value: Binding(
                get: { displayManager.displayInfo(for: key)?.padding ?? 0 },
                set: { displayManager.updatePadding(for: key, padding: $0) }
            ), in: 10...100, step: 1) {
                EmptyView()
            }
            .labelsHidden()
            .controlSize(.small)
            .frame(maxWidth: .infinity)
            .opacity(
                displayManager.isPaddingEnabled(for: key) ? 1 : 0.5
            )
            .disabled(!displayManager.isPaddingEnabled(for: key))
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.opposite.opacity(0.18))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.primary.opacity(0.08))
        }
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

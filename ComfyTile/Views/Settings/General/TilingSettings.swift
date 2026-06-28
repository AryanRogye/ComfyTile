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
        SettingsSlider(
            title: "Center Tiling Padding",
            label: "\(Int(defaultsManager.centerTilingPadding)) px",
            value: $defaultsManager.centerTilingPadding,
            range: 10...300,
            step: 1.0,
            showSettings: $menuBarVM.showSettings,
            isResizing: $menuBarVM.isResizing
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring, value: menuBarVM.showSettings)
        .animation(.spring, value: menuBarVM.isResizing)
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
                                    displayManager: displayManager,
                                    showSettings: $menuBarVM.showSettings,
                                    isResizing: $menuBarVM.isResizing
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

// MARK: - Tile Ring General View
struct TileRingGeneralView: View {
    @Bindable var defaultsManager : DefaultsManager
    
    var body: some View {
        Toggle("Enable Tile Ring", isOn: $defaultsManager.enableTileRing)
    }
}

// MARK: - Tile Ring Hotkey
struct TileRingHotKey: View {
    @Bindable var defaultsManager : DefaultsManager
    
    var body: some View {
        if defaultsManager.enableTileRing {
            ShortcutRecorder(label: "Toggle Tile Ring", type: .toggleTileRing)
                .padding(.horizontal, -16)
        }
    }
}

// MARK: - Tile Ring Activation Diameter
struct TileRingActivationDiameter: View {
    
    @Bindable var defaultsManager: DefaultsManager
    @Bindable var menuBarVM: ComfyTileMenuBarViewModel
    
    var body: some View {
        if defaultsManager.enableTileRing {
            
            SettingsSlider(
                title: "Activation Diameter",
                label: "\(Int(defaultsManager.tileRingActivationDiameter)) px",
                value: $defaultsManager.tileRingActivationDiameter,
                range: 5...300,
                step: 1,
                showSettings: $menuBarVM.showSettings,
                isResizing: $menuBarVM.isResizing,
            )
        }
    }
}

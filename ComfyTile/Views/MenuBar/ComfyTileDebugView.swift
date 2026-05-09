//
//  ComfyTileDebugView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/12/26.
//

#if DEBUG
import SwiftUI
import KeyboardShortcuts

struct ComfyTileDebugView: View {
    
    @Environment(DisplayManager.self) var displayManager
    @Environment(WindowCore.self) var windowCore
    
    @State private var brightness: Float = 0
    
    var body: some View {
        @Bindable var displayManager = displayManager
        MenuBarContainer {
            ShortcutEditableRow(
                onClick: {},
                roundTop: true,
                title: "DEBUG",
                editLabel: "Edit",
                hotkey: .debug_press,
                idPrefix: "debug-1-\(UUID())",
                icon: { Image(systemName: "bolt.fill") },
                helpText: "used to run things fast"
            )
            
            VStack(alignment: .leading, spacing: 12) {
                
                // MARK: - Active App
                if let bundleID = displayManager.activeAppBundleID {
                    HStack {
                        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                            Text(app.localizedName ?? bundleID)
                                .font(.caption)
                                .fontWeight(.medium)
                        } else {
                            Text(bundleID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("active")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                }
                
                // MARK: - Brightness
                Text("Brightness")
                    .font(.headline)
                
                HStack {
                    Label("Brightness", systemImage: "sun.max.fill")
                    Spacer()
                    Text(String(format: "%.2f  (~%.0f nits)", brightness, brightness * 500))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                Slider(value: $brightness, in: 0.05...Float(displayManager.maxEDRHeadroom)) { editing in
                    if !editing {
                        displayManager.setBrightness(brightness)
                    }
                }
                
                HStack {
                    Text("EDR headroom")
                    Spacer()
                    Text(String(format: "%.1fx  (%.0f nits max)", displayManager.maxEDRHeadroom, displayManager.maxEDRHeadroom * 500))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if displayManager.maxEDRHeadroom <= 1.0 {
                    Label("XDR not available on this display", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Button("Reset to 100%") {
                    brightness = 1.0
                    displayManager.setBrightness(1.0)
                }
                .keyboardShortcut("r")
                
                Divider()
                
                // MARK: - Contrast
                Text("Contrast")
                    .font(.headline)
                
                Button("Reset Contrast") {
                    displayManager.resetContrast()
                }
                .keyboardShortcut("c")
                
                // MARK: - All App Profiles
                Divider()
                
                Text("App Profiles")
                    .font(.headline)
                
                // dedupe by bundleID from windowCore.windows
                let knownApps = Dictionary(
                    grouping: windowCore.windows.filter { $0.bundleIdentifier != nil },
                    by: { $0.bundleIdentifier! }
                )
                .compactMap { (_, windows) in windows.first }
                .sorted { ($0.app.localizedName ?? "") < ($1.app.localizedName ?? "") }
                
                ForEach(knownApps, id: \.bundleIdentifier) { window in
                    let bundleID = window.bundleIdentifier!
                    let isActive = bundleID == displayManager.activeAppBundleID
                    let profile  = displayManager.appProfiles[bundleID, default: .default]
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if let icon = window.app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 14, height: 14)
                            }
                            Text(window.app.localizedName ?? bundleID)
                                .font(.caption)
                                .fontWeight(isActive ? .semibold : .regular)
                            Spacer()
                            Text(String(format: "contrast %.2f", profile.contrast))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        
                        // inline contrast slider per app
                        Slider(
                            value: Binding(
                                get: { displayManager.appProfiles[bundleID, default: .default].contrast },
                                set: { displayManager.setContrast($0, for: bundleID) }
                            ),
                            in: 0.5...2.0
                        )
                    }
                    .opacity(isActive ? 1.0 : 0.7)
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .frame(width: 320)
            .onAppear {
                brightness = displayManager.currentBrightness
            }
        }
    }
}
#endif

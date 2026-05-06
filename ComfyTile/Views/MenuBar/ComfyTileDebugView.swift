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
    @State private var brightness: Float = 0
    
    var body: some View {
        @Bindable var displayManager = displayManager
        MenuBarContainer {
            ShortcutEditableRow(
                onClick: {
                    /// Do Nothing
                },
                roundTop: true,
                title: "DEBUG",
                editLabel: "Edit",
                hotkey: .debug_press,
                idPrefix: "debug-1-\(UUID())",
                icon: { Image(systemName: "bolt.fill") },
                helpText: "used to run things fast"
            )
            
            VStack(alignment: .leading, spacing: 12) {
                
                Text("Brightness Debug")
                    .font(.headline)
                
                Divider()
                
                // current value row
                HStack {
                    Label("Brightness", systemImage: "sun.max.fill")
                    Spacer()
                    Text(String(format: "%.2f  (~%.0f nits)", brightness, brightness * 500))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                // slider capped at actual EDR headroom
                Slider(value: $brightness, in: 0...Float(displayManager.maxEDRHeadroom)) { editing in
                    if !editing {
                        displayManager.setBrightness(brightness)
                    }
                }
                
                // EDR info row
                HStack {
                    Text("EDR headroom")
                    Spacer()
                    Text(String(format: "%.1fx  (%.0f nits max)", displayManager.maxEDRHeadroom, displayManager.maxEDRHeadroom * 500))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                // warn if XDR not available
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
                
                HStack {
                    Label("Contrast", systemImage: "circle.lefthalf.filled")
                    Spacer()
                    Text(String(format: "%.2f", displayManager.contrast))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                Slider(value: $displayManager.contrast, in: 0.5...2.0)
                
                Button("Reset Contrast") {
                    displayManager.resetContrast()
                }
                .keyboardShortcut("c")
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

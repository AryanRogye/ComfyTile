//
//  DisplayCard.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI

struct DisplayCard: View {
    let key: CGDirectDisplayID
    let image: NSImage
    @Bindable var displayManager: DisplayManager
    @Binding var showSettings: Bool
    @Binding var isResizing: Bool

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

                SettingsSlider(
                    title: "Padding Control",
                    label: "\(Int(displayManager.displayInfo(for: key)?.padding ?? 0 ))",
                    value: Binding(
                        get: { displayManager.displayInfo(for: key)?.padding ?? 0 },
                        set: { displayManager.updatePadding(for: key, padding: $0) }
                    ),
                    range: 10...300,
                    step: 1.0,
                    showSettings: $showSettings,
                    isResizing: $isResizing,
                    showBottomLabel: false
                )
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

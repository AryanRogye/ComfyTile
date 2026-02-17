//
//  AppearanceSettings.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/22/26.
//

import SwiftUI
import KeyboardShortcuts

struct AppearanceSettings: View {
    
    @Bindable var defaultsManager : DefaultsManager
    
    @State var superFocusColorPicker = ColorPickerCoordinator()
    @State var highlightFocusedWindowColorPicker = ColorPickerCoordinator()
    
    var body: some View {
        Form {
            Section("Tab Bar") {
                Picker("Position", selection: $defaultsManager.comfyTileTabPlacement) {
                    ForEach(ComfyTileTabPlacement.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                    }
                }
            }
            
            Section("Focused Window") {
                Toggle("Highlight focused window", isOn: $defaultsManager.highlightFocusedWindow)
                
                HStack {
                    Text("Highlight Color")
                    Button {
                        NSColorPanel.shared.orderFront(nil)
                    } label: {
                        Rectangle()
                            .fill(Color(defaultsManager.highlightFocusedWindowColor))
                    }
                    .onChange(of: highlightFocusedWindowColorPicker.selectedColor) { _, newValue in
                        defaultsManager.highlightFocusedWindowColor = Color(nsColor: newValue)
                    }
                }
                
                HStack {
                    Text("Highlight Line Width")
                    Slider(value: $defaultsManager.highlightedFocusedWindowWidth, in: 1...2, step: 0.1)
                }
                
                Toggle("Super Focus Window", isOn: $defaultsManager.superFocusWindow)
                ShortcutRecorder(label: "Toggle Super Focus", type: .toggleSuperFocus)
                    .padding(.horizontal, -16)
                HStack {
                    Text("Super Focus Color")
                    
                    Button {
                        NSColorPanel.shared.orderFront(nil)
                    } label: {
                        Rectangle()
                            .fill(Color(defaultsManager.superFocusColor))
                    }
                    .onChange(of: superFocusColorPicker.selectedColor) { _, newValue in
                        defaultsManager.superFocusColor = Color(nsColor: newValue)
                    }
                }
            }
            
            Section("Animations") {
                Toggle("Tiling animations", isOn: $defaultsManager.showTilingAnimations)
                    .toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@Observable
@MainActor
class ColorPickerCoordinator: NSObject {
    var selectedColor: NSColor = .white
    
    override init() {
        super.init()
        NSColorPanel.shared.setTarget(self)
        NSColorPanel.shared.setAction(#selector(colorChanged(_:)))
    }
    
    @objc private func colorChanged(_ sender: NSColorPanel) {
        selectedColor = sender.color
    }
}

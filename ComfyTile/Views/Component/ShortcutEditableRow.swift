//
//  ShortcutEditableRow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI
import KeyboardShortcuts

struct ShortcutEditableRow<Icon: View>: View {
    let roundTop: Bool
    let title: String
    let editLabel: String
    let hotkey: KeyboardShortcuts.Name
    let idPrefix: String
    let icon: () -> Icon
    let helpText: String
    
    @State private var allowEditHotkey = false
    @State private var hoveringOverSomethingElse = false
    @Namespace private var nm
    
    var body: some View {
        VStack(spacing: 0) {
            MenuBarModeRow(
                roundTop: roundTop,
                hoveringOverSomethingElse: $hoveringOverSomethingElse,
                icon: { AnyView(icon()) },
                name: {
                    AnyView(
                        Text(allowEditHotkey ? "" : title)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    )
                },
                shortcutButton: {
                    AnyView(
                        Button {
                            withAnimation(.snappy) { allowEditHotkey.toggle() }
                        } label: {
                            HotKeyOrClose(
                                shortcut: hotkey.shortcut,
                                allowEditHotkey: $allowEditHotkey,
                                nm: nm,
                                id: "\(idPrefix)-capsule"
                            )
                        }
                            .buttonStyle(.plain)
                            .onHover { hoveringOverSomethingElse = $0 }
                            .help(Text(helpText))
                    )
                }
            )
            
            if allowEditHotkey {
                editHotkey
                    .transition(
                        .asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .slide
                                .combined(with: .opacity)
                                .animation(.snappy(duration: 0.10))
                        )
                    )
            }
        }
        .animation(.snappy, value: allowEditHotkey)
    }
    
    private var editHotkey: some View {
        HStack(alignment: .center) {
            Text(editLabel).padding(.leading)
            Spacer()
            ShortcutRecorder(label: "", type: hotkey)
                .shadow(color: .black.opacity(1), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: 30)
        .padding(.vertical, 4)
        .background { Rectangle().fill(.secondary.opacity(0.2)) }
    }
}

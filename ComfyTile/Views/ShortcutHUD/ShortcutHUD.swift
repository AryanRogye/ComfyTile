//
//  ShortcutHUD.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/10/25.
//

import SwiftUI
import KeyboardShortcuts

struct ShortcutHUD: View {
    
    @EnvironmentObject var shortcutHUDVM : ShortcutHUDViewModel
    @StateObject var keyboardManager = KeyboardManager()
    
    var filteredShortcuts : [KeyboardShortcuts.Name] {
        
        let list : [KeyboardShortcuts.Name] = KeyboardShortcuts.Name.allForHUD.filter { (name) -> Bool in
            if let desc = name.shortcut?.description {
                let split = Array(desc)
                for i in 0..<min(keyboardManager.pressedKeys.count, split.count) {
                    if String(split[i]) != keyboardManager.pressedKeys[i].description {
                        return false
                    }
                }
                return true
            }
            
            return false
        }
        return list
    }
    
    
    var body: some View {
        ZStack {
            

            ShortcutHUDBackground()
            
            VStack(alignment: .center) {
                Button(action: { shortcutHUDVM.onEscape?() }) {}
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                
                HStack {
                    ForEach(keyboardManager.pressedKeys, id: \.self) { order in
                        Text(order.description)
                    }
                }
                
                Text("Shortcuts")
                ForEach(filteredShortcuts, id: \.self) { name in
                    ShortcutRowView(name: name)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: shortcutHUDVM.isShown ? 0 : 200)
            .scaleEffect(shortcutHUDVM.isShown ? 1 : 0.95)
            .shadow(color: .black, radius: shortcutHUDVM.isShown ? 10 : 0)
            .animation(.spring, value: shortcutHUDVM.isShown)
            .focusable(false)
            .onMoveCommand { _ in }
            .onAppear {
                keyboardManager.startMonitoring()
            }
            .onDisappear {
                keyboardManager.stopMonitoring()
            }
        }
    }
}

struct ShortcutRowView: View {
    let name: KeyboardShortcuts.Name
    
    var body: some View {
        HStack(alignment: .center) {
            // The library's view automatically displays the correct keys (e.g., "⌥H")
            Text(name.shortcut?.description ?? "")
            Text(description(for: name)) // A helper to get the text
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        }
        .padding(.vertical, 4)
    }
    
    private func description(for name: KeyboardShortcuts.Name) -> String {
        switch name {
        case .LeftHalf: return "Left Half"
        case .RightHalf: return "Right Half"
        case .Maximize: return "Maximize"
        case .Center: return "Center"
        case .NudgeTopUp: return "Nudge Top Up"
        case .NudgeTopDown: return "Nudge Top Down"
        case .NudgeBottomUp: return "Nudge Bottom Up"
        case .NudgeBottomDown: return "Nudge Bottom Down"
            
        default: return ""
        }
    }
}

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
            
            Button(action: { shortcutHUDVM.onEscape?() }) {}
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

//            ShortcutHUDBackground()
            

            VStack(alignment: .center) {
                Spacer()
                
                if keyboardManager.pressedKeys.isEmpty {
                    HStack {
                        
                    }
                    .frame(width: 100, height: 100)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                    }
                    
                } else {
                    HStack(alignment: .center) {
                        ForEach(keyboardManager.pressedKeys, id: \.self) { order in
                            Text(order.description)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.thinMaterial)
                                }
                        }
                    }
                    .frame(width: 100, height: 100)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                    }
                }
                
                ForEach(filteredShortcuts, id: \.self) { name in
                    ShortcutRowView(name: name)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: shortcutHUDVM.isShown ? 0 : 200)
            .scaleEffect(shortcutHUDVM.isShown ? 1 : 0.95)
            .shadow(color: .black, radius: shortcutHUDVM.isShown ? 10 : 0)
            .animation(.spring, value: shortcutHUDVM.isShown)
            .focusable(false)
            .onMoveCommand { _ in }
            .onChange(of: shortcutHUDVM.isShown) { _, value in
                if value {
                    keyboardManager.startMonitoring()
                } else {
                    keyboardManager.stopMonitoring()
                }
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


#Preview {
    @Previewable @StateObject var shortcutHUDVM = ShortcutHUDViewModel()
    
        ShortcutHUD()
            .environmentObject(shortcutHUDVM)
            .frame(width: 300, height: 600)
}

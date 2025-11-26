//
//  ShortcutHUDBackground.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/10/25.
//
import SwiftUI

struct ShortcutHUDBackground: View {
    
    @EnvironmentObject var shortcutHUDVM : ShortcutHUDViewModel
    
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .ignoresSafeArea()
            .scaleEffect(shortcutHUDVM.isShown ? 1 : 0.95)
            .shadow(color: .black, radius: shortcutHUDVM.isShown ? 10 : 0)
            .animation(.spring, value: shortcutHUDVM.isShown)
    }
}

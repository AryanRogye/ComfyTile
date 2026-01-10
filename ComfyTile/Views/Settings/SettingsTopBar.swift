//
//  SettingsTopBar.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct SettingsTopBar: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    var onToggleSidebar: () -> Void = { }
    
    private var borderColor: Color {
        Color.secondary
    }
    private var strokeColor: Color {
        borderColor.opacity(0.2)
    }
    
    
    // MARK: - App Version Number
    private var appVersion: some View {
        Text("\(Bundle.main.versionNumber)")
    }
    
    // MARK: - App Build Number
    private var appBuild: some View {
        Text("\(Bundle.main.buildNumber)")
    }
    
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                onToggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
                    .padding()
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
            
            Spacer()
            
            HStack {
                Text("Version:")
                appVersion
            }
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.primary.opacity(0.5))
            HStack {
                Text("Build:")
                appBuild
            }
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.primary.opacity(0.5))
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: 30)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: defaultsManager.comfyTileTabPlacement == .bottom ? 12 : 0,
                bottomLeadingRadius: defaultsManager.comfyTileTabPlacement == .top ? 12 : 0,
                bottomTrailingRadius: defaultsManager.comfyTileTabPlacement == .top ? 12 : 0,
                topTrailingRadius: defaultsManager.comfyTileTabPlacement == .bottom ? 12 : 0
            )
            .fill(.clear)
            .stroke(
                strokeColor,
                style: .init(lineWidth: 0.5)
            )
        }
    }
}

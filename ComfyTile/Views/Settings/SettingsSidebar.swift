//
//  SettingsSidebar.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct SettingsSidebar: View {
    @Binding var selected: SettingsTab
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SidebarRow(
                        title: tab.rawValue,
                        isSelected: selected == tab
                    ) {
                        selected = tab
                    }
                    
                    Divider()
                }
            }
        }
        .background(.clear)
        .frame(maxWidth: 120)
    }
}


private struct SidebarRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal)
            .frame(height: 28)
            .background{
                isSelected ? Color.accentColor : .clear
            }
            .contentShape(Rectangle()) // full row clickable
        }
        .buttonStyle(.plain)
    }
}


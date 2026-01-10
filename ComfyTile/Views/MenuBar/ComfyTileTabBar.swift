//
//  ComfyTileTabBar.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/9/26.
//

import SwiftUI

struct ComfyTileTabBar: View {
    
    @Environment(ComfyTileMenuBarViewModel.self) var comfyTileMenuBarVM
    @Binding var tabPlacement: ComfyTileTabPlacement
    
    // MARK: - Styling
    
    private var borderColor: Color {
        Color.secondary
    }
    
    private var selectedColor: Color {
        Color.secondary.opacity(0.5)
    }
    
    private var borderOpacity: Double {
        0.9
    }
    
    private var borderLineWidth: CGFloat {
        0.5
    }
    
    private var cornerRadius: CGFloat {
        12
    }
    
    private var strokeStyle: StrokeStyle {
        .init(lineWidth: borderLineWidth)
    }
    
    private var strokeColor: Color {
        borderColor.opacity(0.2)
    }
    private var selectedStrokeColor: Color {
        borderColor.opacity(0)
    }
    
    // MARK: - Body
    
    var body: some View {
        let tabs = ComfyTileTabs.allCases
        
        return HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                TabButton(
                    tab: tabs[i],
                    shape: backgroundShape(for: i),
                    isSelected: tabs[i] == comfyTileMenuBarVM.selectedTab
                )
            }
        }
        .animation(.spring, value: comfyTileMenuBarVM.selectedTab)
    }
    
    @ViewBuilder
    private func TabButton(tab: ComfyTileTabs, shape: some Shape, isSelected: Bool) -> some View {
        Button {
            withAnimation(.snappy) {
                comfyTileMenuBarVM.selectedTab = tab
            }
        } label: {
            content(for: tab)
                .frame(maxWidth: .infinity)
                .background {
                    GlassEffectContainer {
                        shape
                            .fill(isSelected ? selectedColor : .clear)
                            .stroke(isSelected ? selectedStrokeColor : strokeColor, style: strokeStyle)
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
    
    private func content(for tab: ComfyTileTabs) -> some View {
        VStack {
            if let icon = tab.icon {
                icon
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
            }
            Text(tab.rawValue)
        }
        .frame(height: 50)
    }
    
    // MARK: - Helpers
    
    private func backgroundShape(for index: Int) -> some Shape {
        let isFirst = index == 0
        let isLast = index == ComfyTileTabs.allCases.count - 1
        
        let topLeading: CGFloat = isFirst && tabPlacement == .top ? cornerRadius : 0
        let bottomLeading: CGFloat = isFirst && tabPlacement == .bottom ? cornerRadius : 0
        let topTrailing: CGFloat = isLast && tabPlacement == .top ? cornerRadius : 0
        let bottomTrailing: CGFloat = isLast && tabPlacement == .bottom ? cornerRadius : 0
        
        return UnevenRoundedRectangle(
            topLeadingRadius: topLeading,
            bottomLeadingRadius: bottomLeading,
            bottomTrailingRadius: bottomTrailing,
            topTrailingRadius: topTrailing
        )
    }
}

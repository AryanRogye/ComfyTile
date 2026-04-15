//
//  WindowTrafficLights.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/15/26.
//

import SwiftUI

struct WindowTrafficLights: View {
    var onClose: () -> Void
    var onMinimize: () -> Void
    var onMaximize: () -> Void
    let selected: Bool
    let shape: RoundedRectangle
    let trafficLightBackground: AnyShapeStyle
    
    var body: some View {
        HStack {
            TrafficLightButton(systemName: "xmark", fillColor: .red, action: onClose)
            TrafficLightButton(systemName: "minus", fillColor: .yellow, action: onMinimize)
            TrafficLightButton(systemName: "arrow.up.left.and.arrow.down.right", fillColor: .green, action: onMaximize)
        }
        .padding(4)
        .padding(.horizontal, 8)
        .background {
            shape
                .fill(trafficLightBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.clear)
                        .stroke(.secondary.opacity(0.5), style: .init(lineWidth: 0.5))
                }
        }
    }
}

private struct TrafficLightButton: View {
    var systemName: String
    var fillColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 7))
                .frame(width: 14, height: 14)
                .background {
                    Circle()
                        .fill(fillColor)
                }
        }
        .buttonStyle(.plain)
    }
}

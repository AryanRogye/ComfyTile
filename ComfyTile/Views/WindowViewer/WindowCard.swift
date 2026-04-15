//
//  WindowCard.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/15/26.
//

import SwiftUI

struct WindowCard: View {
    
    let appName: String
    let appIcon: NSImage?
    let appScreenshot: CGImage?
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var onClose: () -> Void
    var onMinimize: () -> Void
    var onMaximize: () -> Void
    let selected: Bool
    
    /// 1/5 goes to the top
    var topHeight: CGFloat {
        cardHeight * 0.15
    }
    
    /// 4/5 goes to the bottom
    var bottomHeight: CGFloat {
        cardHeight * 0.85
    }
    
    var paddingAround: CGFloat {
        6
    }
    
    var spacingBetween: CGFloat {
        2
    }
    
    var shape : RoundedRectangle {
        RoundedRectangle(cornerRadius: 18)
    }
    
    var backgroundColor: AnyShapeStyle {
        selected
        ? AnyShapeStyle(Color.accentColor.opacity(0.2))
        : AnyShapeStyle(.regularMaterial)
    }
    
    var cardStrokeColor: Color {
        selected ? Color.accentColor : Color.clear
    }
    
    var trafficLightBackground: AnyShapeStyle {
        selected
        ? AnyShapeStyle(Color.accentColor.opacity(0.1))
        : AnyShapeStyle(.regularMaterial.opacity(0.2))
    }
    
    var body: some View {
        VStack(spacing: spacingBetween) {
            /// Top Area
            HStack(spacing: 0) {
                trafficLights
                Spacer()
                appNameView
            }
            .padding(.horizontal, paddingAround)
            .frame(
                height: topHeight
            )
            
            /// Bottom Area
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(shape)
        }
        .padding(paddingAround)
        /// This is height so we can force it
        .frame(height: cardHeight, alignment: .top)
        .background {
            shape
                .fill(backgroundColor
                    .shadow(
                        .inner(
                            color: selected ? .white : .clear,
                            radius: 20
                        )
                    )
                )
                .overlay {
                    shape
                        .stroke(.white.opacity(selected ? 0.9 : 0), lineWidth: 1)
                        .blur(radius: 20)
                }
                .overlay {
                    shape
                        .stroke(
                            cardStrokeColor,
                            lineWidth: 1.5
                        )
                }
        }
    }
    
    
    @ViewBuilder
    private var preview: some View {
        if let appScreenshot {
            Image(decorative: appScreenshot, scale: 1.0)
                .resizable()
        } else {
            Rectangle()
                .fill(Color.secondary)
        }
    }
    
    @ViewBuilder
    private var appNameView: some View {
        HStack {
            if let appIcon {
                Image(nsImage: appIcon)
                    .frame(width: 20, height: 20)
            }
            Text(appName)
        }
    }
    
    @ViewBuilder
    private var trafficLights: some View {
        HStack {
            actionButton(
                systemName: "xmark",
                fillColor: .red,
                action: onClose
            )
            actionButton(
                systemName: "minus",
                fillColor: .yellow,
                action: onMinimize
            )
            actionButton(
                systemName: "arrow.up.left.and.arrow.down.right",
                fillColor: .green,
                action: onMaximize
            )
        }
        .padding(4)
        .padding(.horizontal, 8)
        .background {
            shape
                .fill(trafficLightBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.clear)
                        .stroke(
                            .secondary.opacity(0.5),
                            style: .init(lineWidth: 0.5)
                        )
                }
        }
    }
    
    @ViewBuilder
    private func actionButton(
        systemName: String,
        fillColor: Color,
        action: @escaping () -> Void
    ) -> some View {
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
